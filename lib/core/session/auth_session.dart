import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/user.dart';
import '../network/api_config.dart';
import '../network/json_parsing.dart';

/// The signed-in user, as seen by the API layer (token + user id).
///
/// INTEGRATION POINT with the authentication flow: after `POST /auth/login`
/// the sign-in screen must call [signIn] with the returned access token, and
/// [signOut] on logout. Until that flow is wired, the development account
/// given with `--dart-define DEV_EMAIL / DEV_PASSWORD` is signed in on demand
/// (and again when its 15-minute token expires), so the modules can be used
/// against the real backend.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? _accessToken;
  String? _userId;
  AppUser? _user;
  Future<bool>? _pendingLogin;
  bool _configLogged = false;

  /// Id of the signed-in user (the JWT `sub`), `null` when anonymous.
  String? get userId => _userId;
  AppUser? get user => _user;
  bool get isSignedIn => _userId != null;

  static bool get _hasDevAccount => ApiConfig.devEmail.isNotEmpty && ApiConfig.devPassword.isNotEmpty;

  void signIn({required String accessToken, AppUser? user}) {
    _accessToken = accessToken;
    _user = user;
    _userId = user?.id ?? _JwtClaims.parse(accessToken)?.subject;
    notifyListeners();
  }

  void signOut() {
    _accessToken = null;
    _userId = null;
    _user = null;
    notifyListeners();
  }

  /// Makes sure a user is available, signing the development account in when
  /// needed. Returns [isSignedIn].
  Future<bool> ensureSignedIn() async {
    if (!_configLogged) {
      _configLogged = true;
      debugPrint(
        'AuthSession: API_BASE_URL=${ApiConfig.baseUrl}, dev account ${_hasDevAccount ? ApiConfig.devEmail : 'NOT SET'}'
        '${_hasDevAccount ? '' : ' (launch with --dart-define-from-file=env/dev.json)'}',
      );
    }
    if (_tokenIsFresh) return true;
    if (!_hasDevAccount) return isSignedIn;
    return _pendingLogin ??= _devLogin().whenComplete(() => _pendingLogin = null);
  }

  /// Access token to send as `Authorization: Bearer`, `null` when anonymous.
  ///
  /// Some services (group-service) silently treat an expired token as an
  /// anonymous call instead of answering 401, so the token is renewed before
  /// it expires rather than after a failure.
  Future<String?> accessToken() async {
    await ensureSignedIn();
    return _accessToken;
  }

  bool get _tokenIsFresh {
    final token = _accessToken;
    if (token == null) return false;
    final expiry = _JwtClaims.parse(token)?.expiresAt;
    return expiry == null || expiry.isAfter(DateTime.now().add(const Duration(seconds: 30)));
  }

  Future<bool> _devLogin() async {
    try {
      final response = await http
          .post(
            ApiConfig.uri('/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': ApiConfig.devEmail, 'password': ApiConfig.devPassword}),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode != 200) {
        debugPrint('AuthSession: dev sign-in failed (HTTP ${response.statusCode})');
        return isSignedIn;
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      signIn(accessToken: json['accessToken'] as String, user: _userFromJson(json['user']));
      return true;
    } catch (e) {
      debugPrint('AuthSession: dev sign-in failed ($e)');
      return isSignedIn;
    }
  }

  static AppUser? _userFromJson(Object? json) {
    if (json is! Map || json['id'] == null) return null;
    final role = UserRole.values.where((r) => r.backendValue == json['role']).firstOrNull;
    return AppUser(
      id: json['id'].toString(),
      nom: stringOrNull(json['nom']) ?? '',
      prenom: stringOrNull(json['prenom']) ?? '',
      email: stringOrNull(json['email']) ?? '',
      role: role ?? UserRole.careOwner,
      numTel: stringOrNull(json['numTel']) ?? '',
      adresse: stringOrNull(json['adresse']) ?? '',
    );
  }
}

/// The two claims the app needs, read without verifying the signature (the
/// backend does that).
class _JwtClaims {
  const _JwtClaims(this.subject, this.expiresAt);

  final String? subject;
  final DateTime? expiresAt;

  static _JwtClaims? parse(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      final exp = payload['exp'];
      return _JwtClaims(
        payload['sub']?.toString(),
        exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000) : null,
      );
    } catch (_) {
      return null;
    }
  }
}
