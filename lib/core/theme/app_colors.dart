import 'package:flutter/material.dart';

/// Every color used by the app. Values are copied from the web front-end
/// (`frontend/src/styles.css` `:root` tokens and the per-module stylesheets)
/// so the mobile app keeps strict visual parity with the web app.
///
/// Widgets must never declare a color literal: they read from here or from
/// `Theme.of(context)`.
abstract final class AppColors {
  // ── Brand: pastel violet palette (styles.css :root) ──────────────────────
  static const Color primary = Color(0xFFA084DC); // --primary-color
  static const Color primarySoft = Color(0xFFBFA2DB); // --primary-soft
  static const Color primaryLight = Color(0xFFCDB4DB); // --primary-light
  static const Color primaryDark = Color(0xFF6A4C93); // --primary-dark
  static const Color primaryHover = Color(0xFF8F6ED5); // --primary-hover
  static const Color secondaryButton = Color(0xFFE5D4F5); // .btn-secondary
  static const Color brandDeep = Color(0xFF5C3486); // logo.png background
  static const Color glowWhite = Color(0x99FFFFFF); // white @ 60 % (onboarding reveal dot)

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bgMain = Color(0xFFF3ECFB); // --bg-main
  static const Color bgSecondary = Color(0xFFEDE7F6); // --bg-secondary
  static const Color bgCard = Color(0xFFFFFFFF); // --bg-card
  static const Color bgPage = Color(0xFFF8F9FA); // module layouts background
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Functional ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF6BCB77); // --success-color
  static const Color warning = Color(0xFFFFD166); // --warning-color
  static const Color error = Color(0xFFEF476F); // --error-color
  static const Color info = Color(0xFF7B9ACC); // --info-color

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textMain = Color(0xFF2E2E2E); // --text-main
  static const Color textSecondary = Color(0xFF6D6D6D); // --text-secondary
  static const Color textMuted = Color(0xFF95A5A6);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color heading = Color(0xFF6A4C93); // --heading-color
  static const Color textInk = Color(0xFF2C2C54); // dark ink used in cards

  // ── Neutral lines ────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderViolet = Color(0xFFEBE9F7);

  // ── Feedback banners (auth pages) ────────────────────────────────────────
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color errorText = Color(0xFFC62828);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);

  // ── Social sign-in ───────────────────────────────────────────────────────
  static const Color facebook = Color(0xFF4267B2);
  static const Color googleText = Color(0xFF3C4043);

  // ── Shadows (rgba(160,132,220,x) in styles.css) ──────────────────────────
  static const Color shadowSm = Color(0x1AA084DC); // 10 %
  static const Color shadowMd = Color(0x26A084DC); // 15 %
  static const Color shadowLg = Color(0x40A084DC); // 25 %
  static const Color focusRing = Color(0x1AA084DC);
  static const Color scrim = Color(0x8C0D1B3E); // rgba(13,27,62,.55)
}

/// Module accent colors (the web gives each module sidebar its own accent).
abstract final class ModuleColors {
  static const Color alzheimer = Color(0xFF5C6BC0);
  static const Color alzheimerDeep = Color(0xFF3F51B5);
  static const Color alzheimerViolet = Color(0xFF7C4DFF);
  static const Color alzheimerActiveBg = Color(0xFFE8EAF6);

  static const Color medical = Color(0xFF7B1FA2);
  static const Color medicalActiveBg = Color(0xFFF3E5F5);

  static const Color geofencing = AppColors.primary;
  static const Color educational = AppColors.primary;
  static const Color communication = AppColors.primary;
  static const Color moduleActiveBg = Color(0xFFF0F7FF);
  static const Color online = Color(0xFF27AE60);
}

/// Alzheimer sessions: session type chips, status chips, stat cards.
abstract final class SessionColors {
  // Type chips — calendar.component.css
  static const Color therapyBg = Color(0xFFF3E5F5);
  static const Color therapyBg2 = Color(0xFFEDE7F6);
  static const Color therapyFg = Color(0xFF7B1FA2);
  static const Color therapyAccent = Color(0xFF9C27B0);

  static const Color cognitiveBg = Color(0xFFE3F2FD);
  static const Color cognitiveBg2 = Color(0xFFE8EAF6);
  static const Color cognitiveFg = Color(0xFF1565C0);
  static const Color cognitiveAccent = Color(0xFF1976D2);

  static const Color physicalBg = Color(0xFFE8F5E9);
  static const Color physicalBg2 = Color(0xFFF1F8E9);
  static const Color physicalFg = Color(0xFF2E7D32);
  static const Color physicalAccent = Color(0xFF43A047);

