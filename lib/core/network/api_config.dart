/// Where the backend lives. Every call goes through the Spring Cloud Gateway
/// (port 8090), exactly like the web app.
///
/// Values come from `--dart-define` at launch, e.g. against the Codespace:
///
///     flutter run --dart-define-from-file=env/dev.json
///
/// (see `env/dev.example.json`). Without it the app targets a gateway running
/// on the host machine, as seen from the Android emulator.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8090');

  /// Development account signed in automatically while the sign-in screen is
  /// not wired to the API yet (see `AuthSession`). Leave empty to stay anonymous.
  static const String devEmail = String.fromEnvironment('DEV_EMAIL');
  static const String devPassword = String.fromEnvironment('DEV_PASSWORD');

  static const Duration timeout = Duration(seconds: 20);

  static String get _root => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  static Uri uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_root$path');
    return query == null || query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  /// Absolute URL of a file path returned by the API (e.g. `/uploads/groups/x.png`).
  static String? mediaUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) return pathOrUrl;
    return '$_root${pathOrUrl.startsWith('/') ? '' : '/'}$pathOrUrl';
  }

  /// Raw (non-SockJS) STOMP endpoint of Chat_Service, through the gateway
  /// route `/chat-ws/**` (rewritten to the service's `/ws/**`).
  static String get chatSocketUrl {
    final root = Uri.parse(_root);
    return root
        .replace(scheme: root.scheme == 'https' ? 'wss' : 'ws', path: '${root.path}/chat-ws/websocket')
        .toString();
  }
}
