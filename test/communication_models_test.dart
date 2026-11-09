import 'package:fakarniapp/core/network/json_parsing.dart';
import 'package:fakarniapp/models/communication.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON shapes copied from the Spring services (group-service `GroupResponse`,
/// Chat_Service `MessageResponseDTO`).
void main() {
  group('parseApiDate', () {
    test('reads a zone-less LocalDateTime as UTC', () {
      final d = parseApiDate('2026-11-08T09:02:53.123456');
      expect(d.toUtc(), DateTime.utc(2026, 11, 8, 9, 2, 53, 123, 456));
    });

    test('keeps an explicit offset', () {
      expect(parseApiDate('2026-11-08T10:00:00+01:00').toUtc(), DateTime.utc(2026, 11, 8, 9));
    });

    test('reads the array form', () {
      expect(parseApiDate([2026, 11, 8, 9, 2, 53]).toUtc(), DateTime.utc(2026, 11, 8, 9, 2, 53));
    });
  });

  test('ChatMessage.fromJson', () {
    final m = ChatMessage.fromJson({
      'id': '6730f1',
      'senderId': 'u1',
      'receiverId': 'u2',
      'content': 'Bonjour 👋 é',
      'conversationId': 'u1_u2',
      'timestamp': '2026-11-08T09:00:00',
    });
    expect(m.content, 'Bonjour 👋 é');
    expect(m.isBetween('u2', 'u1'), isTrue);
    expect(m.isBetween('u1', 'u3'), isFalse);
  });

  group('Group.fromJson', () {
    final json = <String, dynamic>{
      'id': 7,
      'name': 'Aidants Tunis',
      'description': 'Entraide',
      'creatorId': 'admin1',
      'creator': {'id': 'admin1', 'nom': 'Ben Ali', 'prenom': 'Sami', 'email': 's@x.tn'},
      'groupType': 'PRIVATE',
      'status': 'ACTIVE',
      'coverImageUrl': '/uploads/groups/abc.png',
      'maxMembers': 2,
      'isJoinable': false,
      'memberCount': 2,
      'members': [
        {
          'id': 1,
          'userId': 'admin1',
          'user': {'id': 'admin1', 'nom': 'Ben Ali', 'prenom': 'Sami', 'email': 's@x.tn'},
          'role': 'ADMIN',
          'joinedAt': '2026-11-01T10:00:00',
        },
        {'id': 2, 'userId': 'abcdef123456', 'user': null, 'role': 'MODERATOR', 'joinedAt': '2026-11-02T10:00:00'},
      ],
      'createdAt': '2026-11-01T10:00:00',
      'updatedAt': '2026-11-01T10:00:00',
    };

    test('maps fields, roles and membership', () {
      final g = Group.fromJson(json);
      expect(g.groupType, GroupType.private);
      expect(g.status, GroupStatus.active);
      expect(g.isJoinable, isFalse);
      expect(g.isFull, isTrue);
      expect(g.roleOf('admin1'), MemberRole.admin);
      expect(g.members.first.displayName, 'Sami Ben Ali');
      // user-service unavailable → the service sends no user: fall back to the id.
      expect(g.members.last.displayName, 'Utilisateur 123456');
      expect(g.coverUrl, endsWith('/uploads/groups/abc.png'));
    });

    test('uses memberCount when members were not requested', () {
      final g = Group.fromJson({...json, 'members': null, 'memberCount': 5});
      expect(g.members, isEmpty);
      expect(g.memberCount, 5);
    });
  });

  test('GroupDraft.toJson matches GroupRequest', () {
    const draft = GroupDraft(name: 'G', description: 'D', groupType: GroupType.public, isJoinable: true);
    expect(draft.toJson(creatorId: 'me'), {
      'name': 'G',
      'description': 'D',
      'groupType': 'PUBLIC',
      'isJoinable': true,
      'maxMembers': null,
      'coverImageUrl': null,
      'creatorId': 'me',
    });
    expect(draft.toJson().containsKey('creatorId'), isFalse);
  });
}
