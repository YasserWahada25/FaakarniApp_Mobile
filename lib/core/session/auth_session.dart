import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

/// The signed-in user, as seen by the communication, posts and medical modules.
///
/// The session itself lives in [AuthProvider] (sign-in screen, "Remember me",
/// sign-out, refresh token): this is only a view on it, so that every module
/// shares the same user and the same token.
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  /// Id of the signed-in user, `null` when signed out.
  String? get userId => AuthProvider.instance.user?.id;
  AppUser? get user => AuthProvider.instance.user;
  bool get isSignedIn => userId != null;

  /// Renews the access token first when it expires within 30 s: group-service
  /// and post-service treat an expired token as an anonymous call instead of
  /// answering 401. Returns [isSignedIn].
  Future<bool> ensureSignedIn() async {
    await accessToken();
    return isSignedIn;
  }

  /// Access token to send as `Authorization: Bearer`, `null` when signed out.
  Future<String?> accessToken() async => ApiClient.instance.tokenProvider?.call();
}
