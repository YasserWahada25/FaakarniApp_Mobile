import '../core/network/api_client.dart';
import '../core/network/json_parsing.dart';
import '../models/user.dart';

/// A user as listed by user-service (enough to show and contact them).
class DirectoryUser {
  const DirectoryUser({required this.id, required this.name, required this.role});

  factory DirectoryUser.fromJson(Map<String, dynamic> json) => DirectoryUser(
    id: json['id'].toString(),
    name: fullNameOf(json) ?? 'Utilisateur',
    role: json['role']?.toString() ?? '',
  );

  final String id;
  final String name;

  /// Backend role code (`PATIENT_PROFILE`, `DOCTOR_PROFILE`, `CARE_OWNER`, `ADMIN`).
  final String role;

  String get roleLabel =>
      UserRole.values.where((r) => r.backendValue == role).firstOrNull?.label ??
      (role == 'ADMIN' ? 'Administrateur' : role);
}

/// Read-only access to user-service. `GET /api/users` is reserved to admins,
/// so the list is built from the public `/api/users/by-role/{role}`.
class UserDirectoryService {
  UserDirectoryService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  static final UserDirectoryService instance = UserDirectoryService();

  final ApiClient _api;

  Future<List<DirectoryUser>> byRole(UserRole role) async {
    final json = await _api.get('/api/users/by-role/${role.backendValue}');
    return (json as List).whereType<Map<String, dynamic>>().map(DirectoryUser.fromJson).toList();
  }

  /// Every patient, doctor and caregiver, sorted by name.
  Future<List<DirectoryUser>> everyone() async {
    final lists = await Future.wait(UserRole.values.map(byRole));
    return lists.expand((l) => l).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
