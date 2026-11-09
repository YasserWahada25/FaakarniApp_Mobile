import 'dart:convert';

import 'package:fakarniapp/core/config/api_config.dart';
import 'package:fakarniapp/core/session/auth_session.dart';
import 'package:fakarniapp/providers/auth_provider.dart';
import 'package:fakarniapp/services/api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_session.dart';

class _ConfigBundle extends CachingAssetBundle {
  _ConfigBundle(this.json);

  final String json;

  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(utf8.encode(json));
}

/// The communication, posts and medical modules (other machine) now share the
/// configuration, the HTTP client and the session of the rest of the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chat socket and media URLs come from the single configuration', () async {
    await ApiConfig.load(_ConfigBundle('{"API_BASE_URL": "https://demo-8090.app.github.dev"}'));
    expect(ApiConfig.chatSocketUrl, 'wss://demo-8090.app.github.dev/chat-ws/websocket');
    expect(ApiConfig.mediaUrl('/uploads/groups/a.png'), 'https://demo-8090.app.github.dev/uploads/groups/a.png');
    expect(ApiConfig.mediaUrl('https://cdn/x.png'), 'https://cdn/x.png');
    expect(ApiConfig.mediaUrl(' '), isNull);
  });

  test('AuthSession reflects the signed-in user of AuthProvider', () async {
    AuthProvider.instance.debugSetSession(testSession);
    addTearDown(() => AuthProvider.instance.debugSetSession(null));
    expect(AuthSession.instance.userId, 'u1');
    expect(AuthSession.instance.user?.fullName, 'Sami Ben Ali');
    expect(await AuthSession.instance.ensureSignedIn(), isTrue);
    expect(await AuthSession.instance.accessToken(), testSession.accessToken);

    AuthProvider.instance.debugSetSession(null);
    expect(AuthSession.instance.userId, isNull);
    expect(await AuthSession.instance.ensureSignedIn(), isFalse);
    expect(await AuthSession.instance.accessToken(), isNull);
  });

  group('ApiClient', () {
    late List<http.Request> requests;
    late ApiClient api;

    setUp(() {
      requests = [];
      api = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }),
      )..tokenProvider = (() async => 'tok');
    });

    test('an image upload is typed image/* and carries the token', () async {
      await api.upload('/api/upload/image', field: 'file', bytes: const [1], filename: 'cover.PNG');
      final request = requests.single;
      expect(request.headers['authorization'], 'Bearer tok');
      expect(request.body, contains('content-type: image/png'));
      await api.upload('/api/upload/image', field: 'file', bytes: const [1], filename: 'photo');
      expect(requests.last.body, contains('content-type: image/jpeg'));
    });

    test('a String body is sent as text, a map as JSON', () async {
      await api.put('/api/messages/1', body: 'Bonjour');
      expect(requests.last.headers['content-type'], startsWith('text/plain'));
      expect(requests.last.body, 'Bonjour');
      await api.put('/api/groups/1', body: {'name': 'G'});
      expect(requests.last.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(requests.last.body), {'name': 'G'});
    });

    test('delete accepts a query', () async {
      await api.delete('/api/posts/1/comments/2', query: {'userId': 'u1'});
      expect(requests.last.url.queryParameters, {'userId': 'u1'});
    });
  });

  test('errors without a message get a French status message', () async {
    final api = ApiClient(client: MockClient((_) async => http.Response('', 403)));
    await expectLater(
      api.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Accès refusé.')),
    );
    expect(ApiException.describe(const ApiException('Boom')), 'Boom');
    expect(ApiException.describe(StateError('x')), 'Réponse inattendue du serveur.');
  });
}
