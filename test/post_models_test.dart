import 'package:fakarniapp/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON shapes of Post-Service (`PostResponse`, `CommentResponse` page,
/// `ReactionCountResponse`).
void main() {
  test('Post.fromJson with author and inline image', () {
    final post = Post.fromJson({
      'id': 3,
      'content': 'Bonjour à toute la communauté',
      'imageUrl': 'data:image/png;base64,iVBORw0KGgo=',
      'userId': '6af03c5566019019914eaaa2',
      'user': {'id': '6af03c5566019019914eaaa2', 'nom': 'Yasser', 'prenom': 'Wahada', 'email': 'w@x.tn'},
      'createdAt': '2026-11-08T10:00:00',
      'updatedAt': '2026-11-08T10:00:00',
    });
    expect(post.author?.displayName, 'Wahada Yasser');
    expect(post.isOwnedBy('6af03c5566019019914eaaa2'), isTrue);
    expect(post.isOwnedBy('someone-else'), isFalse);
    expect(post.isOwnedBy(null), isFalse);
    expect(post.imageUrl, startsWith('data:image/png'));
  });

  test('Post.fromJson keeps the owner when User-Service is down', () {
    final post = Post.fromJson({
      'id': 4,
      'content': 'Sans auteur résolu',
      'userId': 'abc',
      'user': null,
      'createdAt': '2026-11-08T10:00:00',
      'updatedAt': '2026-11-08T10:00:00',
    });
    expect(post.author, isNull);
    expect(post.isOwnedBy('abc'), isTrue);
  });

  test('PostComment.fromJson with replies and author name', () {
    final c = PostComment.fromJson({
      'id': 10,
      'postId': 3,
      'userId': 'u1',
      'user': {'id': 'u1', 'nom': 'Saidi', 'prenom': 'Balkis'},
      'content': 'Merci !',
      'parentCommentId': null,
      'createdAt': '2026-11-08T10:05:00',
      'replies': [
        {'id': 11, 'postId': 3, 'userId': 'u2', 'user': null, 'content': 'Avec plaisir', 'parentCommentId': 10, 'createdAt': '2026-11-08T10:06:00'},
      ],
    });
    expect(c.displayName, 'Balkis Saidi');
    expect(c.replies.single.parentId, 10);
    expect(c.replies.single.displayName, 'Utilisateur u2');
  });

  test('ReactionSummary.fromJson and toggle', () {
    final r = ReactionSummary.fromJson({
      'counts': {'LIKE': 2, 'HEART': 0, 'SUPPORT': 1},
      'userReaction': 'LIKE',
    });
    expect(r.count(ReactionType.like), 2);
    expect(r.userReaction, ReactionType.like);

    final switched = r.toggle(ReactionType.support);
    expect(switched.count(ReactionType.like), 1);
    expect(switched.count(ReactionType.support), 2);
    expect(switched.userReaction, ReactionType.support);

    final removed = switched.toggle(ReactionType.support);
    expect(removed.userReaction, isNull);
    expect(removed.count(ReactionType.support), 1);
  });
}
