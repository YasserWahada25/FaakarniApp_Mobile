import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography of the web app (styles.css):
/// - body: Poppins (`--font-family-base`)
/// - headings h1–h6: Playfair Display, weight 600, `--heading-color`
/// - display accents: Amatic SC (`--font-family-display`)
abstract final class AppTypography {
  static TextStyle base({
    double? size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textMain,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle heading({
    double? size,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.heading,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle display({double? size, Color color = AppColors.primaryDark}) =>
      GoogleFonts.amaticSc(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextTheme textTheme() => TextTheme(
        displayLarge: heading(size: 44, height: 1.15),
        displayMedium: heading(size: 36, height: 1.15),
        displaySmall: heading(size: 30, height: 1.2),
        headlineLarge: heading(size: 28, height: 1.2),
        headlineMedium: heading(size: 24, height: 1.25),
        headlineSmall: heading(size: 20, height: 1.3),
        titleLarge: base(size: 18, weight: FontWeight.w600, height: 1.3),
        titleMedium: base(size: 16, weight: FontWeight.w600, height: 1.35),
        titleSmall: base(size: 14, weight: FontWeight.w600, height: 1.35),
        bodyLarge: base(size: 16, height: 1.6),
        bodyMedium: base(size: 14, height: 1.6),
        bodySmall: base(size: 12, color: AppColors.textSecondary, height: 1.5),
        labelLarge: base(size: 14, weight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: base(size: 12, weight: FontWeight.w600, letterSpacing: 0.3),
        labelSmall: base(size: 11, weight: FontWeight.w600, letterSpacing: 0.4),
      );

  // ── Named styles reused by several widgets ───────────────────────────────
  /// `.brand-name` (navbar).
  static TextStyle get brandName =>
      base(size: 17, weight: FontWeight.w600, color: AppColors.primaryDark, letterSpacing: 0.5);

  /// `.tagline` (navbar, Arabic "فكرني").
  static TextStyle get tagline =>
      base(size: 12, weight: FontWeight.w500, color: AppColors.primary, letterSpacing: 0.3);

  /// Uppercase pill buttons (`.btn-primary`).
  static TextStyle get button =>
      base(size: 14.4, weight: FontWeight.w600, color: AppColors.white, letterSpacing: 0.5);

  /// Hero title (`.hero-title`) — Poppins, bold, heading color.
  static TextStyle get heroTitle =>
      base(size: 34, weight: FontWeight.w700, color: AppColors.heading, height: 1.15);

  /// Section eyebrow (`.sub-title`, `.pill-label`).
  static TextStyle get eyebrow =>
      base(size: 13, weight: FontWeight.w600, color: AppColors.primaryDark, letterSpacing: 1);

  /// Big number on stat cards.
  static TextStyle get statValue =>
      base(size: 22, weight: FontWeight.w800, color: SessionColors.statValue, height: 1);

  /// Numeric / coordinate values.
  static TextStyle get mono => GoogleFonts.robotoMono(fontSize: 13, color: AppColors.textMain);

  /// 6-digit verification code input (reset password).
  static TextStyle get codeInput => GoogleFonts.robotoMono(fontSize: 24, letterSpacing: 8, color: AppColors.textMain);

  /// Small pill label ("OUR WORKING PROCESS").
  static TextStyle get eyebrowSmall => eyebrow.copyWith(fontSize: 12);

  /// Tiny counter under calendar days ("+2").
  static TextStyle get micro => base(size: 9, weight: FontWeight.w600, color: AppColors.textSecondary);

  /// Big emoji used as quiz illustration.
  static const TextStyle emojiLarge = TextStyle(fontSize: 72);

  /// Required-field asterisk.
  static const TextStyle requiredMark = TextStyle(color: AppColors.error);

  /// Tight line height for stacked labels.
  static const double tightHeight = 1.1;

  // ── Onboarding ───────────────────────────────────────────────────────────
  /// "FAKARNI" wordmark — heavy, wide-set Poppins.
  static TextStyle get onboardingName =>
      base(size: 46, weight: FontWeight.w800, color: AppColors.white, letterSpacing: 4, height: 1.1);

  /// "فكرني" — Reem Kufi, a geometric Kufi face that pairs with Poppins.
  static TextStyle get onboardingArabic =>
      GoogleFonts.reemKufi(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.primaryLight, height: 1.2);
}