  static const Color creativeBg = Color(0xFFFFF3E0);
  static const Color creativeBg2 = Color(0xFFFFF8E1);
  static const Color creativeFg = Color(0xFFE65100);
  static const Color creativeAccent = Color(0xFFEF6C00);

  static const Color generalBg = Color(0xFFECEFF1);
  static const Color generalBg2 = Color(0xFFF5F5F5);
  static const Color generalFg = Color(0xFF455A64);
  static const Color generalAccent = Color(0xFF607D8B);

  // Status chips (consultation calendar)
  static const Color plannedBg = Color(0xFFEBF2FF);
  static const Color plannedFg = Color(0xFF2856C3);
  static const Color plannedBorder = Color(0xFFCFE0FF);
  static const Color doneBg = Color(0xFFE9F9EF);
  static const Color doneFg = Color(0xFF1F7D43);
  static const Color doneBorder = Color(0xFFCDEED9);
  static const Color defaultBg = Color(0xFFF2F3F8);
  static const Color defaultFg = Color(0xFF5E6176);
  static const Color defaultBorder = Color(0xFFE2E4EF);

  // Reservation statuses (calendar-view.component.ts)
  static const Color pendingBg = Color(0xFFFFF1DC);
  static const Color pendingFg = Color(0xFF9A5800);
  static const Color acceptedBg = Color(0xFFE6F7EF);
  static const Color acceptedFg = Color(0xFF186E45);
  static const Color refusedBg = Color(0xFFFFE9E8);
  static const Color refusedFg = Color(0xFF9F1F15);
  static const Color finishedBg = Color(0xFFE8F1FF);
  static const Color finishedFg = Color(0xFF1D4ED8);

  // Stat cards (top gradients)
  static const Color statTotal = Color(0xFFF8F7FF);
  static const Color statOnline = Color(0xFFF2F8FF);
  static const Color statPresential = Color(0xFFF2FCF5);
  static const Color statMonth = Color(0xFFFFF8EF);
  static const Color statValue = Color(0xFF2B2F4D);

  static const Color favorite = Color(0xFFFFC107);
  static const Color favoriteDeep = Color(0xFFFFB300);
  static const Color reservationHeader = Color(0xFFF7F9FF);
  static const Color reservationHeader2 = Color(0xFFEEF4FF);
  static const Color reservationBorder = Color(0xFFE3EBFD);
  static const Color reservationTitle = Color(0xFF1F2A44);
  static const Color reservationText = Color(0xFF5F6F8A);
}

/// Virtual meeting (dark UI of meeting-controls.component.ts).
abstract final class MeetingColors {
  static const Color background = Color(0xFF121212);
  static const Color bar = Color(0xF5181818);
  static const Color barBorder = Color(0xFF2F3136);
  static const Color tile = Color(0xFF26272B);
  static const Color tileAlt = Color(0xFF303136);
  static const Color control = Color(0xFF3C4043);
  static const Color danger = Color(0xFFEA4335);
  static const Color recording = Color(0xFFFF5252);
  static const Color textOnDark = Color(0xFFF1F3F4);
  static const Color textOnDarkMuted = Color(0xFF9AA0A6);
}

/// Geofencing (live tracking, alerts, supervision).
abstract final class GeoColors {
  static const Color safe = Color(0xFF1565C0);
  static const Color danger = Color(0xFFE53935);
  static const Color ok = Color(0xFF388E3C);
  static const Color okBg = Color(0xFFE8F5E9);
  static const Color dangerBg = Color(0xFFFFEBEE);
  static const Color safeBg = Color(0xFFE3F2FD);
  static const Color warning = Color(0xFFFB8C00);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color purple = Color(0xFF7E57C2);
  static const Color purpleBg = Color(0xFFEDE7F6);
  static const Color muted = Color(0xFF90A4AE);
  static const Color sos = Color(0xFFD32F2F);
}

/// Educational module (activities-list.component.css, game thumbnails).
abstract final class EduColors {
  static const Color title = Color(0xFF1A237E);
  static const Color subtitle = Color(0xFF5C6BC0);
  static const Color play = Color(0xFF3949AB);
  static const Color thumbBg = Color(0xFFE8EAF6);
  static const Color thumbBg2 = Color(0xFFC5CAE9);

