import '../core/network/json_parsing.dart';

/// Community posts models (web `posts/models`, Post-Service DTOs).
class PostAuthor {
  const PostAuthor({required this.id, required this.nom, required this.prenom});

  /// User-Service `UserDTO` embedded by Post-Service as `user`.
  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
    id: json['id']?.toString() ?? '',
    nom: stringOrNull(json['nom']) ?? '',
    prenom: stringOrNull(json['prenom']) ?? '',
  );

  final String id;
  final String nom;
  final String prenom;

  String get displayName => '$prenom $nom'.trim();
}

class Post {
  const Post({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.userId,
  });

  /// Post-Service `PostResponse`.
  factory Post.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return Post(
      id: (json['id'] as num).toInt(),
      content: json['content']?.toString() ?? '',
      imageUrl: stringOrNull(json['imageUrl']),
      userId: stringOrNull(json['userId']),
      author: user is Map<String, dynamic> && user['id'] != null ? PostAuthor.fromJson(user) : null,
      createdAt: parseApiDate(json['createdAt']),
      updatedAt: parseApiDate(json['updatedAt']),
    );
  }

  final int id;
  final String content;
  final PostAuthor? author;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Image as stored by the web app: a `data:image/...;base64,` URL (or a plain URL).
  final String? imageUrl;

  /// Author id (JWT `sub` at creation); kept even when User-Service is down.
  final String? userId;

  bool isOwnedBy(String? user) => user != null && userId == user;

  Post copyWith({String? content, String? imageUrl, bool clearImage = false, DateTime? updatedAt}) => Post(
    id: id,
    content: content ?? this.content,
    author: author,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
    userId: userId,
  );
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.parentId,
    this.replies = const [],
  });

  /// Post-Service `CommentResponse` (top-level comments carry their `replies`).
  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: (json['id'] as num).toInt(),
    postId: (json['postId'] as num?)?.toInt() ?? 0,
    userId: json['userId']?.toString() ?? '',
    authorName: fullNameOf(json['user']),
    content: json['content']?.toString() ?? '',
    createdAt: parseApiDate(json['createdAt']),
    parentId: (json['parentCommentId'] as num?)?.toInt(),
    replies: (json['replies'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PostComment.fromJson)
        .toList(),
  );

  final int id;
  final int postId;
  final String userId;

  /// "Prénom Nom" of the author, `null` when User-Service could not be reached.
  final String? authorName;
  final String content;
  final DateTime createdAt;
  final int? parentId;
  final List<PostComment> replies;

  String get displayName =>
      authorName ?? 'Utilisateur ${userId.length > 6 ? userId.substring(userId.length - 6) : userId}';

  PostComment copyWith({List<PostComment>? replies}) => PostComment(
    id: id,
    postId: postId,
    userId: userId,
    authorName: authorName,
    content: content,
    createdAt: createdAt,
    parentId: parentId,
    replies: replies ?? this.replies,
  );
}

enum ReactionType {
  like('LIKE', 'Like'),
  heart('HEART', 'Love'),
  support('SUPPORT', 'Support');

  const ReactionType(this.code, this.label);

  /// Value of the Post-Service `ReactionType` enum.
  final String code;
  final String label;

  static ReactionType? fromCode(Object? code) => values.where((t) => t.code == code).firstOrNull;
}

class ReactionSummary {
  const ReactionSummary({required this.counts, this.userReaction});

  /// Post-Service `ReactionCountResponse` (`{counts: {LIKE: 2, ...}, userReaction: "LIKE"}`).
  factory ReactionSummary.fromJson(Map<String, dynamic> json) {
    final counts = <ReactionType, int>{};
    final raw = json['counts'];
    if (raw is Map) {
      for (final type in ReactionType.values) {
        counts[type] = (raw[type.code] as num?)?.toInt() ?? 0;
      }
    }
    return ReactionSummary(counts: counts, userReaction: ReactionType.fromCode(json['userReaction']));
  }

  static const empty = ReactionSummary(counts: {});

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
