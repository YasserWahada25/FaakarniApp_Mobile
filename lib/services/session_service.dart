import '../core/config/api_endpoints.dart';
import '../models/meeting.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// session-service API, through the gateway (web `AlzheimerService`,
/// `SessionService` and the REST part of `VideoSessionService`).
class SessionService {
  SessionService({ApiClient? client, this._auth, String? Function()? currentUserId})
      : _api = client ?? ApiClient.instance,
        _currentUserId = currentUserId ?? (() => AuthProvider.instance.user?.id);

  static final SessionService instance = SessionService();

  final ApiClient _api;
  final AuthService? _auth;
  final String? Function() _currentUserId;
  final Map<String, String> _names = {};

  String? get currentUserId {
    final id = _currentUserId()?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  String _requireUserId() => currentUserId ?? (throw const ApiException('Utilisateur non authentifié.'));

  // ─── Sessions ────────────────────────────────────────────────────────────

  /// Sessions visible by the current user, by start date.
  Future<List<Session>> getSessions() async {
    final userId = currentUserId;
    return (await _fetchSessions()).where((s) => s.isVisibleTo(userId)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<List<Session>> _fetchSessions() async {
    final raw = await _api.get(ApiEndpoints.sessions);
    return _maps(raw).map(_session).toList();
  }

  Future<List<Session>> getFavorites() async {
    final userId = currentUserId;
    final raw = await _api.get(ApiEndpoints.myFavoriteSessions);
    return _maps(raw).map(_session).where((s) => s.isVisibleTo(userId)).map((s) => s.copyWith(isFavorite: true)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<Session> getSession(int id) async => _session(_map(await _api.get(ApiEndpoints.session(id))));

  /// Sends a request to the doctor, unless the slot is already taken (the check
  /// is client-side, like the web reservation form).
  Future<Session> createReservation(ReservationRequest request) async {
    final existing = await _fetchSessions();
    if (existing.any((s) => s.status.holdsTimeSlot && s.overlaps(request.start, request.end))) {
      throw const ApiException('Une session existe deja dans cette plage horaire.');
    }
    return _session(_map(await _api.post(ApiEndpoints.sessions, body: request.toJson())));
  }

  Future<void> setFavorite(int sessionId, bool favorite) async {
    await _api.patch(ApiEndpoints.sessionMyPrefs(sessionId), body: {'isFavorite': favorite});
  }

  // ─── Video rooms ─────────────────────────────────────────────────────────

  /// Joins the session's active room, opening it when there is none (web
  /// `SessionDetailComponent.joinMeeting`). Errors carry the message to show.
  Future<VideoRoom> openRoom(int sessionId) async {
    final userId = _requireUserId();
    final room = await _activeRoom(sessionId) ?? await _startRoom(sessionId, userId);
    try {
      await _api.post(ApiEndpoints.videoJoin, body: {'roomId': room.roomId, 'userId': userId});
      return room;
    } on ApiException catch (e) {
      throw switch (e.statusCode) {
        403 => ApiException("Vous n'êtes pas autorisé à rejoindre cette session.", statusCode: e.statusCode),
        409 => ApiException('La session est pleine.', statusCode: e.statusCode),
        _ => e,
      };
    }
  }

  Future<VideoRoom?> _activeRoom(int sessionId) async {
    try {
      return VideoRoom.fromJson(_map(await _api.get(ApiEndpoints.videoByVirtualSession(sessionId))));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      if (e.statusCode == 403) {
        throw ApiException("Vous n'êtes pas autorisé à rejoindre cette session.", statusCode: e.statusCode);
      }
      rethrow;
    }
  }

  Future<VideoRoom> _startRoom(int sessionId, String userId) async {
    try {
      return VideoRoom.fromJson(
        _map(await _api.post(ApiEndpoints.videoStart, body: {'virtualSessionId': sessionId, 'hostUserId': userId})),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw ApiException("Seul l'hôte peut démarrer la session. Attendez que l'hôte l'ouvre.", statusCode: e.statusCode);
      }
      if (e.statusCode == 409) {
        // Someone else opened the room in the meantime.
        final room = await _activeRoom(sessionId);
        if (room != null) return room;
      }
      rethrow;
    }
  }

  Future<List<MeetingChatMessage>> getRoomMessages(String roomId) async {
    final userId = _requireUserId();
    final raw = await _api.get(ApiEndpoints.videoRoomMessages(roomId));
    return _maps(raw).map((m) => MeetingChatMessage.fromJson(m, currentUserId: userId)).toList();
  }

  Future<List<MeetingParticipant>> getParticipants(int sessionId) async {
    final raw = await _api.get(ApiEndpoints.sessionParticipants(sessionId));
    return _maps(raw).map(MeetingParticipant.fromJson).toList();
  }

  /// Adds a user by id; doctors and admins become organizers (web
  /// `mapUserRoleToParticipantRole`). Returns the user's name and room role.
  Future<({String name, ParticipantRole role, List<MeetingParticipant> participants})> addParticipant({
    required String roomId,
    required String userId,
  }) async {
    final AppUser user;
    try {
      user = await (_auth ?? AuthService.instance).getUser(userId);
    } on ApiException {
      throw const ApiException('Utilisateur introuvable. Verifiez le userId saisi.');
    }
    final role = user.role == UserRole.doctor || user.role == UserRole.admin
        ? ParticipantRole.organizer
        : ParticipantRole.participant;
    final raw = await _api.post(
      ApiEndpoints.videoRoomParticipants(roomId),
      body: {
        'requesterUserId': _requireUserId(),
        'userId': userId,
        'role': role.backendValue,
        'joinStatus': 'CONFIRMED',
      },
    );
    return (
      name: user.fullName,
      role: role,
      participants: _maps(raw).map(MeetingParticipant.fromJson).toList(),
    );
  }

  /// "Prénom Nom" of a user, cached; a shortened id when it cannot be resolved.
  Future<String> displayName(String userId) async {
    final cached = _names[userId];
    if (cached != null) return cached;
    String name;
    try {
      final user = await (_auth ?? AuthService.instance).getUser(userId);
      name = user.fullName.trim();
      if (name.isEmpty) name = shortenUserId(userId);
    } on ApiException {
      name = shortenUserId(userId);
    }
    return _names[userId] = name;
  }

  static String shortenUserId(String userId) {
    if (userId.isEmpty) return 'Utilisateur';
    return userId.length <= 12 ? userId : '${userId.substring(0, 5)}...${userId.substring(userId.length - 4)}';
  }

  Session _session(Map<String, dynamic> json) => Session.fromJson(json, currentUserId: currentUserId);

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>() : const [];

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    throw const ApiException('Réponse serveur invalide.');
  }
}
