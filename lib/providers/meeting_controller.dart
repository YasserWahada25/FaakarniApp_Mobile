import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/meeting.dart';
import '../services/api_client.dart';
import '../services/meeting_media.dart';
import '../services/meeting_signaling.dart';
import '../services/session_service.dart';

enum MeetingPhase { joining, inRoom, failed }

/// State of one video room (web `VirtualMeetingComponent`, `VideoGridComponent`
/// and `MeetingSidebarComponent`): joins the room, negotiates with the other
/// participants and holds the chat.
class MeetingController extends ChangeNotifier {
  MeetingController({
    required this.sessionId,
    this._title,
    SessionService? service,
    MeetingSignaling? signaling,
    MeetingMedia? media,
    Future<String?> Function()? token,
  })  : _service = service ?? SessionService.instance,
        _signaling = signaling ?? StompMeetingSignaling(),
        _media = media ?? WebRtcMeetingMedia(),
        _token = token ?? ApiClient.instance.tokenProvider;

  final int sessionId;
  final SessionService _service;
  final MeetingSignaling _signaling;
  final MeetingMedia _media;
  final Future<String?> Function()? _token;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<String> _remoteIds = [];
  final Map<String, MeetingParticipant> _members = {};
  final Map<String, String> _names = {};
  final List<MeetingChatMessage> _messages = [];
  Future<void> _signalQueue = Future.value();

  MeetingPhase _phase = MeetingPhase.joining;
  String? _error;
  String? _title;
  String? _roomId;
  String? _userId;
  bool _connected = false;
  bool _mediaAvailable = true;
  bool _muted = false;
  bool _videoOff = false;
  bool _closed = false;

  MeetingMedia get media => _media;
  MeetingPhase get phase => _phase;
  String? get error => _error;
  String get title => _title ?? 'Session #$sessionId';
  bool get connected => _connected;

  /// Neither the camera nor the microphone could be opened.
  bool get mediaAvailable => _mediaAvailable;
  bool get muted => _muted;
  bool get videoOff => _videoOff || !_media.hasCamera;
  String? get userId => _userId;

  /// Other users present in the room, by order of arrival.
  List<String> get remoteIds => List.unmodifiable(_remoteIds);
  List<MeetingChatMessage> get messages => List.unmodifiable(_messages);

  /// The session's participants and the users present, connected first.
  List<MeetingParticipant> get participants {
    final online = {?_userId, ..._remoteIds};
    final byId = {
      ..._members,
      for (final id in online)
        if (!_members.containsKey(id))
          id: MeetingParticipant(userId: id, role: ParticipantRole.participant, joinStatus: JoinStatus.attended),
    };
    final list = [
      for (final p in byId.values) p.copyWith(displayName: nameOf(p.userId), isOnline: online.contains(p.userId)),
    ];
    list.sort((a, b) => (b.isOnline ? 1 : 0) - (a.isOnline ? 1 : 0));
    return list;
  }

  String nameOf(String userId) => _names[userId] ?? SessionService.shortenUserId(userId);

  Future<void> start() async {
    _phase = MeetingPhase.joining;
    _error = null;
    notifyListeners();

    final userId = _service.currentUserId;
    if (userId == null) return _fail('Utilisateur non authentifié.');
    _userId = userId;

    final VideoRoom room;
    try {
      room = await _service.openRoom(sessionId);
    } on ApiException catch (e) {
      return _fail(e.message);
    }
    if (_closed) return;
    _roomId = room.roomId;
    if (_title == null) unawaited(_loadTitle());

    // The stream must be ready first: peer connections capture it when created.
    _mediaAvailable = await _media.openLocal();
    if (_closed) {
      // Left during the permission prompt: the camera opened after dispose().
      await _media.dispose();
      return;
    }

    _media.onCandidate = (peerId, candidate) => _sendTo(peerId, SignalType.iceCandidate, candidate);
    _media.onStreamsChanged = _refresh;
    _subscriptions
      ..add(_signaling.signals.listen((s) => _signalQueue = _signalQueue.then((_) => _safeHandle(s))))
      ..add(_signaling.connection.listen((value) {
        _connected = value;
        _refresh();
      }));
    _signaling.connect(roomId: room.roomId, userId: userId, token: await _token?.call());
    if (_closed) return;

    _phase = MeetingPhase.inRoom;
    notifyListeners();
    unawaited(_loadHistory(room.roomId));
    unawaited(_loadMembers());
    _resolveName(userId);
  }

  void _fail(String message) {
    _phase = MeetingPhase.failed;
    _error = message;
    _refresh();
  }

  void _refresh() {
    if (!_closed) notifyListeners();
  }

  Future<void> _loadTitle() async {
    try {
      _title = (await _service.getSession(sessionId)).title;
      _refresh();
    } on ApiException {
      // The default title stays.
    }
  }

