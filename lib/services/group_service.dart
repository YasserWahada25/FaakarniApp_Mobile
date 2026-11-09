import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/communication.dart';

/// group-service, through the gateway (`/api/groups/**`, `/api/upload/**`).
///
/// [revision] changes after every write, so screens showing groups (list,
/// details) can reload when another screen created, edited or left a group.
class GroupService {
  GroupService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  static final GroupService instance = GroupService();

  final ApiClient _api;
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// Members are included: the list needs them to know which groups the user belongs to.
  Future<List<Group>> getAll() async {
    final json = await _api.get('/api/groups', query: const {'includeMembers': 'true'});
    return (json as List).whereType<Map<String, dynamic>>().map(Group.fromJson).toList();
  }

  Future<Group> getById(int id) async => Group.fromJson(
    await _api.get('/api/groups/$id', query: const {'includeMembers': 'true'}) as Map<String, dynamic>,
  );

  /// Needs a signed-in user: the service takes the creator (made ADMIN) from the JWT.
  Future<Group> create(GroupDraft draft, {required String creatorId}) async {
    final json = await _api.post('/api/groups', body: draft.toJson(creatorId: creatorId));
    _changed();
    return Group.fromJson(json as Map<String, dynamic>);
  }

  Future<Group> update(int id, GroupDraft draft) async {
    final json = await _api.put('/api/groups/$id', body: draft.toJson());
    _changed();
    return Group.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/groups/$id');
    _changed();
  }

  Future<void> join(int groupId, String userId) async {
    try {
      await _api.post('/api/groups/$groupId/members', body: {'userId': userId, 'role': MemberRole.member.code});
    } on ApiException catch (e) {
      // The service answers 500 for "already a member" / "group full".
      if ((e.statusCode ?? 0) >= 500) {
        throw const ApiException('Impossible de rejoindre ce groupe (complet ou déjà membre).');
      }
      rethrow;
    }
    _changed();
  }

  /// Also used to leave a group (with the signed-in user's id).
  Future<void> removeMember(int groupId, String userId) async {
    await _api.delete('/api/groups/$groupId/members/$userId');
    _changed();
  }

  Future<void> setRole(int groupId, String userId, MemberRole role) async {
    await _api.patch('/api/groups/$groupId/members/$userId/role', body: {'role': role.code});
    _changed();
  }

  /// Uploads a cover image and returns its path (`/uploads/groups/…`).
  Future<String> uploadCover(List<int> bytes, String filename) async {
    final json = await _api.upload('/api/upload/image', field: 'file', bytes: bytes, filename: filename);
    final url = json is Map ? json['url'] : null;
    if (url is! String || url.isEmpty) throw const ApiException("L'image n'a pas pu être envoyée.");
    return url;
  }

  void _changed() => revision.value++;
}
