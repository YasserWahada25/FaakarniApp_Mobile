import 'dart:convert';

import 'package:fakarniapp/models/user.dart';
import 'package:fakarniapp/providers/auth_provider.dart';
import 'package:fakarniapp/services/api_client.dart';
import 'package:fakarniapp/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Unsigned JWT whose `exp` is [expiresIn] from now (only `exp` is read).
String _jwt(Duration expiresIn) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final exp = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'none'})}.${part({'sub': 'u1', 'exp': exp})}.sig';
}

const _userJson = {
  'id': 'u1',
  'nom': 'Ben Ali',
  'prenom': 'Sami',
  'email': 'sami@fakarni.tn',
  'role': 'PATIENT_PROFILE',
  'numTel': '12345678',
  'adresse': 'Tunis',
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('models', () {
    test('user parses the API response and unknown roles', () {
      final user = AppUser.fromJson(_userJson);
      expect(user.role, UserRole.patient);
      expect(user.fullName, 'Sami Ben Ali');
      expect(UserRole.fromBackend('ADMIN'), UserRole.admin);
      expect(UserRole.selectable, isNot(contains(UserRole.admin)));
    });

    test('update and sign-up payloads omit empty optional fields', () {
      expect(const UpdateUserRequest(nom: 'A', numTel: '', adresse: ' ').toJson(), {'nom': 'A'});
      const signUp = SignUpRequest(
        nom: 'A',
        prenom: 'B',
        email: 'a@b.tn',
        password: 'Abc12!',
        role: UserRole.careOwner,
        numTel: '',
        adresse: 'Tunis',
      );
      expect(signUp.toJson().containsKey('numTel'), isFalse);
      expect(signUp.toJson()['role'], 'CARE_OWNER');
    });

    test('session reads the access token expiry', () {
      final fresh = UserSession(accessToken: _jwt(const Duration(minutes: 15)), refreshToken: 'r', user: AppUser.fromJson(_userJson));
      final stale = UserSession(accessToken: _jwt(const Duration(seconds: 10)), refreshToken: 'r', user: fresh.user);
      expect(fresh.accessTokenExpired(), isFalse);
      expect(stale.accessTokenExpired(), isTrue);
      expect(UserSession(accessToken: 'not-a-jwt', refreshToken: 'r', user: fresh.user).accessTokenExpired(), isTrue);
    });
  });

  group('AuthProvider', () {
    late List<http.Request> calls;
    late http.Response Function(http.Request) handler;
    late ApiClient api;
    late AuthProvider auth;

    setUp(() {
      calls = [];
      api = ApiClient(client: MockClient((req) async {
        calls.add(req);
        return handler(req);
      }));
      auth = AuthProvider(service: AuthService(client: api), client: api);
    });

    test('sign-in stores the session; wrong credentials show the web message', () async {
      handler = (_) => _json({'timestamp': 't', 'status': 500, 'error': 'Internal Server Error', 'path': '/auth/login'}, 500);
      await expectLater(
        auth.signIn('sami@fakarni.tn', 'bad', remember: false),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Email ou mot de passe incorrect.')),
      );
      expect(auth.isAuthenticated, isFalse);

      handler = (_) => _json({'accessToken': _jwt(const Duration(minutes: 15)), 'refreshToken': 'r1', 'user': _userJson});
      final user = await auth.signIn(' sami@fakarni.tn ', 'Good1!', remember: false);
      expect(user.id, 'u1');
      expect(auth.isAuthenticated, isTrue);
      expect(jsonDecode(calls.last.body), {'email': 'sami@fakarni.tn', 'password': 'Good1!'});
      expect(calls.last.headers.containsKey('Authorization'), isFalse);
    });

    test('an expired access token is renewed before the request', () async {
      final fresh = _jwt(const Duration(minutes: 15));
      auth.debugSetSession(UserSession(accessToken: _jwt(Duration.zero), refreshToken: 'r1', user: AppUser.fromJson(_userJson)));
      handler = (req) => req.url.path == '/auth/refresh'
          ? _json({'accessToken': fresh, 'refreshToken': 'r2', 'user': _userJson})
          : _json(<Object>[]);

      await api.get('/api/events');
      expect(calls.map((c) => c.url.path), ['/auth/refresh', '/api/events']);
      expect(jsonDecode(calls.first.body), {'refreshToken': 'r1'});
      expect(calls.last.headers['Authorization'], 'Bearer $fresh');
    });

    test('a 401 renews the session once and retries', () async {
      final fresh = _jwt(const Duration(minutes: 15));
      auth.debugSetSession(
        UserSession(accessToken: _jwt(const Duration(minutes: 10)), refreshToken: 'r1', user: AppUser.fromJson(_userJson)),
      );
      var denied = false;
      handler = (req) {
        if (req.url.path == '/auth/refresh') return _json({'accessToken': fresh, 'refreshToken': 'r2', 'user': _userJson});
        if (!denied) {
          denied = true;
          return _json({'message': 'expired'}, 401);
        }
        return _json(_userJson);
      };

      final raw = await api.put('/api/users/u1', body: {'nom': 'X'});
      expect((raw as Map)['id'], 'u1');
      expect(calls.map((c) => c.url.path), ['/api/users/u1', '/auth/refresh', '/api/users/u1']);
      expect(calls.last.headers['Authorization'], 'Bearer $fresh');
    });

    test('a rejected refresh token signs the user out', () async {
      auth.debugSetSession(UserSession(accessToken: _jwt(Duration.zero), refreshToken: 'r1', user: AppUser.fromJson(_userJson)));
      handler = (req) => req.url.path == '/auth/refresh'
          ? _json({'timestamp': 't', 'status': 500, 'error': 'Internal Server Error', 'path': '/auth/refresh'}, 500)
          : _json(<Object>[]);

      await api.get('/api/events');
      expect(auth.isAuthenticated, isFalse);
      expect(calls.last.headers.containsKey('Authorization'), isFalse);
    });

    test('a private Codespaces port is reported, without renewing the session', () async {
      auth.debugSetSession(
        UserSession(accessToken: _jwt(const Duration(minutes: 15)), refreshToken: 'r1', user: AppUser.fromJson(_userJson)),
      );
      handler = (_) => http.Response('', 401, headers: {'www-authenticate': 'tunnel'});
      await expectLater(
        api.post('/api/users', body: const {}),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('port 8090'))),
      );
      expect(calls.map((c) => c.url.path), ['/api/users']);
      expect(auth.isAuthenticated, isTrue);
    });

    test('sign-out revokes the server session', () async {
      auth.debugSetSession(
        UserSession(accessToken: _jwt(const Duration(minutes: 15)), refreshToken: 'r1', user: AppUser.fromJson(_userJson)),
      );
      handler = (_) => http.Response('', 204);
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(calls.single.url.path, '/auth/logout');
      expect(jsonDecode(calls.single.body), {'refreshToken': 'r1'});
    });
  });
}
