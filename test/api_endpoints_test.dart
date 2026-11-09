import 'package:fakarniapp/core/config/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes match the gateway / backend controllers', () {
    expect(ApiEndpoints.login, '/auth/login');
    expect(ApiEndpoints.refresh, '/auth/refresh');
    expect(ApiEndpoints.logout, '/auth/logout');
    expect(ApiEndpoints.forgotPassword, '/auth/forgot-password');
    expect(ApiEndpoints.resetPassword, '/auth/reset-password');
    expect(ApiEndpoints.users, '/api/users');
    expect(ApiEndpoints.user('u1'), '/api/users/u1');

    expect(ApiEndpoints.activities, '/api/activities');
    expect(ApiEndpoints.activity(3), '/api/activities/3');
    expect(ApiEndpoints.activityImageCards(3), '/api/activities/3/image-cards');
    expect(ApiEndpoints.activityStart(3), '/api/activities/3/start');
    expect(ApiEndpoints.activitySubmitAnswer(3), '/api/activities/3/submit-answer');
    expect(ApiEndpoints.gameSessionFinish(9), '/api/activities/game-sessions/9/finish');
    expect(ApiEndpoints.gameSessionMove(9), '/api/activities/game-sessions/9/move');

    expect(ApiEndpoints.events, '/api/events');
    expect(ApiEndpoints.patientEngagement('a b'), '/api/engagement/patients/a%20b');

    expect(ApiEndpoints.sessions, '/session/sessions');
    expect(ApiEndpoints.session(4), '/session/sessions/4');
    expect(ApiEndpoints.sessionParticipants(4), '/session/sessions/4/participants');
    expect(ApiEndpoints.sessionMyPrefs(4), '/session/sessions/4/participants/me/prefs');
    expect(ApiEndpoints.myFavoriteSessions, '/session/me/favorites');
    expect(ApiEndpoints.videoStart, '/session/sessions/video/start');
    expect(ApiEndpoints.videoJoin, '/session/sessions/video/join');
    expect(ApiEndpoints.videoByVirtualSession(4), '/session/sessions/video/by-virtual-session/4');
    expect(ApiEndpoints.videoRoomMessages('r 1'), '/session/sessions/video/rooms/r%201/messages');
    expect(ApiEndpoints.videoRoomParticipants('r1'), '/session/sessions/video/rooms/r1/participants');
    expect(ApiEndpoints.signaling, '/ws');
    expect(ApiEndpoints.signalingRoomTopic('r1'), '/topic/room/r1');
    expect(ApiEndpoints.signalingDestination('ice-candidate'), '/app/signal/ice-candidate');

    expect(ApiEndpoints.meetRecording, '/api/meet/recording');
    expect(ApiEndpoints.meetReport, '/api/meet/report');
    expect(ApiEndpoints.meetReports, '/api/meet/reports');
    expect(ApiEndpoints.meetTranscriptions, '/api/meet/transcriptions');
  });
}
