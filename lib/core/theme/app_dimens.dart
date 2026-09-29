import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale used across the app (multiples of 4).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double section = 40;

  /// Horizontal padding of every screen body.
  static const double gutter = 16;

  static const EdgeInsets screen = EdgeInsets.all(gutter);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Corner radii (styles.css `--border-radius` = 16px, `-lg` = 30px).
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 30;
  static const double organic = 50; // home collage `border-radius: 50px 0 50px 0`
  static const double round = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(pill));
}

/// Sizes (touch targets follow Material ≥ 48dp, which covers the 44pt HIG minimum).
abstract final class AppSizes {
  static const double minTouchTarget = 48;
  static const double buttonHeight = 50;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double icon = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  static const double avatarSm = 36;
  static const double avatar = 44;
  static const double avatarLg = 64;
  static const double avatarXl = 84;
  static const double logoHeight = 40;
  static const double mapHeight = 260;
  static const double mapHeightLg = 340;
  static const double maxContentWidth = 560;
  static const double chartHeight = 150;
  static const double thumbHeight = 120;
  static const double coverHeight = 140;
  static const double progressHeight = 8;
  static const double dot = 8;
  static const double borderWidth = 1;
  static const double accentWidth = 4;

  // Logos
  static const double logoSm = 34;
  static const double logoMd = 52;
  static const double logoLg = 56;

  // Layout widths
  static const double authMaxWidth = 450;
  static const double labelColumn = 110;
  static const double labelColumnWide = 130;
  static const double valueColumn = 44;
  static const double gridItemMaxWidth = 240;

  // Home page
  static const double heroBadge = 92;
  static const double collageHeight = 230;
  static const double collageAvatar = 96;
  static const double collageSubWidth = 150;
  static const double collageSubHeight = 100;
  static const double stepImageHeight = 170;

  // Media
  static const double coverSm = 96;
  static const double headerImageHeight = 180;
  static const double postImageHeight = 220;
  static const double uploadHeight = 100;
  static const double uploadHeightMd = 110;

  // Components
  static const double activityCardHeight = 270;
  static const double calendarDay = 28;
  static const double sosButtonHeight = 72;
  static const double gaugeWidth = 200;
  static const double gaugeHeight = 115;
  static const double quizSceneHeight = 140;
  static const double puzzleTray = 76;
  static const double puzzlePieceBase = 100;
  static const double stepConnector = 2;

  // Onboarding
  static const double onboardingMarkWidth = 128; // = native splash icon (splash_mark / launch_mark)
  static const double onboardingDot = 10;
}

/// Shadows (styles.css `--shadow-sm|md|lg`).
abstract final class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: AppColors.shadowSm, blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: AppColors.shadowMd, blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: AppColors.shadowLg, blurRadius: 30, offset: Offset(0, 12)),
  ];
}

/// Animation durations (styles.css `--transition-speed: .3s`).
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Onboarding sequence: mark → glides to the name → writes "FAKARNI" → "فكرني".
  static const Duration onboardingIntro = Duration(milliseconds: 2200);

  /// Pause on the final lockup before opening the app.
  static const Duration onboardingHold = Duration(milliseconds: 500);

  /// Short pause after the first frame so the engine is warm before animating.
  static const Duration onboardingStartDelay = Duration(milliseconds: 100);

  /// Upper bound when waiting for fonts/images (e.g. offline first launch).
  static const Duration onboardingMaxWait = Duration(milliseconds: 800);
}
