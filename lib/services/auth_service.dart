import '../core/config/api_endpoints.dart';
import '../models/user.dart';
import 'api_client.dart';

/// Authentication API of the User-Service, through the gateway (web
/// `AuthService`): `/auth/**` and `/api/users/**`.
///
/// The User-Service throws plain `RuntimeException`s for bad credentials or an
/// invalid reset code: they reach the client as a 500 without message, so
/// those calls translate the status into the message shown by the web.
class AuthService {
  AuthService({ApiClient? client}) : _api = client ?? ApiClient.instance;

  static final AuthService instance = AuthService();

  final ApiClient _api;

  Future<AuthSession> login(String email, String password) async {
    try {
      final raw = await _api.post(ApiEndpoints.login, body: {'email': email, 'password': password}, auth: false);
      return AuthSession.fromJson(_map(raw));
    } on ApiException catch (e) {
      throw _rejected(e, 'Email ou mot de passe incorrect.');
    }
  }

  /// Web `register`: creates the account; the user then signs in.
  Future<AppUser> register(SignUpRequest request) async {
    try {
      final raw = await _api.post(ApiEndpoints.users, body: request.toJson(), auth: false);
      return AppUser.fromJson(_map(raw));
    } on ApiException catch (e) {
      // 409 carries the API message ("This email is already registered…").
      if (e.statusCode == 400) throw ApiException('Vérifiez les champs du formulaire.', statusCode: e.statusCode);
      rethrow;
    }
  }

  /// Rotates the refresh token (same session) and issues a new access token.
  Future<AuthSession> refresh(String refreshToken) async {
    final raw = await _api.post(ApiEndpoints.refresh, body: {'refreshToken': refreshToken}, auth: false);
    return AuthSession.fromJson(_map(raw));
  }

  /// Revokes the server session of [refreshToken].
  Future<void> logout(String refreshToken) =>
      _api.post(ApiEndpoints.logout, body: {'refreshToken': refreshToken}, auth: false);

  /// Sends the 6-digit reset code by email.
  Future<String> forgotPassword(String email) async {
    final raw = await _api.post(ApiEndpoints.forgotPassword, body: {'email': email}, auth: false);
    return _message(raw, 'Si un compte existe pour cet email, un code vous a été envoyé.');
  }

  Future<String> resetPassword({required String email, required String code, required String newPassword}) async {
    try {
      final raw = await _api.post(
        ApiEndpoints.resetPassword,
        body: {'email': email, 'code': code, 'newPassword': newPassword},
        auth: false,
      );
      return _message(raw, 'Mot de passe réinitialisé.');
    } on ApiException catch (e) {
      throw _rejected(e, 'Code invalide ou expiré.');
    }
  }

  Future<AppUser> getUser(String id) async => AppUser.fromJson(_map(await _api.get(ApiEndpoints.user(id))));

  /// Requires the session token (the API allows only the user or an admin).
  Future<AppUser> updateUser(String id, UpdateUserRequest request) async {
    try {
      return AppUser.fromJson(_map(await _api.put(ApiEndpoints.user(id), body: request.toJson())));
    } on ApiException catch (e) {
      if (e.statusCode == 400) throw ApiException('Vérifiez les champs du formulaire.', statusCode: e.statusCode);
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw ApiException('Session expirée. Reconnectez-vous.', statusCode: e.statusCode);
      }
      rethrow;
    }
  }

  /// Keeps network errors as is; any server rejection becomes [message].
  static ApiException _rejected(ApiException e, String message) {
    final status = e.statusCode;
    if (status == null || status == 404 || status >= 502) return e;
    return ApiException(message, statusCode: status);
  }

  static String _message(dynamic raw, String fallback) {
    final m = raw is Map ? raw['message'] : null;
    return m is String && m.trim().isNotEmpty ? m.trim() : fallback;
  }

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    throw const ApiException('Réponse serveur invalide.');
  }
}
