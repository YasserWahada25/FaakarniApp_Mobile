import '../core/network/api_config.dart';
import '../core/network/json_parsing.dart';

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
    this.status,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final String role;

  /// `null` when unknown: the backend does not track presence.
  final PresenceStatus? status;
  final String? lastMessage;
  final int unreadCount;

  String get initials => name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();
}

/// Chat_Service `MessageResponseDTO`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'].toString(),
    senderId: json['senderId'].toString(),
    receiverId: json['receiverId'].toString(),
    content: json['content']?.toString() ?? '',
    timestamp: parseApiDate(json['timestamp']),
  );

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;

  /// Whether this message belongs to the conversation between [a] and [b].
  bool isBetween(String a, String b) => (senderId == a && receiverId == b) || (senderId == b && receiverId == a);
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

  static GroupType fromCode(Object? code) => values.where((t) => t.code == code).firstOrNull ?? GroupType.public;
}

enum GroupStatus {
  active,
  archived,
  suspended;

  static GroupStatus fromCode(Object? code) =>
      values.where((s) => s.name.toUpperCase() == code).firstOrNull ?? GroupStatus.active;
}

enum MemberRole {
  admin('ADMIN'),
  moderator('MODERATOR'),
  member('MEMBER');

  const MemberRole(this.code);
  final String code;

  static MemberRole fromCode(Object? code) => values.where((r) => r.code == code).firstOrNull ?? MemberRole.member;
}

/// group-service `GroupMemberResponse` (the service embeds the user-service
/// `UserDTO` as `user`).
class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'].toString();
    return GroupMember(
      userId: userId,
      displayName:
          fullNameOf(json['user']) ?? 'Utilisateur ${userId.length > 6 ? userId.substring(userId.length - 6) : userId}',
      role: MemberRole.fromCode(json['role']),
      joinedAt: parseApiDate(json['joinedAt']),
      invitedBy: stringOrNull(json['invitedBy']),
    );
  }

  final String userId;
  final String displayName;
  final MemberRole role;
  final DateTime joinedAt;
  final String? invitedBy;

  GroupMember withRole(MemberRole newRole) =>
      GroupMember(userId: userId, displayName: displayName, role: newRole, joinedAt: joinedAt, invitedBy: invitedBy);
}

/// group-service `GroupResponse`.
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
    this.coverImageUrl,
    this.reportedMemberCount,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GroupMember.fromJson)
        .toList();
    final cover = stringOrNull(json['coverImageUrl']);
    return Group(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      creatorId: json['creatorId']?.toString() ?? '',
      groupType: GroupType.fromCode(json['groupType']),
      status: GroupStatus.fromCode(json['status']),
      isJoinable: json['isJoinable'] as bool? ?? true,
      maxMembers: (json['maxMembers'] as num?)?.toInt(),
      members: members,
      createdAt: parseApiDate(json['createdAt']),
      coverImageUrl: cover,
      // Same placeholder as the web ("Pas d'image") when no cover was uploaded.
      coverIndex: -1,
      reportedMemberCount: (json['memberCount'] as num?)?.toInt(),
    );
  }

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

  /// Uploaded cover, as returned by the API (`/uploads/groups/…`).
  final String? coverImageUrl;

  /// `memberCount` of the API, used when [members] were not requested.
  final int? reportedMemberCount;

  /// Absolute URL of [coverImageUrl].
  String? get coverUrl => ApiConfig.mediaUrl(coverImageUrl);

  int get memberCount => members.isNotEmpty ? members.length : (reportedMemberCount ?? 0);
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
    String? coverImageUrl,
  }) => Group(
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
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    reportedMemberCount: reportedMemberCount,
  );
}

/// Data submitted by the create/edit group form (group-service `GroupRequest`).
class GroupDraft {
  const GroupDraft({
    required this.name,
    required this.description,
    required this.groupType,
    required this.isJoinable,
    this.maxMembers,
    this.coverIndex = -1,
    this.coverImageUrl,
  });

  final String name;
  final String description;
  final GroupType groupType;
  final bool isJoinable;
  final int? maxMembers;
  final int coverIndex;
  final String? coverImageUrl;

  /// The service takes the creator from the JWT; `creatorId` is sent like the web does.
  Map<String, dynamic> toJson({String? creatorId}) => {
    'name': name,
    'description': description,
    'groupType': groupType.code,
    'isJoinable': isJoinable,
    'maxMembers': maxMembers,
    'coverImageUrl': coverImageUrl,
    'creatorId': ?creatorId,
  };
}
