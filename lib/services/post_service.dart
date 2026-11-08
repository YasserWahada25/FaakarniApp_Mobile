import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/post.dart';

/// Post-Service, through the gateway (`/api/posts/**`): posts, reactions and
/// comments.
///
/// The author of a post is taken from the JWT by the service; reactions and
/// comments carry the user id in the request (same contract as the web app).
/// [revision] changes after every post write so the feed and "My Posts" reload.
class PostService {
  PostService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  static final PostService instance = PostService();

  final ApiClient _api;
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// Newest first (the service returns them unsorted).
  Future<List<Post>> getAll() async => _sorted(await _api.get('/api/posts'));

  Future<List<Post>> getByUser(String userId) async => _sorted(await _api.get('/api/posts/user/$userId'));

  /// [imageUrl] is a `data:` URL (or `null`), like the web app sends.
  Future<Post> create({required String content, String? imageUrl}) async {
    final json = await _api.post('/api/posts', body: {'content': content, 'imageUrl': imageUrl});
    revision.value++;
    return Post.fromJson(json as Map<String, dynamic>);
  }

  Future<Post> update(int id, {required String content, String? imageUrl}) async {
    final json = await _api.put('/api/posts/$id', body: {'content': content, 'imageUrl': imageUrl});
    revision.value++;
    return Post.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/posts/$id');
    revision.value++;
  }

  // ---- Reactions ----

  Future<ReactionSummary> getReactions(int postId, {String? userId}) async {
    final json = await _api.get('/api/posts/$postId/reactions', query: {'userId': ?userId});
    return ReactionSummary.fromJson(json as Map<String, dynamic>);
  }

  /// Reactions of several posts; a post whose call fails keeps empty counts.
  Future<Map<int, ReactionSummary>> getReactionsFor(Iterable<Post> posts, {String? userId}) async {
    final entries = await Future.wait(
      posts.map((p) async {
        try {
          return MapEntry(p.id, await getReactions(p.id, userId: userId));
        } catch (_) {
          return MapEntry(p.id, ReactionSummary.empty);
        }
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<ReactionSummary> toggleReaction(int postId, {required String userId, required ReactionType type}) async {
    final json = await _api.post('/api/posts/$postId/reactions/toggle', body: {'userId': userId, 'type': type.code});
    return ReactionSummary.fromJson(json as Map<String, dynamic>);
  }

  // ---- Comments ----

  /// Top-level comments (newest first), each with its replies.
  Future<List<PostComment>> getComments(int postId) async {
    final json = await _api.get('/api/posts/$postId/comments', query: const {'page': '0', 'size': '50'});
    final content = json is Map ? json['content'] : null;
    return (content as List? ?? const []).whereType<Map<String, dynamic>>().map(PostComment.fromJson).toList();
  }

  /// Only one level of replies is allowed by the service.
  Future<PostComment> addComment(int postId, {required String userId, required String content, int? parentId}) async {
    final json = await _api.post(
      '/api/posts/$postId/comments',
      body: {'userId': userId, 'content': content, 'parentCommentId': ?parentId},
    );
    return PostComment.fromJson(json as Map<String, dynamic>);
  }

  /// The service refuses (403) when [userId] is not the author.
  Future<void> deleteComment(int postId, int commentId, {required String userId}) =>
      _api.delete('/api/posts/$postId/comments/$commentId', query: {'userId': userId});

  static List<Post> _sorted(Object? json) =>
      (json as List).whereType<Map<String, dynamic>>().map(Post.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
