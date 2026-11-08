import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../session/auth_session.dart';
import 'api_config.dart';

/// Error shown to the user when a call fails. [message] is already in French.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
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

/// Thin JSON client over the gateway: adds the bearer token, decodes UTF-8
/// JSON and turns failures into [ApiException]s.
class ApiClient {
  ApiClient({http.Client? httpClient, AuthSession? session})
    : _http = httpClient ?? http.Client(),
      _session = session ?? AuthSession.instance;

  static final ApiClient instance = ApiClient();

  final http.Client _http;
  final AuthSession _session;

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);
  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);
  Future<dynamic> delete(String path, {Map<String, String>? query}) => _send('DELETE', path, query: query);

  /// `multipart/form-data` upload of a single image. [timeout] overrides the
  /// default for slow endpoints (e.g. the AI analysis of an MRI).
  Future<dynamic> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    final request = http.MultipartRequest('POST', ApiConfig.uri(path, query))
      ..headers.addAll(await _authHeaders())
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename, contentType: _imageType(filename)));
    return _execute(request, timeout: timeout);
  }

  /// A [String] body is sent as `text/plain` (e.g. chat `PUT /api/messages/{id}`),
  /// anything else as JSON.
  Future<dynamic> _send(String method, String path, {Map<String, String>? query, Object? body}) async {
    final request = http.Request(method, ApiConfig.uri(path, query))..headers.addAll(await _authHeaders());
    if (body is String) {
      request
        ..headers['Content-Type'] = 'text/plain; charset=utf-8'
        ..body = body;
    } else if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = jsonEncode(body);
    }
    return _execute(request);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _session.accessToken();
    return {'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<dynamic> _execute(http.BaseRequest request, {Duration? timeout}) async {
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(timeout ?? ApiConfig.timeout));
    } on TimeoutException {
      debugPrint('API ${request.method} ${request.url} → timeout');
      throw ApiException('Le serveur ne répond pas. Réessayez dans un instant.${_debugTarget()}');
    } on http.ClientException catch (e) {
      debugPrint('API ${request.method} ${request.url} → $e');
      throw ApiException('Impossible de joindre le serveur. Vérifiez votre connexion.${_debugTarget()}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) return null;
      final text = utf8.decode(response.bodyBytes);
      try {
        return jsonDecode(text);
      } on FormatException {
        return text;
      }
    }
    debugPrint('API ${request.method} ${request.url} → HTTP ${response.statusCode}');
    throw ApiException(_errorMessage(response), statusCode: response.statusCode);
  }

  /// In debug builds, shows which server was tried: a wrong or missing
  /// `API_BASE_URL` is the usual cause of "server unreachable".
  static String _debugTarget() => kDebugMode ? '\n(${ApiConfig.baseUrl})' : '';

  static String _errorMessage(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final message = json is Map ? (json['message'] ?? json['error']) : null;
      if (message is String && message.isNotEmpty && message != 'No message available' && response.statusCode < 500) {
        return message;
      }
    } on FormatException {
      // Not JSON: fall back to the status code.
    }
    return switch (response.statusCode) {
      400 => 'Requête invalide.',
      401 => 'Session expirée. Reconnectez-vous.',
      403 => 'Accès refusé.',
      404 => 'Élément introuvable.',
      502 || 503 || 504 => 'Service momentanément indisponible. Réessayez dans un instant.',
      _ => 'Une erreur est survenue (code ${response.statusCode}).',
    };
  }

  /// group-service rejects any upload whose part is not typed `image/*`, so
  /// unknown extensions default to JPEG (what `image_picker` produces).
  static MediaType _imageType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
