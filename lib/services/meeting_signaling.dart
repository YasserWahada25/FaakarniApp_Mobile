import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/config/api_config.dart';
import '../core/config/api_endpoints.dart';
import '../models/meeting.dart';

/// Room messages transport (web `VideoSessionService` STOMP part).
abstract class MeetingSignaling {
  /// Frames addressed to this user: its own frames and those for others are dropped.
  Stream<SignalMessage> get signals;

  /// `true` while connected. Connecting announces the user with a `join` frame,
  /// also after a reconnection, so that the others negotiate with it again.
  Stream<bool> get connection;

  void connect({required String roomId, required String userId, String? token});

  /// Returns `false` when not connected (the frame is lost).
  bool send(SignalMessage signal);

  /// Announces the departure and closes the connection.
  void disconnect();

  /// Web `connectAndSubscribe` filter.
  static bool isFor(SignalMessage signal, String userId) =>
      signal.fromUserId != userId && (signal.toUserId == null || signal.toUserId == userId);
}

/// SockJS + STOMP on `/ws` of the session-service, through the gateway.
class StompMeetingSignaling implements MeetingSignaling {
  final _signals = StreamController<SignalMessage>.broadcast();
  final _connection = StreamController<bool>.broadcast();

  StompClient? _client;
  String? _roomId;
  String? _userId;

  @override
  Stream<SignalMessage> get signals => _signals.stream;

  @override
  Stream<bool> get connection => _connection.stream;

  @override
  void connect({required String roomId, required String userId, String? token}) {
    _roomId = roomId;
    _userId = userId;
    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiConfig.uri(ApiEndpoints.signaling).toString(),
        stompConnectHeaders: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 2),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        connectionTimeout: const Duration(seconds: 15),
        onConnect: (_) => _onConnected(),
        onWebSocketDone: () => _setConnected(false),
        onWebSocketError: (_) => _setConnected(false),
        onStompError: (_) => _setConnected(false),
      ),
    )..activate();
  }

  void _onConnected() {
    final roomId = _roomId!;
    _client?.subscribe(
      destination: ApiEndpoints.signalingRoomTopic(roomId),
      callback: (frame) {
        final signal = _parse(frame.body);
        if (signal != null && MeetingSignaling.isFor(signal, _userId!)) _signals.add(signal);
      },
    );
    _setConnected(true);
    send(SignalMessage(
      type: SignalType.join,
      fromUserId: _userId!,
      roomId: roomId,
      payload: jsonEncode({'message': 'Utilisateur rejoint'}),
    ));
  }

  static SignalMessage? _parse(String? body) {
    if (body == null) return null;
    try {
      final json = jsonDecode(body);
      return json is Map<String, dynamic> ? SignalMessage.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }

  void _setConnected(bool value) {
    if (!_connection.isClosed) _connection.add(value);
  }

  @override
  bool send(SignalMessage signal) {
    final client = _client;
    if (client == null || !client.connected) return false;
    client.send(destination: ApiEndpoints.signalingDestination(signal.type), body: jsonEncode(signal.toJson()));
    return true;
  }

  @override
  void disconnect() {
    final roomId = _roomId;
    final userId = _userId;
    if (roomId != null && userId != null) {
      send(SignalMessage(
        type: SignalType.leave,
        fromUserId: userId,
        roomId: roomId,
        payload: jsonEncode({'message': 'Utilisateur parti'}),
      ));
    }
    _client?.deactivate();
    _client = null;
    _roomId = null;
    _userId = null;
    _signals.close();
    _connection.close();
  }
}
