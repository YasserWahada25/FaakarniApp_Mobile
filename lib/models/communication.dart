/// Communication module models (messaging, feed, groups).
enum PresenceStatus {
  online('online'),
  away('away'),
  offline('offline');

  const PresenceStatus(this.label);
  final String label;
}

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final String role;
  final PresenceStatus status;
  final String? lastMessage;
  final int unreadCount;

  String get initials => name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
}

/// A post of the "Feed" tab of Messaging & Feed.
class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.date,
    required this.title,
    required this.content,
    this.likes = 0,
    this.liked = false,
  });

  final int id;
  final String author;
  final DateTime date;
  final String title;
  final String content;
  final int likes;
  final bool liked;

  FeedPost toggleLike() => FeedPost(
        id: id,
        author: author,
        date: date,
        title: title,
        content: content,
        likes: liked ? likes - 1 : likes + 1,
        liked: !liked,
      );
}

enum GroupType {
  public('PUBLIC', 'Public'),
  private('PRIVATE', 'Privé');

  const GroupType(this.code, this.label);
  final String code;
  final String label;
}

enum GroupStatus { active, archived, suspended }

enum MemberRole {
  admin('ADMIN'),
  moderator('MODERATOR'),
  member('MEMBER');

  const MemberRole(this.code);
  final String code;
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
  });

  final String userId;
  final String displayName;
  final MemberRole role;
  final DateTime joinedAt;
  final String? invitedBy;

  GroupMember withRole(MemberRole newRole) =>
      GroupMember(userId: userId, displayName: displayName, role: newRole, joinedAt: joinedAt, invitedBy: invitedBy);
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.groupType,
    required this.status,
    required this.isJoinable,
    required this.members,
    required this.createdAt,
    required this.coverIndex,
    this.maxMembers,
  });

  final int id;
  final String name;
  final String description;
  final String creatorId;
  final GroupType groupType;
  final GroupStatus status;
  final bool isJoinable;
  final int? maxMembers;
  final List<GroupMember> members;
  final DateTime createdAt;

  /// Index into the cover gradient palette; `-1` means "no image".
  final int coverIndex;

  int get memberCount => members.length;
  bool get isFull => maxMembers != null && memberCount >= maxMembers!;
  bool hasMember(String userId) => members.any((m) => m.userId == userId);
  MemberRole? roleOf(String userId) {
    for (final m in members) {
      if (m.userId == userId) return m.role;
    }
    return null;
  }

  Group copyWith({
    String? name,
    String? description,
    GroupType? groupType,
    bool? isJoinable,
    int? maxMembers,
    bool clearMaxMembers = false,
    List<GroupMember>? members,
    int? coverIndex,
  }) =>
      Group(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        creatorId: creatorId,
        groupType: groupType ?? this.groupType,
        status: status,
        isJoinable: isJoinable ?? this.isJoinable,
        maxMembers: clearMaxMembers ? null : (maxMembers ?? this.maxMembers),
        members: members ?? this.members,
        createdAt: createdAt,
        coverIndex: coverIndex ?? this.coverIndex,
      );
}

/// Data submitted by the create/edit group form.
class GroupDraft {
  const GroupDraft({
    required this.name,
    required this.description,
    required this.groupType,
    required this.isJoinable,
    this.maxMembers,
    this.coverIndex = -1,
  });

  final String name;
  final String description;
  final GroupType groupType;
  final bool isJoinable;
  final int? maxMembers;
  final int coverIndex;
}
