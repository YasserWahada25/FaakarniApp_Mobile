import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// The single [ThemeData] of the app. Component themes reproduce the web
/// classes (`.btn-primary`, `.btn-secondary`, `.form-group input`, cards…).
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.bgSecondary,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.secondaryButton,
      onSecondaryContainer: AppColors.primaryDark,
      tertiary: AppColors.info,
      surface: AppColors.bgCard,
      onSurface: AppColors.textMain,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.bgPage,
      surfaceContainer: AppColors.bgMain,
      surfaceContainerHigh: AppColors.bgSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.bgSecondary,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorBg,
      onErrorContainer: AppColors.errorText,
    );

    final textTheme = AppTypography.textTheme();

    const pillShape = RoundedRectangleBorder(borderRadius: AppRadius.pillAll);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.md);
    const buttonMinSize = Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: AppColors.bgPage,
      canvasColor: AppColors.bgCard,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      dividerTheme: const DividerThemeData(color: AppColors.bgSecondary, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.primaryDark, size: AppSizes.icon),
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.shadowMd,
        centerTitle: false,
        titleTextStyle: AppTypography.brandName,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        actionsIconTheme: const IconThemeData(color: AppColors.primaryDark),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.white,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: pillShape,
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: pillShape,
          textStyle: AppTypography.button,
          shadowColor: AppColors.shadowMd,
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: pillShape,
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTypography.button.copyWith(color: AppColors.primaryDark),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: buttonMinSize,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: buttonMinSize,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.bgMain,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w500),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.errorText),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primaryDark,
        border: inputBorder(AppColors.bgSecondary),
        enabledBorder: inputBorder(AppColors.bgSecondary),
        focusedBorder: inputBorder(AppColors.primary, 1.5),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.5),
        disabledBorder: inputBorder(AppColors.borderLight),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgCard,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.shadowMd,
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.bgSecondary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgMain,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.borderLight,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.white),
        side: const BorderSide(color: AppColors.bgSecondary),
        shape: const StadiumBorder(),
        checkmarkColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: AppColors.bgSecondary,
        elevation: 3,
        shadowColor: AppColors.shadowMd,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.bgSecondary,
        tabAlignment: TabAlignment.start,
        overlayColor: const WidgetStatePropertyAll(AppColors.focusRing),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.pill)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primaryDark,
        textColor: AppColors.textMain,
        minTileHeight: AppSizes.minTouchTarget,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        textColor: AppColors.primaryDark,
        collapsedTextColor: AppColors.textMain,
        shape: Border(),
        collapsedShape: Border(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
        actionTextColor: AppColors.primaryLight,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.bgSecondary,
        circularTrackColor: AppColors.bgSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(color: AppColors.primarySoft, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.primarySoft,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.bgSecondary,
        thumbColor: AppColors.primaryDark,
        overlayColor: AppColors.focusRing,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonMinSize),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.primaryDark,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.primarySoft)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(color: AppColors.primaryDark, borderRadius: AppRadius.smAll),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.white),
      ),
    );
  }
}
