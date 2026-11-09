import 'dart:convert';

import 'package:fakarniapp/models/meeting.dart';
import 'package:fakarniapp/models/session.dart';
import 'package:fakarniapp/providers/sessions_provider.dart';
import 'package:fakarniapp/services/api_client.dart';
import 'package:fakarniapp/services/meeting_insights_service.dart';
import 'package:fakarniapp/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object? body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _sessionJson({
  int id = 1,
  String title = 'Atelier',
  String start = '2026-11-10T09:00:00Z',
  String end = '2026-11-10T10:00:00Z',
  String status = 'SCHEDULED',
  String visibility = 'PUBLIC',
  String? meetingMode = 'ONLINE',
  String createdBy = 'other',
  List<Map<String, dynamic>> participants = const [],
}) =>
    {
      'id': id,
      'title': title,
      'description': 'Description',
      'startTime': start,
      'endTime': end,
      'status': status,
      'visibility': visibility,
      'meetingMode': meetingMode,
      'createdBy': createdBy,
      'participants': participants,
    };

/// Client whose answers are chosen per `METHOD path`; records the requests.
class _Backend {
  final List<http.Request> requests = [];
  final Map<String, http.Response Function(http.Request)> routes = {};

  ApiClient get client => ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          final route = routes['${request.method} ${request.url.path}'];
          return route == null ? _json({'message': 'not found'}, 404) : route(request);
        }),
      );

  List<String> get calls => [for (final r in requests) '${r.method} ${r.url.path}'];
}