  Future<void> _loadHistory(String roomId) async {
    try {
      final history = await _service.getRoomMessages(roomId);
      // Messages received during the request stay after the history.
      _messages.insertAll(0, history);
      history.map((m) => m.senderId).toSet().forEach(_resolveName);
      _refresh();
    } on ApiException {
      // Only the history is missing: the chat keeps working.
    }
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _service.getParticipants(sessionId);
      final loaded = members.map((m) => m.userId).toSet();
      // Keeps a `participant-added` received during the request.
      _setMembers([...members, ..._members.values.where((m) => !loaded.contains(m.userId))]);
    } on ApiException {
      // The participants present are still listed.
    }
  }

  void _setMembers(List<MeetingParticipant> members) {
    _members
      ..clear()
      ..addEntries(members.map((m) => MapEntry(m.userId, m)));
    members.map((m) => m.userId).forEach(_resolveName);
    _refresh();
  }

  void _resolveName(String userId) {
    if (_names.containsKey(userId)) return;
    _names[userId] = SessionService.shortenUserId(userId);
    unawaited(_service.displayName(userId).then((name) {
      _names[userId] = name;
      _refresh();
    }));
  }

  Future<void> _safeHandle(SignalMessage signal) async {
    if (_closed) return;
    try {
      await _handle(signal);
    } catch (e) {
      // One bad frame must not stop the frames behind it.
      debugPrint('Signal ${signal.type} de ${signal.fromUserId} ignoré : $e');
    }
    _refresh();
  }

  Future<void> _handle(SignalMessage signal) async {
    final from = signal.fromUserId;
    switch (signal.type) {
      case SignalType.join:
        _addRemote(from);
        _sendTo(from, SignalType.offer, await _media.createOffer(from));
      case SignalType.offer:
        // Both sides offered at once: the larger id keeps its offer.
        if (await _media.hasPendingOffer(from) && _userId!.compareTo(from) > 0) return;
        _addRemote(from);
        _sendTo(from, SignalType.answer, await _media.acceptOffer(from, signal.payload));
      case SignalType.answer:
        await _media.acceptAnswer(from, signal.payload);
      case SignalType.iceCandidate:
        await _media.addCandidate(from, signal.payload);
      case SignalType.leave:
        _remoteIds.remove(from);
        await _media.closePeer(from);
      case SignalType.chat:
        _receiveChat(signal);
      case SignalType.participantAdded:
        final member = MeetingParticipant.fromJson(signal.payloadMap);
        if (member.userId.isNotEmpty) {
          _members[member.userId] = member;
          _resolveName(member.userId);
        }
    }
  }

  void _addRemote(String userId) {
    if (!_remoteIds.contains(userId)) _remoteIds.add(userId);
    _resolveName(userId);
  }

  void _receiveChat(SignalMessage signal) {
    final payload = signal.payloadMap;
    final text = '${payload['text'] ?? ''}'.trim();
    if (text.isEmpty) return;
    _resolveName(signal.fromUserId);
    _messages.add(MeetingChatMessage(
      senderId: signal.fromUserId,
      text: text,
      time: DateTime.tryParse('${payload['sentAt'] ?? ''}')?.toLocal() ?? DateTime.now(),
      isSelf: false,
    ));
  }

  void _sendTo(String peerId, String type, String payload) {
    final roomId = _roomId;
    final userId = _userId;
    if (roomId == null || userId == null) return;
    _signaling.send(SignalMessage(type: type, fromUserId: userId, toUserId: peerId, roomId: roomId, payload: payload));
  }

  /// Returns `false` when the message could not be sent (connection lost).
  bool sendMessage(String text) {
    final value = text.trim();
    final roomId = _roomId;
    final userId = _userId;
    if (value.isEmpty || roomId == null || userId == null) return false;
    final sent = _signaling.send(SignalMessage(
      type: SignalType.chat,
      fromUserId: userId,
      roomId: roomId,
      payload: jsonEncode({'text': value}),
    ));
    if (!sent) return false;
    _messages.add(MeetingChatMessage(senderId: userId, text: value, time: DateTime.now(), isSelf: true));
    _refresh();
    return true;
  }

  /// Returns the confirmation to show; throws [ApiException] with the reason.
  Future<String> addParticipant(String userId) async {
    final roomId = _roomId;
    if (roomId == null) throw const ApiException('Room indisponible.');
    final result = await _service.addParticipant(roomId: roomId, userId: userId.trim());
    _names[userId.trim()] = result.name;
    _setMembers(result.participants);
    return 'Participant ajoute: ${result.name} (${result.role.label}).';
  }

  void toggleMute() {
    _muted = !_muted;
    _media.setMuted(_muted);
    notifyListeners();
  }

  void toggleVideo() {
    if (!_media.hasCamera) return;
    _videoOff = !_videoOff;
    _media.setVideoOff(_videoOff);
    notifyListeners();
  }

  Future<void> switchCamera() => _media.switchCamera();

  @override
  void dispose() {
    _closed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _media
      ..onCandidate = null
      ..onStreamsChanged = null;
    _signaling.disconnect();
    unawaited(_media.dispose());
    super.dispose();
  }
}
