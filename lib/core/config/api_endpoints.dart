
abstract final class ApiEndpoints {
  // ─── User-Service: authentication (gateway `/auth/**`) ───────────────────

  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ─── User-Service: users (gateway `/api/users/**`) ───────────────────────

  /// `POST`: sign-up (public).
  static const String users = '/api/users';
  static String user(String id) => '$users/$id';

  // ─── activite-educative-service (gateway `/api/activities/**`) ──────────

  static const String activities = '/api/activities';
  static String activity(int id) => '$activities/$id';
  static String activityImageCards(int activityId) => '$activities/$activityId/image-cards';
  static String activityStart(int activityId) => '$activities/$activityId/start';
  static String activitySubmitAnswer(int activityId) => '$activities/$activityId/submit-answer';

  static const String _gameSessions = '$activities/game-sessions';
  static String gameSessionFinish(int sessionId) => '$_gameSessions/$sessionId/finish';
  static String gameSessionMove(int sessionId) => '$_gameSessions/$sessionId/move';

  // ─── Event-Service (gateway `/api/events/**`) ───────────────────────────

  static const String events = '/api/events';

  // ─── suivi-engagement-service (gateway `/api/engagement/**`) ────────────

  static String patientEngagement(String patientId) => '/api/engagement/patients/${Uri.encodeComponent(patientId)}';

  // ─── session-service: sessions (gateway `/session/**`) ──────────────────

  static const String sessions = '/session/sessions';
  static String session(int id) => '$sessions/$id';
  static String sessionParticipants(int id) => '${session(id)}/participants';
  static String sessionMyPrefs(int id) => '${session(id)}/participants/me/prefs';
  static const String myFavoriteSessions = '/session/me/favorites';

  // ─── session-service: video rooms ───────────────────────────────────────

  static const String _videoSessions = '$sessions/video';
  static const String videoStart = '$_videoSessions/start';
  static const String videoJoin = '$_videoSessions/join';
  static String videoByVirtualSession(int sessionId) => '$_videoSessions/by-virtual-session/$sessionId';
  static String videoRoomMessages(String roomId) => '$_videoSessions/rooms/${Uri.encodeComponent(roomId)}/messages';
  static String videoRoomParticipants(String roomId) =>
      '$_videoSessions/rooms/${Uri.encodeComponent(roomId)}/participants';

  // ─── session-service: WebRTC signaling (SockJS + STOMP, gateway `/ws/**`) ─

  static const String signaling = '/ws';
  static String signalingRoomTopic(String roomId) => '/topic/room/$roomId';
  static String signalingDestination(String type) => '/app/signal/$type';

  // ─── meeting-insights-service (gateway `/api/meet/**`) ──────────────────

  static const String meetRecording = '/api/meet/recording';
  static const String meetReport = '/api/meet/report';
  static const String meetReports = '/api/meet/reports';
  static const String meetTranscriptions = '/api/meet/transcriptions';
}
