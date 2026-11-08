import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/network/api_config.dart';
import '../models/communication.dart';

/// Real-time side of Chat_Service (STOMP over WebSocket), same protocol as
/// the web `WebSocketService`:
/// - receives messages on `/queue/messages/{userId}` and typing
///   notifications on `/queue/typing/{userId}`;
/// - publishes typing notifications to `/app/chat.typing`.
///
/// Optional: when the socket cannot connect, [connected] stays `false` and the
/// chat screen falls back to polling the REST API.
class ChatSocket {
  ChatSocket({required this.userId});

  final String userId;

  StompClient? _client;
  final _messages = StreamController<ChatMessage>.broadcast();
  final _typing = StreamController<({String senderId, bool typing})>.broadcast();

  bool get connected => _client?.connected ?? false;
  Stream<ChatMessage> get messages => _messages.stream;
  Stream<({String senderId, bool typing})> get typing => _typing.stream;

  void connect() {
    if (_client != null) return;
    _client = StompClient(
      config: StompConfig(
        url: ApiConfig.chatSocketUrl,
        connectionTimeout: const Duration(seconds: 8),
        reconnectDelay: const Duration(seconds: 15),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onConnect,
        onWebSocketError: (error) => debugPrint('ChatSocket: $error'),
        onStompError: (frame) => debugPrint('ChatSocket STOMP error: ${frame.body}'),
      ),
    )..activate();
  }

  void _onConnect(StompFrame _) {
    debugPrint('ChatSocket: connected as $userId');
    _client?.subscribe(
      destination: '/queue/messages/$userId',
      callback: (frame) {
        final json = _decode(frame.body);
        if (json != null && !_messages.isClosed) _messages.add(ChatMessage.fromJson(json));
      },
    );
    _client?.subscribe(
      destination: '/queue/typing/$userId',
      callback: (frame) {
        final json = _decode(frame.body);
        if (json != null && !_typing.isClosed) {
          _typing.add((senderId: json['senderId'].toString(), typing: json['typing'] == true));
        }
      },
    );
  }

  void sendTyping(String receiverId, bool typing) {
    if (!connected) return;
    _client!.send(
      destination: '/app/chat.typing',
      body: jsonEncode({'senderId': userId, 'receiverId': receiverId, 'typing': typing}),
    );
  }

  void dispose() {
    _client?.deactivate();
    _client = null;
    _messages.close();
    _typing.close();
  }

  static Map<String, dynamic>? _decode(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }
}