void main() {
  group('Session.fromJson', () {
    test('reads the favorite flag of the current user under the Jackson key', () {
      final json = _sessionJson(participants: [
        {'userId': 'u1', 'favorite': true},
        {'userId': 'u2', 'favorite': false},
      ]);
      expect(Session.fromJson(json, currentUserId: 'u1').isFavorite, isTrue);
      expect(Session.fromJson(json, currentUserId: 'u2').isFavorite, isFalse);
      expect(Session.fromJson(json, currentUserId: 'u3').isFavorite, isFalse);
      expect(Session.fromJson(json, currentUserId: 'u1').participants, 2);
    });

    test('dates are converted to local time', () {
      final session = Session.fromJson(_sessionJson());
      expect(session.start, DateTime.utc(2026, 11, 10, 9).toLocal());
      expect(session.start.isUtc, isFalse);
    });

    test('mode, audience and status fall back like the web', () {
      final legacy = {..._sessionJson(meetingMode: null), 'meetingUrl': 'https://meet'};
      expect(Session.fromJson(legacy).mode, SessionMode.online);
      expect(Session.fromJson(_sessionJson(meetingMode: null)).mode, SessionMode.inPerson);
      expect(Session.fromJson(_sessionJson()).audience, SessionAudience.group);
      expect(Session.fromJson(_sessionJson(visibility: 'PRIVATE')).audience, SessionAudience.private);
      expect(SessionStatus.fromApi('ACCEPTED'), SessionStatus.scheduled);
      expect(SessionStatus.fromApi(null), SessionStatus.draft);
    });

    test('type is inferred from the text', () {
      expect(SessionType.infer('Music', ''), SessionType.therapy);
      expect(SessionType.infer('Atelier', 'exercices de mémoire'), SessionType.cognitive);
      expect(SessionType.infer('Yoga', ''), SessionType.physical);
      expect(SessionType.infer('Suivi', ''), SessionType.general);
    });

    test('a private session is visible only to its creator and participants', () {
      final session = Session.fromJson(_sessionJson(visibility: 'PRIVATE', createdBy: 'c1', participants: [
        {'userId': 'p1'},
      ]));
      expect(session.isVisibleTo('c1'), isTrue);
      expect(session.isVisibleTo('p1'), isTrue);
      expect(session.isVisibleTo('x'), isFalse);
      expect(session.isVisibleTo(null), isFalse);
    });
  });

  group('ReservationRequest', () {
    final start = DateTime(2026, 11, 10, 9);
    final end = DateTime(2026, 11, 10, 10);

    test('an in-person request carries its location, in UTC', () {
      final json = ReservationRequest(
        title: ' Suivi ',
        description: ' Besoin ',
        start: start,
        end: end,
        mode: SessionMode.inPerson,
        audience: SessionAudience.private,
        locationAddress: 'Centre',
        latitude: 36.8,
        longitude: 10.1,
      ).toJson();
      expect(json['title'], 'Suivi');
      expect(json['startTime'], start.toUtc().toIso8601String());
      expect(json['meetingMode'], 'IN_PERSON');
      expect(json['visibility'], 'PRIVATE');
      expect(json['sessionType'], 'PRIVATE');
      expect(json['locationLatitude'], 36.8);
      expect(json['locationAddress'], 'Centre');
    });

    test('an online group request has no location and is public', () {
      final json = ReservationRequest(
        title: 'Groupe',
        description: 'Besoin',
        start: start,
        end: end,
        mode: SessionMode.online,
        audience: SessionAudience.group,
      ).toJson();
      expect(json['meetingMode'], 'ONLINE');
      expect(json['visibility'], 'PUBLIC');
      expect(json.containsKey('locationLatitude'), isFalse);
      expect(json.containsKey('locationAddress'), isFalse);
    });
  });

  group('SessionService', () {
    late _Backend backend;
    late SessionService service;

    setUp(() {
      backend = _Backend();
      service = SessionService(client: backend.client, currentUserId: () => 'u1');
    });

    test('sessions are filtered by visibility and sorted', () async {
      backend.routes['GET /session/sessions'] = (_) => _json([
            _sessionJson(id: 2, start: '2026-12-01T09:00:00Z'),
            _sessionJson(id: 3, visibility: 'PRIVATE'),
            _sessionJson(id: 1, start: '2026-11-01T09:00:00Z'),
          ]);
      final sessions = await service.getSessions();
      expect(sessions.map((s) => s.id), [1, 2]);
    });

    test('a reservation overlapping a pending request is refused without calling the API', () async {
      backend.routes['GET /session/sessions'] = (_) => _json([_sessionJson(status: 'DRAFT')]);
      final request = ReservationRequest(
        title: 'T',
        description: 'D',
        start: DateTime.utc(2026, 11, 10, 9, 30).toLocal(),
        end: DateTime.utc(2026, 11, 10, 10, 30).toLocal(),
        mode: SessionMode.online,
        audience: SessionAudience.private,
      );
      await expectLater(service.createReservation(request), throwsA(isA<ApiException>()));
      expect(backend.calls, ['GET /session/sessions']);
    });

    test('a refused session does not hold its slot, adjacent slots are free', () async {
      backend.routes['GET /session/sessions'] = (_) => _json([
            _sessionJson(id: 1, status: 'CANCELLED'),
            _sessionJson(id: 2, start: '2026-11-10T10:00:00Z', end: '2026-11-10T11:00:00Z'),
          ]);
      backend.routes['POST /session/sessions'] = (_) => _json(_sessionJson(id: 9, status: 'DRAFT'));
      final created = await service.createReservation(ReservationRequest(
        title: 'T',
        description: 'D',
        start: DateTime.utc(2026, 11, 10, 9).toLocal(),
        end: DateTime.utc(2026, 11, 10, 10).toLocal(),
        mode: SessionMode.online,
        audience: SessionAudience.private,
      ));
      expect(created.id, 9);
    });

    test('favorite goes through PATCH with the expected body', () async {
      backend.routes['PATCH /session/sessions/4/participants/me/prefs'] = (_) => _json(_sessionJson(id: 4));
      await service.setFavorite(4, true);
      expect(jsonDecode(backend.requests.single.body), {'isFavorite': true});
    });

    group('openRoom', () {
      const room = {'id': 7, 'roomId': 'room-1', 'hostUserId': 'u1'};
      const byVirtual = 'GET /session/sessions/video/by-virtual-session/4';
      const start = 'POST /session/sessions/video/start';
      const join = 'POST /session/sessions/video/join';

      test('joins the active room', () async {
        backend.routes[byVirtual] = (_) => _json(room);
        backend.routes[join] = (_) => _json(room);
        expect((await service.openRoom(4)).roomId, 'room-1');
        expect(backend.calls, [byVirtual, join]);
        expect(jsonDecode(backend.requests.last.body), {'roomId': 'room-1', 'userId': 'u1'});
      });

      test('opens the room when there is none', () async {
        backend.routes[start] = (_) => _json(room, 201);
        backend.routes[join] = (_) => _json(room);
        expect((await service.openRoom(4)).roomId, 'room-1');
        expect(backend.calls, [byVirtual, start, join]);
        expect(jsonDecode(backend.requests[1].body), {'virtualSessionId': 4, 'hostUserId': 'u1'});
      });

      test('a room opened by someone else in the meantime is joined', () async {
        var lookups = 0;
        backend.routes[byVirtual] = (_) => ++lookups == 1 ? _json({'message': 'none'}, 404) : _json(room);
        backend.routes[start] = (_) => _json({'message': 'exists'}, 409);
        backend.routes[join] = (_) => _json(room);
        expect((await service.openRoom(4)).roomId, 'room-1');
      });

      test('errors are explained', () async {
        backend.routes[start] = (_) => _json({'message': 'x'}, 403);
        await expectLater(
          service.openRoom(4),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', contains("Seul l'hôte"))),
        );

        backend.routes[start] = (_) => _json({'message': 'La session video peut demarrer uniquement'}, 400);
        await expectLater(
          service.openRoom(4),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('uniquement'))),
        );

        backend.routes[byVirtual] = (_) => _json(room);
        backend.routes[join] = (_) => _json({'message': 'x'}, 409);
        await expectLater(
          service.openRoom(4),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', 'La session est pleine.')),
        );
      });

      test('signed out: nothing is called', () async {
        final signedOut = SessionService(client: backend.client, currentUserId: () => null);
        await expectLater(signedOut.openRoom(4), throwsA(isA<ApiException>()));
        expect(backend.calls, isEmpty);
      });
    });

    test('long user ids are shortened like the web', () {
      expect(SessionService.shortenUserId('short'), 'short');
      expect(SessionService.shortenUserId('0123456789abcdef'), '01234...cdef');
      expect(SessionService.shortenUserId(''), 'Utilisateur');
    });
  });

  group('SessionsProvider', () {
    late _Backend backend;
    late SessionsProvider provider;

    setUp(() {
      backend = _Backend();
      provider = SessionsProvider(service: SessionService(client: backend.client, currentUserId: () => 'u1'));
      backend.routes['GET /session/sessions'] = (_) => _json([_sessionJson(id: 1)]);
      backend.routes['GET /session/me/favorites'] = (_) => _json(<Object>[]);
    });

    test('concurrent loads share the same requests', () async {
      await Future.wait([provider.load(), provider.load()]);
      expect(backend.calls, ['GET /session/sessions', 'GET /session/me/favorites']);
      expect(provider.sessions.single.id, 1);
    });

    test('a load failure is reported, then a retry recovers', () async {
      backend.routes['GET /session/sessions'] = (_) => _json({'message': 'Panne'}, 500);
      await provider.load();
      expect(provider.error, 'Panne');
      backend.routes['GET /session/sessions'] = (_) => _json([_sessionJson(id: 1)]);
      await provider.load();
      expect(provider.error, isNull);
      expect(provider.sessions, hasLength(1));
    });

    test('toggling a favorite updates both lists only when the server accepts', () async {
      await provider.load();
      final session = provider.sessions.single;
      backend.routes['PATCH /session/sessions/1/participants/me/prefs'] = (_) => _json({'message': 'non'}, 403);
      await expectLater(provider.toggleFavorite(session), throwsA(isA<ApiException>()));
      expect(provider.favorites, isEmpty);

      backend.routes['PATCH /session/sessions/1/participants/me/prefs'] = (_) => _json(_sessionJson());
      await provider.toggleFavorite(session);
      expect(provider.favorites.single.id, 1);
      expect(provider.sessions.single.isFavorite, isTrue);

      await provider.toggleFavorite(provider.sessions.single);
      expect(provider.favorites, isEmpty);
      expect(provider.sessions.single.isFavorite, isFalse);
    });
  });

  group('MeetingInsightsService', () {
    late _Backend backend;
    late MeetingInsightsService service;

    setUp(() {
      backend = _Backend();
      service = MeetingInsightsService(client: backend.client);
    });

    test('the recording is sent as multipart, with the language in the query', () async {
      backend.routes['POST /api/meet/recording'] = (_) => _json({
            'id': 't1',
            'filename': 'a.wav',
            'language': 'fr',
            'transcription': 'Bonjour',
            'created_at': '2026-11-10T09:00:00Z',
          });
      final result = await service.transcribe(bytes: [1, 2, 3], filename: 'a.wav', language: ' fr ');
      expect(result.text, 'Bonjour');
      final request = backend.requests.single;
      expect(request.url.queryParameters['language'], 'fr');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      expect(request.body, contains('name="file"'));
      expect(request.body, contains('filename="a.wav"'));
    });

    test('a report is parsed, empty optional fields are sent as null', () async {
      backend.routes['POST /api/meet/report'] = (_) => _json({
            'id': 'r1',
            'summary': 'Résumé',
            'key_points': ['a'],
            'action_items': ['b'],
            'sentiment_analysis': {'label': 'POSITIVE', 'score': 0.9},
            'entities': <String, Object>{},
          });
      final report = await service.generateReport(text: ' texte ', meetingTitle: ' ', language: 'fr');
      expect(report.meetingTitle, 'Rapport de reunion');
      expect(report.summary, 'Résumé');
      expect(report.sentimentScore, 0.9);
      expect(report.keyPoints, ['a']);
      final body = jsonDecode(backend.requests.single.body) as Map<String, dynamic>;
      expect(body['transcribed_text'], 'texte');
      expect(body['meeting_title'], isNull);
    });

    test('a FastAPI error shows its detail', () async {
      backend.routes['GET /api/meet/reports'] = (_) => _json({'detail': 'Invalid JWT token.'}, 400);
      await expectLater(
        service.getReports(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid JWT token.')),
      );
    });

    test('a missing service is explained', () async {
      await expectLater(
        service.getReports(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('pas disponible'))),
      );
    });

    test('a null transcription language shows n/a', () {
      final t = MeetingTranscription.fromJson(const {'id': 't', 'filename': 'a', 'transcription': 'x'});
      expect(t.language, 'n/a');
    });
  });

  test('a multipart upload is rebuilt when retried after a 401', () async {
    var attempts = 0;
    final api = ApiClient(
      client: MockClient((request) async {
        attempts++;
        return attempts == 1 ? _json({'message': 'expired'}, 401) : _json({'ok': true});
      }),
    )
      ..tokenProvider = (() async => 'token')
      ..onUnauthorized = (() async => true);
    final result = await api.postFile('/x', field: 'file', bytes: const [1], filename: 'a.wav');
    expect(result, {'ok': true});
    expect(attempts, 2);
  });
}
