import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/api_config.dart';

/// Error raised by [ApiClient]; [message] is ready to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// HTTP status, or null when the server could not be reached.
  final int? statusCode;

  /// User-facing message for any error caught around an API call.
  static String describe(Object error) {
    if (error is ApiException) return error.message;
    debugPrint('Unexpected API error: $error');
    return 'Réponse inattendue du serveur.';
  }

  @override
  String toString() => message;
}

/// Thin JSON client over the gateway (web `HttpClient` + `authInterceptor`).
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static final ApiClient instance = ApiClient();

  final http.Client _client;

  /// Returns a valid access token (renewed if needed), or null when signed out.
  /// Set by the auth provider.
  Future<String?> Function()? tokenProvider;

  /// Called after a 401 on an authenticated request; returns true when the
  /// session was renewed and the request can be retried.
  Future<bool> Function()? onUnauthorized;

  /// [auth] `false` for public routes (sign-in, sign-up, password reset): an
  /// expired token would make the User-Service reject them (web interceptor).
  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) =>
      _send('GET', ApiConfig.uri(path, query), auth: auth);

  Future<dynamic> post(String path, {Object? body, Map<String, String>? query, bool auth = true}) =>
      _send('POST', ApiConfig.uri(path, query), body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', ApiConfig.uri(path), body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', ApiConfig.uri(path), body: body, auth: auth);

  Future<dynamic> delete(String path, {Map<String, String>? query, bool auth = true}) =>
      _send('DELETE', ApiConfig.uri(path, query), auth: auth);

  /// Multipart upload of a single file. [timeout] defaults to [ApiConfig.timeout].
  Future<dynamic> postFile(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    MediaType? contentType,
    Map<String, String>? query,
    Duration? timeout,
  }) =>
      _dispatch(
        (token) => http.MultipartRequest('POST', ApiConfig.uri(path, query))
          ..headers.addAll(_headers(token))
          ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename, contentType: contentType)),
        auth: true,
        timeout: timeout,
      );

  /// Multipart upload of an image: group-service rejects any part not typed
  /// `image/*`, so unknown extensions are sent as JPEG (what `image_picker` produces).
  Future<dynamic> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String>? query,
    Duration? timeout,
  }) =>
      postFile(
        path,
        field: field,
        bytes: bytes,
        filename: filename,
        contentType: _imageType(filename),
        query: query,
        timeout: timeout,
      );

  /// A [String] body is sent as `text/plain` (e.g. chat `PUT /api/messages/{id}`),
  /// anything else as JSON.
  Future<dynamic> _send(String method, Uri uri, {Object? body, required bool auth}) => _dispatch(
        (token) {
          final request = http.Request(method, uri)..headers.addAll(_headers(token));
          if (body is String) {
            request
              ..headers[HttpHeaders.contentTypeHeader] = 'text/plain; charset=utf-8'
              ..body = body;
          } else {
            request.headers[HttpHeaders.contentTypeHeader] = 'application/json; charset=utf-8';
            if (body != null) request.body = jsonEncode(body);
          }
          return request;
        },
        auth: auth,
      );

  static Map<String, String> _headers(String? token) => {
        HttpHeaders.acceptHeader: 'application/json',
        if (token != null && token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
      };

  /// [build] creates a new request for each attempt: a request can only be sent once.
  Future<dynamic> _dispatch(
    http.BaseRequest Function(String? token) build, {
    required bool auth,
    Duration? timeout,
    bool retried = false,
  }) async {
    final token = auth ? await tokenProvider?.call() : null;

    final http.Response res;
    try {
      res = await _client.send(build(token)).then(http.Response.fromStream).timeout(timeout ?? ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Délai dépassé (${ApiConfig.baseUrl}). Vérifiez que le serveur est démarré et joignable.');
    } on SocketException {
      throw ApiException('Serveur injoignable (${ApiConfig.baseUrl}). Vérifiez le réseau et la gateway.');
    } on http.ClientException catch (e) {
      throw ApiException('Erreur réseau : ${e.message}');
    }

    // A private GitHub Codespaces port: the tunnel rejects the request (401
    // `WWW-Authenticate: tunnel`) or redirects to GitHub's sign-in page (HTML)
    // before it reaches the gateway.
    final privatePort = res.statusCode == 401 && (res.headers['www-authenticate'] ?? '').contains('tunnel');
    if (privatePort || (res.headers[HttpHeaders.contentTypeHeader] ?? '').contains('text/html')) {
      throw ApiException(
        'Le port 8090 du Codespace est privé : passez-le en « Public » (onglet Ports) puis réessayez.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode == 401 && token != null && !retried && onUnauthorized != null && await onUnauthorized!()) {
      return _dispatch(build, auth: auth, timeout: timeout, retried: true);
    }

    final decoded = res.bodyBytes.isEmpty ? null : _decode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    debugPrint('API ${res.request?.method} ${res.request?.url} → HTTP ${res.statusCode}');
    throw ApiException(_errorMessage(decoded) ?? _statusMessage(res.statusCode), statusCode: res.statusCode);
  }

  static String _statusMessage(int status) => switch (status) {
        400 => 'Requête invalide.',
        401 => 'Session expirée. Reconnectez-vous.',
        403 => 'Accès refusé.',
        404 => 'Élément introuvable.',
        502 || 503 || 504 => 'Service momentanément indisponible ($status). Réessayez dans un instant.',
        _ => 'Erreur serveur ($status).',
      };

  static MediaType _imageType(String filename) => switch (filename.split('.').last.toLowerCase()) {
        'png' => MediaType('image', 'png'),
        'gif' => MediaType('image', 'gif'),
        'webp' => MediaType('image', 'webp'),
        'heic' => MediaType('image', 'heic'),
        _ => MediaType('image', 'jpeg'),
      };

  static dynamic _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  /// Error bodies: custom `{message}` / `{error}` maps, FastAPI `{detail}` or
  /// plain text. Spring's default body (`{timestamp, status, error, path}`) only
  /// carries the status reason ("Internal Server Error"), useless to the user:
  /// it is ignored.
  static String? _errorMessage(dynamic body) {
    if (body is Map) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty && message != 'No message available') return message.trim();
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      final springDefault = body.containsKey('timestamp') && body.containsKey('path');
      final error = body['error'];
      if (!springDefault && error is String && error.trim().isNotEmpty) return error.trim();
    }
    if (body is String && body.trim().isNotEmpty && body.length < 300) return body.trim();
    return null;
  }
}