  static const Color quizBadgeBg = Color(0xFFE3F2FD);
  static const Color quizBadgeFg = Color(0xFF0D47A1);
  static const Color cognitiveBadgeBg = Color(0xFFFFF3E0);
  static const Color cognitiveBadgeFg = Color(0xFFE65100);
  static const Color memoryBadgeBg = Color(0xFFE8F5E9);
  static const Color memoryBadgeFg = Color(0xFF1B5E20);
  static const Color videoBadgeBg = Color(0xFFFCE4EC);
  static const Color videoBadgeFg = Color(0xFF880E4F);
  static const Color contentBadgeBg = Color(0xFFF3E5F5);
  static const Color contentBadgeFg = Color(0xFF4A148C);
  static const Color defaultBadgeBg = Color(0xFFECEFF1);
  static const Color defaultBadgeFg = Color(0xFF37474F);

  // Thumbnails (assets/games/*.svg)
  static const Color thumbQuiz = Color(0xFF1565C0);
  static const Color thumbQuizText = Color(0xFFBBDEFB);
  static const Color thumbImage = Color(0xFFEF6C00);
  static const Color thumbImage2 = Color(0xFFFFB74D);
  static const Color thumbMemory = Color(0xFF2E7D32);
  static const Color thumbMemoryText = Color(0xFFA5D6A7);
  static const Color thumbContent = Color(0xFF6A1B9A);
  static const Color thumbContentText = Color(0xFFF3E5F5);
  static const Color thumbVideo = Color(0xFFAD1457);
  static const Color thumbVideoText = Color(0xFFFCE4EC);
  static const Color thumbDefault = Color(0xFF006064);
  static const Color thumbDefault2 = Color(0xFF26A69A);

  static const Color correct = Color(0xFF2E7D32);
  static const Color correctBg = Color(0xFFE8F5E9);
  static const Color wrong = Color(0xFFB71C1C);
  static const Color wrongBg = Color(0xFFFFEBEE);

  // Event cover gradients (event-cover-image.util.ts)
  static const List<List<Color>> eventCovers = [
    [Color(0xFF5C4D7D), Color(0xFF7B6FA2)],
    [Color(0xFF6D4C41), Color(0xFF8D6E63)],
    [Color(0xFF7B2D8B), Color(0xFF9C4DCC)],
    [Color(0xFF2E7D6D), Color(0xFF4DB6AC)],
    [Color(0xFFC67C38), Color(0xFFE89B4E)],
    [Color(0xFF5E35B1), Color(0xFF7E57C2)],
    [Color(0xFF1565C0), Color(0xFF42A5F5)],
  ];
}

/// Medical module (NeuroScan AI + follow-up dossiers).
abstract final class MedColors {
  static const Color neuro = Color(0xFF9B8FEF);
  static const Color neuroPink = Color(0xFFC084FC);
  static const Color neuroSoft = Color(0xFFA78BFA);
  static const Color neuroPale = Color(0xFFC4B5FD);
  static const Color neuroBg = Color(0xFFEDE9FE);
  static const Color neuroDeep = Color(0xFF7C3AED);
  static const Color ink = Color(0xFF1E1B4B);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color grayLight = Color(0xFFD1D5DB);

  // Risk colors (getRiskColor, globalRiskColor)
  static const Color riskLow = Color(0xFF6EE7B7);
  static const Color riskGreen = Color(0xFF10B981);
  static const Color riskYellow = Color(0xFFA78BFA);
  static const Color riskOrange = Color(0xFFC084FC);
  static const Color riskRed = Color(0xFFF87171);

  // Follow-up stage colors (getStageColor)
  static const Color stageNon = Color(0xFF38BDF8);
  static const Color stageVeryMild = Color(0xFF818CF8);
  static const Color stageMild = Color(0xFFC084FC);
  static const Color stageModerate = Color(0xFFFB7185);
  static const Color stageUnknown = Color(0xFF64748B);
  static const Color slate = Color(0xFF243447);

  // MRI viewer
  static const Color scanBg = Color(0xFF1A1A2E);
  static const Color scanLayer1 = Color(0xFF2D2D4A);
  static const Color scanLayer2 = Color(0xFF3D3D5C);
  static const Color scanLayer3 = Color(0xFF4A4A6A);
  static const Color scanLine = Color(0xFF666690);
}

/// Posts module (Facebook-like feed).
abstract final class PostColors {
  static const Color text = Color(0xFF1C1E21);
  static const Color textSecondary = Color(0xFF65676B);
  static const Color surface = Color(0xFFF0F2F5);
  static const Color like = Color(0xFF1877F2);
  static const Color heart = Color(0xFFE41E3F);
  static const Color support = Color(0xFFF7B928);
}
