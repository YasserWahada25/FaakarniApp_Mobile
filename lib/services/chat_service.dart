import '../core/network/api_client.dart';
import '../models/communication.dart';

/// Chat_Service REST API, through the gateway (`/api/messages/**`).
class ChatService {
  ChatService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  static final ChatService instance = ChatService();

  final ApiClient _api;

  /// Messages between [me] and [other], oldest first.
  Future<List<ChatMessage>> getConversation(String me, String other) async {
    final json = await _api.get('/api/messages/conversation', query: {'user1': me, 'user2': other});
    return (json as List).whereType<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
  }

  /// Saved, then pushed by the service to both users' WebSocket queues.
  Future<ChatMessage> send({required String senderId, required String receiverId, required String content}) async {
    final json = await _api.post(
      '/api/messages/send',
      body: {'senderId': senderId, 'receiverId': receiverId, 'content': content},
    );
    return ChatMessage.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(String messageId) => _api.delete('/api/messages/$messageId');
}
