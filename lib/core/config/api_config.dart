import 'dart:convert';

import 'package:flutter/services.dart';

/// Backend endpoints (web `environment.apiBaseUrl`).
///
/// Every microservice is reached through the Spring Cloud Gateway (port 8090),
/// like the web app's proxy. The URL comes from, by priority:
/// 1. `--dart-define=API_BASE_URL=…` (or `--dart-define-from-file=…`);
/// 2. `config/dev.json` (copy of `config/dev.example.json`), bundled as an
///    asset and read by [load] at startup, so a plain `flutter run` works;
/// 3. `http://10.0.2.2:8090` (the PC's gateway seen from an Android emulator).
///
/// - GitHub Codespaces: `https://<codespace>-8090.app.github.dev` (port 8090 public).
/// - Physical phone on the same Wi-Fi: the LAN IP of the PC running the gateway.
abstract final class ApiConfig {
  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _definedPatientId = String.fromEnvironment('PATIENT_ID');
  static const _configAsset = 'config/dev.json';

  static String _baseUrl = _definedBaseUrl.isNotEmpty ? _definedBaseUrl : 'http://10.0.2.2:8090';
  static String _patientId = _definedPatientId.isNotEmpty ? _definedPatientId : 'mobile-demo-patient';

  static String get baseUrl => _baseUrl;

  /// Fallback patient id when nobody is signed in (tests, demos); the
  /// signed-in user's id is used otherwise.
  static String get patientId => _patientId;

  /// Reads `config/dev.json` (call before `runApp`). Missing file or keys keep
  /// the defaults; dart-defines always win.
  static Future<void> load([AssetBundle? bundle]) async {
    try {
      final json = jsonDecode(await (bundle ?? rootBundle).loadString(_configAsset));
      if (json is! Map) return;
      final url = '${json['API_BASE_URL'] ?? ''}'.trim();
      final patient = '${json['PATIENT_ID'] ?? ''}'.trim();
      if (_definedBaseUrl.isEmpty && url.startsWith('http')) _baseUrl = url;
      if (_definedPatientId.isEmpty && patient.isNotEmpty && !patient.startsWith('<')) _patientId = patient;
    } catch (_) {
      // No config/dev.json in this build: defaults apply.
    }
  }

  static const Duration timeout = Duration(seconds: 45);

  static Uri uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query == null || query.isEmpty ? null : query);
  }

  /// Media URLs returned by the API are often relative (`/uploads/activities/x.png`):
  /// resolve them against the gateway so `Image.network` can load them.
  /// Older records store the service's own URL (`http://localhost:8087/uploads/…`),
  /// unreachable from a phone: only their path is kept.
  static String? resolveMedia(String? url) {
    final u = url?.trim() ?? '';
    if (u.isEmpty) return null;
    if (u.startsWith('data:')) return u;
    if (u.startsWith('http://') || u.startsWith('https://')) {
      final parsed = Uri.tryParse(u);
      if (parsed == null || !_localHosts.contains(parsed.host)) return u;
      return uri(parsed.path, parsed.queryParameters).toString();
    }
    return uri(u.startsWith('/') ? u : '/$u').toString();
  }

  static const _localHosts = {'localhost', '127.0.0.1'};

  /// Absolute URL of a file path returned by the API (e.g. `/uploads/groups/x.png`).
  static String? mediaUrl(String? pathOrUrl) => resolveMedia(pathOrUrl);

  /// Raw (non-SockJS) STOMP endpoint of Chat_Service, through the gateway
  /// route `/chat-ws/**` (rewritten to the service's `/ws/**`).
  static String get chatSocketUrl {
    final root = uri('/chat-ws/websocket');
    return root.replace(scheme: root.scheme == 'https' ? 'wss' : 'ws').toString();
  }
}
