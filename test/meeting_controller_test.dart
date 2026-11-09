import 'dart:async';
import 'dart:convert';

import 'package:fakarniapp/models/meeting.dart';
import 'package:fakarniapp/providers/meeting_controller.dart';
import 'package:fakarniapp/services/api_client.dart';
import 'package:fakarniapp/services/auth_service.dart';
import 'package:fakarniapp/services/meeting_media.dart';
import 'package:fakarniapp/services/meeting_signaling.dart';
import 'package:fakarniapp/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object? body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

class _FakeSignaling implements MeetingSignaling {
  final _signals = StreamController<SignalMessage>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final List<SignalMessage> sent = [];
  String? roomId;
  bool online = true;
  bool disconnected = false;

  @override
  Stream<SignalMessage> get signals => _signals.stream;

  @override
  Stream<bool> get connection => _connection.stream;

  @override
  void connect({required String roomId, required String userId, String? token}) {
    this.roomId = roomId;
    _connection.add(true);
  }

  @override
  bool send(SignalMessage signal) {
    if (!online) return false;
    sent.add(signal);
    return true;
  }

  @override
  void disconnect() => disconnected = true;

  void receive(String type, String from, [String payload = '{}']) =>
      _signals.add(SignalMessage(type: type, fromUserId: from, roomId: 'room-1', payload: payload));
}

class _FakeMedia extends MeetingMedia {
  final List<String> log = [];
  bool available = true;
  bool pendingOffer = false;
  bool failOffer = false;
  bool disposed = false;
  Completer<void>? openGate;

  @override
  Future<bool> openLocal() async {
    log.add('openLocal');
    await openGate?.future;
    return available;
  }

  @override
  RTCVideoRenderer? renderer(String? peerId) => null;

  @override
  bool get hasCamera => available;

  @override
  Future<bool> hasPendingOffer(String peerId) async => pendingOffer;

  @override
  Future<String> createOffer(String peerId) async {
    log.add('offer $peerId');
    return 'offer-sdp';
  }

  @override
  Future<String> acceptOffer(String peerId, String offer) async {
    if (failOffer) throw StateError('bad sdp');
    log.add('accept $peerId');
    return 'answer-sdp';
  }

  @override
  Future<void> acceptAnswer(String peerId, String answer) async => log.add('answer $peerId');

  @override
  Future<void> addCandidate(String peerId, String candidate) async => log.add('candidate $peerId');

  @override
  Future<void> closePeer(String peerId) async => log.add('close $peerId');

  @override
  void setMuted(bool muted) => log.add('muted $muted');

  @override
  void setVideoOff(bool off) => log.add('videoOff $off');

  @override
  Future<void> switchCamera() async => log.add('switch');

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  late _FakeSignaling signaling;
  late _FakeMedia media;
  late Map<String, http.Response Function(http.Request)> routes;

  MeetingController controller({String? title = 'Atelier', String? userId = 'me'}) {
    final api = ApiClient(
      client: MockClient((request) async {
        final route = routes['${request.method} ${request.url.path}'];
        return route == null ? _json({'message': 'not found'}, 404) : route(request);
      }),
    );
    return MeetingController(
      sessionId: 4,
      title: title,
      service: SessionService(client: api, auth: AuthService(client: api), currentUserId: () => userId),
      signaling: signaling,
      media: media,
      token: () async => 'token',
    );
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() {
    signaling = _FakeSignaling();
    media = _FakeMedia();
    routes = {
      'GET /session/sessions/video/by-virtual-session/4': (_) => _json({'id': 7, 'roomId': 'room-1', 'hostUserId': 'x'}),
      'POST /session/sessions/video/join': (_) => _json({'id': 7, 'roomId': 'room-1', 'hostUserId': 'x'}),
      'GET /session/sessions/video/rooms/room-1/messages': (_) => _json(<Object>[]),
      'GET /session/sessions/4/participants': (_) => _json(<Object>[]),
    };
  });

  test('joins the room, then opens the media before connecting', () async {
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    expect(meeting.phase, MeetingPhase.inRoom);
    expect(signaling.roomId, 'room-1');
    expect(media.log.first, 'openLocal');
    expect(meeting.title, 'Atelier');
  });

  test('a refused join is shown and neither the media nor the socket are opened', () async {
    routes['POST /session/sessions/video/join'] = (_) => _json({'message': 'x'}, 403);
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    expect(meeting.phase, MeetingPhase.failed);
    expect(meeting.error, contains("pas autorisé"));
    expect(media.log, isEmpty);
    expect(signaling.roomId, isNull);
  });

