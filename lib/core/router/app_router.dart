import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/communication.dart';
import '../../models/educational.dart';
import '../../models/geofencing.dart';
import '../../models/medical.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../screens/alzheimer/alzheimer_screen.dart';
import '../../screens/alzheimer/reservation_form_screen.dart';
import '../../screens/alzheimer/virtual_meeting_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/auth/sign_in_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/communication/chat_screen.dart';
import '../../screens/communication/communication_screen.dart';
import '../../screens/communication/group_details_screen.dart';
import '../../screens/communication/group_form_screen.dart';
import '../../screens/educational/activity_play_screen.dart';
import '../../screens/educational/educational_screen.dart';
import '../../screens/geofencing/geofencing_screen.dart';
import '../../screens/geofencing/zone_form_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/medical/medical_screen.dart';
import '../../screens/medical/patient_dossier_screen.dart';
import '../../screens/posts/my_posts_screen.dart';
import '../../screens/posts/post_form_screen.dart';
import '../../screens/posts/posts_feed_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../widgets/common/state_views.dart';
import 'app_routes.dart';

/// Navigation of the app.
///
/// - The app opens on the animated onboarding screen.
/// - Auth pages are standalone (web: no header/footer) and public; every other
///   page requires a session (web `authGuard`), and a signed-in user skips the
///   sign-in / sign-up pages.
/// - The five main modules (home, alzheimer, posts, educational, communication)
///   live in a [StatefulShellRoute] (bottom navigation, each tab keeps its own
///   navigation stack).
/// - Forms, details, the meeting room and the secondary modules (geofencing,
///   medical, profile) are pushed full-screen on the root navigator.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static String? _tab(GoRouterState state) => state.uri.queryParameters['tab'];

  static const _publicRoutes = {
    AppRoutes.onboarding,
    AppRoutes.signIn,
    AppRoutes.signUp,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
  };

  static String? _guard(BuildContext context, GoRouterState state) {
    final signedIn = AuthProvider.instance.isAuthenticated;
    final location = state.matchedLocation;
    if (!signedIn && location != '/' && !_publicRoutes.contains(location)) return AppRoutes.signIn;
    if (signedIn && (location == AppRoutes.signIn || location == AppRoutes.signUp)) return AppRoutes.home;
    return null;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.onboarding,
    refreshListenable: AuthProvider.instance,
    redirect: _guard,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyStateView(
        icon: Icons.explore_off_outlined,
        title: 'Page introuvable',
        message: state.uri.toString(),
        actionLabel: 'Accueil',
        actionIcon: Icons.home_outlined,
        onAction: () => context.go(AppRoutes.home),
      ),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.onboarding),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) => ResetPasswordScreen(email: state.extra as String?),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.alzheimer,
              builder: (_, state) => AlzheimerScreen(initialTab: _tab(state)),
              routes: [
                GoRoute(
                  path: 'reservations/new',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) => ReservationFormScreen(initialDate: state.extra as DateTime?),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.posts,
              builder: (_, _) => const PostsFeedScreen(),
              routes: [
                GoRoute(path: 'create', parentNavigatorKey: _rootKey, builder: (_, _) => const PostFormScreen()),
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) => PostFormScreen(post: state.extra as Post?),
                ),
                GoRoute(path: 'my-posts', parentNavigatorKey: _rootKey, builder: (_, _) => const MyPostsScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.educational,
              builder: (_, state) => EducationalScreen(initialTab: _tab(state)),
              routes: [
                GoRoute(
                  path: 'activities/:id/play',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) => ActivityPlayScreen(
                    activityId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                    activity: state.extra as EducationalActivity?,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.communication,
              builder: (_, state) => CommunicationScreen(initialTab: _tab(state)),
              routes: [
                GoRoute(
                  path: 'chat/:contactId',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) {
                    final extra = state.extra;
                    return ChatScreen(
                      contactId: state.pathParameters['contactId']!,
                      contact: extra is Contact ? extra : null,
                      title: extra is String ? extra : null,
                    );
                  },
                ),
                GoRoute(path: 'groups/new', parentNavigatorKey: _rootKey, builder: (_, _) => const GroupFormScreen()),
                GoRoute(
                  path: 'groups/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) => GroupDetailsScreen(
                    groupId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                    group: state.extra as Group?,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootKey,
                      builder: (_, state) => GroupFormScreen(group: state.extra as Group?),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/meeting/:id',
        builder: (_, state) => VirtualMeetingScreen(
          sessionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          title: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.medical,
        builder: (_, state) => MedicalScreen(initialTab: _tab(state)),
        routes: [
          GoRoute(
            path: 'follow-up/:patientId',
            builder: (_, state) => PatientDossierScreen(
              patientId: state.pathParameters['patientId']!,
              patient: state.extra as FollowUpPatient?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.geofencing,
        builder: (_, state) => GeofencingScreen(
          initialTab: _tab(state),
          role: AuthProvider.instance.user?.role ?? UserRole.careOwner,
        ),
        routes: [
          GoRoute(path: 'zones/new', builder: (_, _) => const ZoneFormScreen()),
          GoRoute(path: 'zones/edit', builder: (_, state) => ZoneFormScreen(zone: state.extra as SafeZone?)),
        ],
      ),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => ProfileScreen(user: AuthProvider.instance.user)),
    ],
  );
}
