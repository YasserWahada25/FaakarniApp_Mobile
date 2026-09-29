import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Reusable gradients and box decorations taken from the web stylesheets.
abstract final class AppGradients {
  /// `.btn-primary` hero variant: primary → primary-hover.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryHover],
  );

  /// `.auth-section`: bg-main → bg-secondary.
  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgMain, AppColors.bgSecondary],
  );

  /// `.services-section`: white → bg-main.
  static const LinearGradient softVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.white, AppColors.bgMain],
  );

  /// `.badge-circle` (hero badge): primary → primary-soft.
  static const LinearGradient badge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primarySoft],
  );

  /// `.highlight` underline in the CTA title.
  static const LinearGradient highlight = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primarySoft],
  );

  /// Brand header (drawer, splash) — logo background.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandDeep, AppColors.primaryDark],
  );

  /// Alzheimer join button (`.join-btn`).
  static const LinearGradient alzheimer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ModuleColors.alzheimer, ModuleColors.alzheimerViolet],
  );

  /// Favorites header icon.
  static const LinearGradient favorite = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SessionColors.favorite, SessionColors.favoriteDeep],
  );

  /// Reservation page header.
  static const LinearGradient reservationHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SessionColors.reservationHeader, SessionColors.reservationHeader2],
  );

  /// NeuroScan AI logo gradient.
  static const LinearGradient neuro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MedColors.neuro, MedColors.neuroPink],
  );

  /// Educational "Jouer" button.
  static const LinearGradient eduPlay = LinearGradient(
    colors: [EduColors.play, EduColors.subtitle],
  );

  static LinearGradient vertical(Color top) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, AppColors.white],
      );

  static LinearGradient diagonal(Color a, Color b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      );
}

abstract final class AppDecorations {
  /// White card with subtle border and `--shadow-sm` (most web cards).
  static BoxDecoration card({
    Color color = AppColors.bgCard,
    BorderRadius radius = AppRadius.lgAll,
    Color borderColor = AppColors.bgSecondary,
    List<BoxShadow> shadow = AppShadows.sm,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      );

  /// Rounded chip/badge.
  static BoxDecoration pill(Color background, {Color? border}) => BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.round)),
        border: border == null ? null : Border.all(color: border),
      );

  /// `.auth-box`.
  static const BoxDecoration authBox = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppRadius.pillAll,
    boxShadow: AppShadows.lg,
    border: Border.fromBorderSide(BorderSide(color: AppColors.bgSecondary)),
  );
}
