/// Route paths of the app. Module screens take an optional `?tab=` query
/// parameter selecting their sub-page (the web module sidebars).
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';

  // Auth (web: /auth/*)
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Bottom navigation branches
  static const String home = '/home';
  static const String alzheimer = '/alzheimer';
  static const String posts = '/posts';
  static const String educational = '/educational';
  static const String communication = '/communication';

  // Full-screen modules
  static const String geofencing = '/geofencing';
  static const String medical = '/medical';
  static const String profile = '/profile';

  // Alzheimer
  static const String reservationNew = '/alzheimer/reservations/new';
  static String meeting(int sessionId) => '/meeting/$sessionId';

  // Geofencing
  static const String zoneNew = '/geofencing/zones/new';
  static const String zoneEdit = '/geofencing/zones/edit';

  // Educational
  static String activityPlay(int activityId) => '/educational/activities/$activityId/play';

  // Communication
  static String chat(String contactId) => '/communication/chat/$contactId';
  static const String groupNew = '/communication/groups/new';
  static String group(int groupId) => '/communication/groups/$groupId';
  static String groupEdit(int groupId) => '/communication/groups/$groupId/edit';

  // Medical
  static String patientDossier(String patientId) => '/medical/follow-up/$patientId';

  // Posts
  static const String postCreate = '/posts/create';
  static String postEdit(int postId) => '/posts/edit/$postId';
  static const String myPosts = '/posts/my-posts';

  static String withTab(String route, String tab) => '$route?tab=$tab';
}

/// Sub-page keys of each module (used by `?tab=`).
abstract final class ModuleTabs {
  static const List<String> alzheimer = ['consultation', 'reservations', 'favorites', 'reports', 'notifications'];
  static const List<String> geofencing = ['tracking', 'alerts', 'supervision'];
  static const List<String> educational = ['activities', 'events', 'tracking'];
  static const List<String> communication = ['messaging', 'groups'];
  static const List<String> medical = ['records', 'detection', 'follow-up'];

  static int indexOf(List<String> tabs, String? key) {
    final i = key == null ? -1 : tabs.indexOf(key);
    return i < 0 ? 0 : i;
  }
}