  test('a retry after a failure can succeed', () async {
    routes['POST /session/sessions/video/join'] = (_) => _json({'message': 'x'}, 409);
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    expect(meeting.phase, MeetingPhase.failed);
    routes['POST /session/sessions/video/join'] = (_) => _json({'id': 7, 'roomId': 'room-1', 'hostUserId': 'x'});
    await meeting.start();
    expect(meeting.phase, MeetingPhase.inRoom);
    expect(meeting.error, isNull);
  });

  test('signed out: fails without calling anything', () async {
    final meeting = controller(userId: null);
    addTearDown(meeting.dispose);
    await meeting.start();
    expect(meeting.phase, MeetingPhase.failed);
    expect(media.log, isEmpty);
  });

  test('the room stays usable without camera and microphone', () async {
    media.available = false;
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    expect(meeting.phase, MeetingPhase.inRoom);
    expect(meeting.mediaAvailable, isFalse);
    expect(meeting.videoOff, isTrue);
    meeting.toggleVideo();
    expect(media.log, isNot(contains('videoOff true')));
  });

  test('a user joining receives an offer addressed to them', () async {
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    signaling.receive(SignalType.join, 'peer');
    await flush();
    expect(meeting.remoteIds, ['peer']);
    final offer = signaling.sent.single;
    expect(offer.type, SignalType.offer);
    expect(offer.toUserId, 'peer');
    expect(offer.payload, 'offer-sdp');
    expect(offer.roomId, 'room-1');
  });

  test('an offer is answered, candidates follow in order', () async {
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    signaling.receive(SignalType.offer, 'peer', 'sdp');
    signaling.receive(SignalType.iceCandidate, 'peer', '{"candidate":"c"}');
    await flush();
    expect(media.log, containsAllInOrder(['accept peer', 'candidate peer']));
    expect(signaling.sent.single.type, SignalType.answer);
    expect(signaling.sent.single.toUserId, 'peer');
    expect(meeting.remoteIds, ['peer']);
  });

  test('simultaneous offers: the larger id keeps its own', () async {
    media.pendingOffer = true;
    final meeting = controller(userId: 'zed');
    addTearDown(meeting.dispose);
    await meeting.start();
    signaling.receive(SignalType.offer, 'alice', 'sdp');
    await flush();
    expect(media.log, isNot(contains('accept alice')));
  });

  test('simultaneous offers: the smaller id gives way', () async {
    media.pendingOffer = true;
    final meeting = controller(userId: 'alice');
    addTearDown(meeting.dispose);
    await meeting.start();
    signaling.receive(SignalType.offer, 'zed', 'sdp');
    await flush();
    expect(media.log, contains('accept zed'));
  });

  test('a bad frame does not block the following ones', () async {
    media.failOffer = true;
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    signaling.receive(SignalType.offer, 'peer', 'garbage');
    signaling.receive(SignalType.join, 'other');
    await flush();
    expect(meeting.remoteIds, containsAll(['peer', 'other']));
    expect(signaling.sent.single.toUserId, 'other');
  });

  test('a user leaving is removed and their connection closed', () async {
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    signaling.receive(SignalType.join, 'peer');
    signaling.receive(SignalType.leave, 'peer');
    await flush();
    expect(meeting.remoteIds, isEmpty);
    expect(media.log, contains('close peer'));
  });

  group('chat', () {
    test('sends with the web payload and shows the message once', () async {
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      expect(meeting.sendMessage('  Bonjour  '), isTrue);
      final signal = signaling.sent.single;
      expect(signal.type, SignalType.chat);
      expect(signal.toUserId, isNull);
      expect(jsonDecode(signal.payload), {'text': 'Bonjour'});
      expect(meeting.messages.single.isSelf, isTrue);
      expect(meeting.messages.single.text, 'Bonjour');
    });

    test('a blank message is ignored', () async {
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      expect(meeting.sendMessage('   '), isFalse);
      expect(signaling.sent, isEmpty);
    });

    test('when disconnected the message is not shown as sent', () async {
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      signaling.online = false;
      expect(meeting.sendMessage('Bonjour'), isFalse);
      expect(meeting.messages, isEmpty);
    });

    test('receives messages and loads the history before them', () async {
      routes['GET /session/sessions/video/rooms/room-1/messages'] = (_) => _json([
            {'fromUserId': 'me', 'text': 'Ancien', 'sentAt': '2026-11-10T09:00:00Z'},
          ]);
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      await flush();
      signaling.receive(SignalType.chat, 'peer', jsonEncode({'text': 'Salut', 'sentAt': '2026-11-10T09:01:00Z'}));
      await flush();
      expect(meeting.messages.map((m) => m.text), ['Ancien', 'Salut']);
      expect(meeting.messages.first.isSelf, isTrue);
      expect(meeting.messages.last.isSelf, isFalse);
    });
  });

