/// Community posts models (web `posts/models`).
class PostAuthor {
  const PostAuthor({required this.id, required this.nom, required this.prenom});

  final String id;
  final String nom;
  final String prenom;

  String get displayName => '$prenom $nom';
}

class Post {
  const Post({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  final int id;
  final String content;
  final PostAuthor? author;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? imageUrl;

  Post copyWith({String? content, String? imageUrl, bool clearImage = false, DateTime? updatedAt}) => Post(
        id: id,
        content: content ?? this.content,
        author: author,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      );
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.replies = const [],
  });

  final int id;
  final int postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final int? parentId;
  final List<PostComment> replies;

  PostComment copyWith({List<PostComment>? replies}) => PostComment(
        id: id,
        postId: postId,
        userId: userId,
        content: content,
        createdAt: createdAt,
        parentId: parentId,
        replies: replies ?? this.replies,
      );
}

enum ReactionType {
  like('Like'),
  heart('Love'),
  support('Support');

  const ReactionType(this.label);
  final String label;
}

class ReactionSummary {
  const ReactionSummary({required this.counts, this.userReaction});

  final Map<ReactionType, int> counts;
  final ReactionType? userReaction;

  int count(ReactionType t) => counts[t] ?? 0;

  /// Same toggle rules as the backend: tapping the active reaction removes
  /// it, tapping another one switches to it.
  ReactionSummary toggle(ReactionType t) {
    final next = Map<ReactionType, int>.from(counts);
    if (userReaction == t) {
      next[t] = count(t) - 1;
      return ReactionSummary(counts: next);
    }
    if (userReaction != null) next[userReaction!] = count(userReaction!) - 1;
    next[t] = count(t) + 1;
    return ReactionSummary(counts: next, userReaction: t);
  }
}
