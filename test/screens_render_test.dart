import 'package:fakarniapp/core/router/app_router.dart';
import 'package:fakarniapp/core/theme/app_theme.dart';
import 'package:fakarniapp/main.dart';
import 'package:fakarniapp/models/user.dart';
import 'package:fakarniapp/screens/geofencing/geofencing_screen.dart';
import 'package:fakarniapp/screens/medical/medical_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _settle(WidgetTester tester, [int steps = 10]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Small Android phone: 360 × 740 dp.
void _smallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting();
  });

  const locations = [
    '/onboarding',
    '/signin',
    '/signup',
    '/forgot-password',
    '/reset-password',
    '/home',
    '/alzheimer?tab=consultation',
    '/alzheimer?tab=reservations',
    '/alzheimer?tab=favorites',
    '/alzheimer?tab=reports',
    '/alzheimer?tab=notifications',
    '/alzheimer/reservations/new',
    '/meeting/1',
    '/geofencing?tab=tracking',
    '/geofencing?tab=alerts',
    '/geofencing?tab=supervision',
    '/geofencing/zones/new',
    '/educational?tab=activities',
    '/educational?tab=events',
    '/educational?tab=tracking',
    '/educational/activities/1/play',
    '/communication?tab=messaging',
    '/communication?tab=groups',
    '/communication/chat/support',
    '/communication/groups/new',
    '/communication/groups/1',
    '/medical?tab=records',
    '/medical?tab=detection',
    '/medical?tab=follow-up',
    '/medical/follow-up/p1',
    '/posts',
    '/posts/create',
    '/posts/my-posts',
    '/posts/edit/1',
    '/profile',
  ];

  testWidgets('every route renders on a small phone', (tester) async {
    _smallPhone(tester);
    await tester.pumpWidget(const FakarniApp());
    await _settle(tester);

    final failures = <String>[];
    for (final location in locations) {
      AppRouter.router.go(location);
      await _settle(tester);
      final error = tester.takeException();
      if (error != null) failures.add('$location → ${error is FlutterError ? error.toStringDeep() : error}');
      if (find.byType(Scaffold).evaluate().isEmpty) failures.add('$location → no Scaffold');
    }
    expect(failures, isEmpty);
  });

  testWidgets('geofencing patient views render', (tester) async {
    _smallPhone(tester);
    Future<void> pumpTab(int index) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GeofencingScreen(role: UserRole.patient, initialTab: const ['tracking', 'alerts', 'supervision'][index]),
        ),
      ));
      await _settle(tester);
    }

    await pumpTab(0);
    expect(find.text('My Location'), findsOneWidget);
    final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(find.text('SOS'), 200, scrollable: vertical.first);
    expect(find.text('SOS'), findsOneWidget);
    await pumpTab(1);
    expect(find.text('Informations'), findsOneWidget);
    await pumpTab(2);
    expect(find.text('Mon Espace Santé'), findsOneWidget);
  });

  testWidgets('NeuroScan wizard computes the risk index and walks through its steps', (tester) async {
    _smallPhone(tester);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: MedicalScreen(initialTab: 'detection')),
    ));
    await _settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ahmed Fares');
    await tester.enterText(find.byType(TextFormField).at(2), '72');
    await _settle(tester, 3);
    expect(find.text('Indice de risque global'), findsOneWidget);
    expect(find.text('13'), findsOneWidget); // age risk for 72 years

    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await _settle(tester, 3);
      await tester.tap(finder);
      await _settle(tester);
    }

    await tapVisible(find.text('Suivant — Questionnaire'));
    await tapVisible(find.text('Troubles de la mémoire'));
    expect(find.text('Profil rassurant'), findsOneWidget);

    await tapVisible(find.text('Suivant — Imagerie IRM'));
    await tester.ensureVisible(find.text('Aucune image IRM chargée'));
    expect(find.text('Aucune image IRM chargée'), findsOneWidget);
  });
}
