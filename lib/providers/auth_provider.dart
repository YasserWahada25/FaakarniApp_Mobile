import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Signed-in user and tokens (web `AuthService` session + `authGuard`).
///
/// - "Remember me" keeps the session in the secure storage (Keystore /
///   Keychain); otherwise it lives in memory only, like the web
///   `sessionStorage`.
/// - The access token lasts 15 minutes: it is renewed with the refresh token
///   before it expires, or after a 401.
/// - The router listens to this provider to protect the app pages.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service, FlutterSecureStorage? storage, ApiClient? client})
      : _service = service ?? AuthService.instance,
        _storage = storage ?? const FlutterSecureStorage() {
    final api = client ?? ApiClient.instance;
    api.tokenProvider = validAccessToken;
    api.onUnauthorized = renew;
  }

  static final AuthProvider instance = AuthProvider();

  static const _storageKey = 'fakarni_session';

  final AuthService _service;
  final FlutterSecureStorage _storage;

  UserSession? _session;
  bool _remember = false;
  Future<bool>? _renewing;

  AppUser? get user => _session?.user;
  bool get isAuthenticated => _session != null;

  /// Restores a remembered session at startup. The access token is renewed
  /// on the first API call if it has expired meanwhile.
  Future<void> restore() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null) return;
      final session = UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (session.refreshToken.isEmpty || session.user.id.isEmpty) return;
      _session = session;
      _remember = true;
      notifyListeners();
    } catch (_) {
      // Unreadable storage (reinstall, key change): start signed out.
      await _clearStorage();
    }
  }

  Future<AppUser> signIn(String email, String password, {required bool remember}) async {
    final session = await _service.login(email.trim(), password);
    _remember = remember;
    await _setSession(session);
    return session.user;
  }

  /// Revokes the server session (best effort) and forgets the local one.
  Future<void> signOut() async {
    final refresh = _session?.refreshToken;
    await _setSession(null);
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _service.logout(refresh);
      } on ApiException {
        // Already signed out locally; the server session expires by itself.
      }
    }
  }

  /// Saves the updated profile of the signed-in user.
  Future<AppUser> updateProfile(UpdateUserRequest request) async {
    final current = _session;
    if (current == null) throw const ApiException('Session expirée. Reconnectez-vous.');
    final updated = await _service.updateUser(current.user.id, request);
    if (_session != null) await _setSession(_session!.copyWith(user: updated));
    return updated;
  }

  /// [ApiClient.tokenProvider]: the current access token, renewed first when
  /// it has expired.
  Future<String?> validAccessToken() async {
    final session = _session;
    if (session == null) return null;
    if (session.accessTokenExpired()) await renew();
    return _session?.accessToken;
  }

  /// [ApiClient.onUnauthorized]: exchanges the refresh token for new tokens.
  /// Concurrent callers share the same request. The session is dropped when
  /// the server rejects the refresh token (expired / revoked); a network
  /// error keeps it.
  Future<bool> renew() => _renewing ??= _renew().whenComplete(() => _renewing = null);

  Future<bool> _renew() async {
    final session = _session;
    if (session == null) return false;
    try {
      final renewed = await _service.refresh(session.refreshToken);
      // The refresh response may omit the user: keep the known one.
      await _setSession(renewed.user.id.isEmpty ? renewed.copyWith(user: session.user) : renewed);
      return true;
    } on ApiException catch (e) {
      // The User-Service rejects an invalid / expired session with a 500;
      // 502-504 mean the gateway or the service is down.
      final status = e.statusCode;
      if (status != null && status <= 500) await _setSession(null);
      return false;
    }
  }

  Future<void> _setSession(UserSession? session) async {
    _session = session;
    notifyListeners();
    if (session == null) {
      _remember = false;
      await _clearStorage();
    } else if (_remember) {
      try {
        await _storage.write(key: _storageKey, value: jsonEncode(session.toJson()));
      } catch (_) {
        // Storage unavailable: the session still works for this run.
      }
    }
  }

  Future<void> _clearStorage() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {
      // Nothing stored or storage unavailable.
    }
  }

  /// Signs in without the API (widget tests).
  @visibleForTesting
  void debugSetSession(UserSession? session) {
    _session = session;
    _remember = false;
    notifyListeners();
  }
}
