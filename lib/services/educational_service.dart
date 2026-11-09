import '../core/config/api_config.dart';
import '../core/config/api_endpoints.dart';
import '../models/educational.dart';
import '../providers/auth_provider.dart';
import 'api_client.dart';

/// Educational module API, through the gateway (web `ActivityService`,
/// `EducationalEventService` and `EngagementService`):
/// - activite-educative-service: `/api/activities/**`
/// - Event-Service: `/api/events/**`
/// - suivi-engagement-service: `/api/engagement/**`
class EducationalService {
  EducationalService({ApiClient? client, this._patientId}) : _api = client ?? ApiClient.instance;

  static final EducationalService instance = EducationalService();

  final ApiClient _api;
  final String? _patientId;

  /// Patient playing the games and whose progress is tracked: the signed-in
  /// user (web `authService.getCurrentUser().id`), else `PATIENT_ID`.
  String get patientId => _patientId ?? AuthProvider.instance.user?.id ?? ApiConfig.patientId;

  // ─── Activities ──────────────────────────────────────────────────────────

  /// Catalogue with the patient's latest score per activity. Inactive
  /// activities (disabled in the back-office) are hidden from patients.
  Future<List<EducationalActivity>> getActivities() async {
    final raw = await _api.get(ApiEndpoints.activities, query: {'patientId': patientId});
    return _maps(raw).map(EducationalActivity.fromJson).where((a) => a.active).toList();
  }

  Future<EducationalActivity> getActivity(int id) async {
    final raw = await _api.get(ApiEndpoints.activity(id), query: {'patientId': patientId});
    if (raw is! Map<String, dynamic>) throw const ApiException('Activité introuvable.');
    return EducationalActivity.fromJson(raw);
  }

  /// Image cards of a memory / puzzle activity (no session).
  Future<List<MemoryCardData>> getImageCards(int activityId) async {
    final raw = await _api.get(ApiEndpoints.activityImageCards(activityId));
    return _maps(raw).map(MemoryCardData.fromJson).toList();
  }

  // ─── Game sessions ───────────────────────────────────────────────────────

  Future<GameSession> startSession(int activityId) async {
    final raw = await _api.post(ApiEndpoints.activityStart(activityId), body: {'patientId': patientId});
    return GameSession.fromJson(_map(raw));
  }

  Future<AnswerFeedback> submitAnswer({
    required int activityId,
    required int sessionId,
    required int questionId,
    required String answer,
  }) async {
    final raw = await _api.post(
      ApiEndpoints.activitySubmitAnswer(activityId),
      body: {'sessionId': sessionId, 'questionId': questionId, 'answer': answer},
    );
    return AnswerFeedback.fromJson(_map(raw));
  }

  Future<GameResult> finishSession(int sessionId) async {
    final raw = await _api.post(ApiEndpoints.gameSessionFinish(sessionId));
    return GameResult.fromApi(_map(raw));
  }

  Future<MemoryMove> submitMemoryMove({required int sessionId, required int firstCardId, required int secondCardId}) async {
    final raw = await _api.post(
      ApiEndpoints.gameSessionMove(sessionId),
      body: {'firstCardId': firstCardId, 'secondCardId': secondCardId},
    );
    return MemoryMove.fromJson(_map(raw));
  }

  // ─── Events ──────────────────────────────────────────────────────────────

  Future<List<EducationalEvent>> getEvents() async {
    final raw = await _api.get(ApiEndpoints.events);
    final events = _maps(raw).map(EducationalEvent.fromJson).toList()
      ..sort((a, b) => (a.startDateTime ?? DateTime(9999)).compareTo(b.startDateTime ?? DateTime(9999)));
    return events;
  }

  // ─── Engagement ──────────────────────────────────────────────────────────

  Future<LearningProgress> getProgress() async {
    final raw = await _api.get(ApiEndpoints.patientEngagement(patientId));
    return LearningProgress.fromEngagement(_maps(raw).map(EngagementRow.fromJson).toList());
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>() : const [];

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    throw const ApiException('Réponse serveur invalide.');
  }
}
