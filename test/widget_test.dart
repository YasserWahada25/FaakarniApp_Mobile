import 'package:fakarniapp/core/constants/app_constants.dart';
import 'package:fakarniapp/core/router/app_router.dart';
import 'package:fakarniapp/core/router/app_routes.dart';
import 'package:fakarniapp/core/utils/clinical_scoring.dart';
import 'package:fakarniapp/core/utils/validators.dart';
import 'package:fakarniapp/main.dart';
import 'package:fakarniapp/providers/auth_provider.dart';
import 'package:fakarniapp/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_session.dart';

/// Pumps frames for [seconds] without waiting for infinite animations
/// (shimmers) to settle.
Future<void> _settle(WidgetTester tester, [int seconds = 2]) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting();
  });

  group('Validators (ported from the web forms)', () {
    test('email', () {
      expect(Validators.email('aidant@fakarni.tn'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('strong password: uppercase, digit, special char', () {
      expect(Validators.strongPassword('Fakarni1!'), isNull);
      expect(Validators.strongPassword('fakarni'), isNotNull);
    });

    test('phone: exactly 8 digits', () {
      expect(Validators.phone('12345678'), isNull);
      expect(Validators.phone('1234'), isNotNull);
    });
  });

  group('Clinical scoring (web NeuroScan formulas)', () {
    test('age risk bands', () {
      expect(ClinicalScoring.ageRisk(55), 2);
      expect(ClinicalScoring.ageRisk(72), 13);
      expect(ClinicalScoring.ageRisk(92), 60);
    });

    test('questionnaire score', () {
      final score = ClinicalScoring.questionnaireScore(
        symptoms: {'memoire', 'confusion'},
        antecedents: {'familiaux'},
        duration: 'gt12',
      );
      expect(score, 4.0);
      expect(ClinicalScoring.questionnaireBand(score), RiskBand.moderate);
    });
  });

  testWidgets('signed out: app pages redirect to sign-in, which validates the form', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FakarniApp());
    AppRouter.router.go(AppRoutes.educational);
    await _settle(tester);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.tap(find.text('SIGN IN'));
    await _settle(tester, 1);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('signed in: navigate through the bottom bar and the drawer, then log out', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(() => AuthProvider.instance.debugSetSession(null));

    await tester.pumpWidget(const FakarniApp());
    AppRouter.router.go(AppRoutes.signIn);
    await _settle(tester);
    AuthProvider.instance.debugSetSession(testSession);
    await _settle(tester);

    // A signed-in user skips the sign-in page and lands on Home: the
    // Community Posts feed.
    expect(find.text('Community Posts'), findsWidgets);
    expect(find.text('Create Post'), findsOneWidget);

    // Bottom navigation
    await tester.tap(find.text('Alzheimer').last);
    await _settle(tester);
    expect(find.text('Alzheimer Care'), findsOneWidget);
    expect(find.text('Filtrer le calendrier'), findsOneWidget);

    await tester.tap(find.text('Geofencing').last);
    await _settle(tester);
    expect(find.text('Configured Zones'), findsOneWidget);

    await tester.tap(find.text('Education').last);
    await _settle(tester);
    expect(find.text('Jeux & activités'), findsOneWidget);
    // The catalogue comes from the API (unreachable in tests): no crash.

    await tester.tap(find.text('Messages').last);
    await _settle(tester);
    expect(find.text('Communication'), findsOneWidget);

    // Drawer → a sub-page of another module (web navbar dropdown).
    await tester.tap(find.byTooltip('Menu'));
    await _settle(tester, 1);
    await tester.tap(find.text('ALZHEIMER'));
    await _settle(tester, 1);
    await tester.tap(find.text('Favorites').last);
    await _settle(tester);
    // The favorites come from the API (unreachable in tests): only the page is checked.
    expect(find.text('My Favorite Sessions'), findsOneWidget);

    // Drawer → Community Posts goes back to Home, in the bottom bar.
    await tester.tap(find.byTooltip('Menu'));
    await _settle(tester, 1);
    await tester.tap(find.text('POSTS'));
    await _settle(tester, 1);
    await tester.tap(find.text('Community Posts').last);
    await _settle(tester);
    expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
    expect(find.text('Create Post'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Logout (drawer): back to the sign-in page.
    await tester.tap(find.byTooltip('Menu'));
    await _settle(tester, 1);
    expect(find.text('Sami Ben Ali'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Logout'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Logout'));
    await _settle(tester);
    expect(AuthProvider.instance.isAuthenticated, isFalse);
    expect(find.text('Sign In'), findsOneWidget);
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Before the first build: no transition from the previous test's page.
    AppRouter.router.go(AppRoutes.onboarding);
    await tester.pumpWidget(const FakarniApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // let go_router build the page
  }

  final mark = find.byWidgetPredicate(
    (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == AppConstants.logoMarkAsset,
  );

  double markOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.ancestor(of: mark, matching: find.byType(Opacity)).first).opacity;

  testWidgets('onboarding: the mark writes the name, then the sign-in page opens', (tester) async {
    await pumpOnboarding(tester);

    // Start (fonts/images warming up): the mark is centered and fully visible,
    // like the native splash, and the name is not revealed yet.
    expect(markOpacity(tester), 1);
    expect(find.text('FAKARNI'), findsOneWidget);
    expect(find.text('فكرني'), findsOneWidget);

    // Warm-up (≤ 0.8 s + 0.1 s) then most of the 2.2 s intro: the mark has
    // dissolved into the name.
    await _settle(tester, 4);
    expect(markOpacity(tester), 0);

    // End of the intro + 0.5 s hold → sign-in page, without any tap.
    await _settle(tester, 3);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('onboarding: a tap skips the intro', (tester) async {
    await pumpOnboarding(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(OnboardingScreen));
    await _settle(tester);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