  group('participants', () {
    test('merges the session list and the users present', () async {
      routes['GET /session/sessions/4/participants'] = (_) => _json([
            {'userId': 'absent', 'role': 'HOST', 'joinStatus': 'CONFIRMED'},
          ]);
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      await flush();
      signaling.receive(SignalType.join, 'peer');
      await flush();
      final byId = {for (final p in meeting.participants) p.userId: p};
      expect(byId.keys, containsAll(['me', 'absent', 'peer']));
      expect(byId['absent']!.isOnline, isFalse);
      expect(byId['absent']!.role, ParticipantRole.host);
      expect(byId['peer']!.isOnline, isTrue);
      expect(meeting.participants.last.userId, 'absent');
    });

    test('names are resolved, with the short id as fallback', () async {
      routes['GET /api/users/peer'] = (_) => _json({'id': 'peer', 'nom': 'Ben', 'prenom': 'Ali', 'email': 'a@b.tn'});
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      signaling.receive(SignalType.join, 'peer');
      signaling.receive(SignalType.join, '0123456789abcdef');
      await flush();
      await flush();
      expect(meeting.nameOf('peer'), 'Ali Ben');
      expect(meeting.nameOf('0123456789abcdef'), '01234...cdef');
    });

    test('adding a doctor makes them organizer', () async {
      routes['GET /api/users/doc'] = (_) =>
          _json({'id': 'doc', 'nom': 'Trabelsi', 'prenom': 'Nour', 'email': 'n@b.tn', 'role': 'DOCTOR_PROFILE'});
      http.Request? posted;
      routes['POST /session/sessions/video/rooms/room-1/participants'] = (request) {
        posted = request;
        return _json([
          {'userId': 'doc', 'role': 'ORGANIZER', 'joinStatus': 'CONFIRMED'},
        ]);
      };
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      final message = await meeting.addParticipant(' doc ');
      expect(message, contains('Nour Trabelsi'));
      expect(message, contains('Organisateur'));
      expect(jsonDecode(posted!.body), {
        'requesterUserId': 'me',
        'userId': 'doc',
        'role': 'ORGANIZER',
        'joinStatus': 'CONFIRMED',
      });
      expect(meeting.participants.map((p) => p.userId), contains('doc'));
    });

    test('an unknown user is reported', () async {
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      await expectLater(
        meeting.addParticipant('nobody'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('introuvable'))),
      );
    });

    test('participant-added is shown to the others', () async {
      final meeting = controller();
      addTearDown(meeting.dispose);
      await meeting.start();
      signaling.receive(
        SignalType.participantAdded,
        'host',
        jsonEncode({'userId': 'new', 'role': 'PARTICIPANT', 'joinStatus': 'CONFIRMED'}),
      );
      await flush();
      expect(meeting.participants.map((p) => p.userId), contains('new'));
    });
  });

  test('controls drive the media', () async {
    final meeting = controller();
    addTearDown(meeting.dispose);
    await meeting.start();
    meeting.toggleMute();
    meeting.toggleVideo();
    expect(meeting.muted, isTrue);
    expect(meeting.videoOff, isTrue);
    expect(media.log, containsAll(['muted true', 'videoOff true']));
  });

  test('leaving closes the socket and the media', () async {
    final meeting = controller();
    await meeting.start();
    meeting.dispose();
    expect(signaling.disconnected, isTrue);
    expect(media.disposed, isTrue);
  });

  test('leaving during the permission prompt still releases the camera', () async {
    media.openGate = Completer<void>();
    final meeting = controller();
    final starting = meeting.start();
    await flush();
    await flush();
    expect(media.log, contains('openLocal'));
    meeting.dispose();
    media.disposed = false;
    media.openGate!.complete();
    await starting;
    expect(media.disposed, isTrue);
    expect(signaling.roomId, isNull);
  });

  group('MeetingSignaling.isFor', () {
    SignalMessage signal(String from, [String? to]) =>
        SignalMessage(type: SignalType.offer, fromUserId: from, toUserId: to, roomId: 'r', payload: '');

    test('drops own frames and those for someone else', () {
      expect(MeetingSignaling.isFor(signal('me'), 'me'), isFalse);
      expect(MeetingSignaling.isFor(signal('a', 'b'), 'me'), isFalse);
      expect(MeetingSignaling.isFor(signal('a', 'me'), 'me'), isTrue);
      expect(MeetingSignaling.isFor(signal('a'), 'me'), isTrue);
    });
  });

  test('toJson omits an empty recipient, the server requires a payload', () {
    const message = SignalMessage(type: SignalType.join, fromUserId: 'a', roomId: 'r', payload: '{}');
    expect(message.toJson(), {'type': 'join', 'fromUserId': 'a', 'roomId': 'r', 'payload': '{}'});
    expect(message.payloadMap, isEmpty);
    expect(
      const SignalMessage(type: SignalType.chat, fromUserId: 'a', roomId: 'r', payload: 'not json').payloadMap,
      isEmpty,
    );
  });
}
