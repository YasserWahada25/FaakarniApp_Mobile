import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import 'shimmer.dart';

/// Centered spinner with an optional message (web `.loading-state`).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Skeleton placeholders shown while a list is loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 3, this.itemHeight = 96});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonBox(height: itemHeight),
            ),
        ],
      ),
    );
  }
}

/// Illustrated empty state (web `.empty-state`).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: compact ? AppSpacing.xl : AppSpacing.section,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? AppSizes.avatarLg : AppSizes.avatarXl,
              height: compact ? AppSizes.avatarLg : AppSizes.avatarXl,
              decoration: const BoxDecoration(color: AppColors.bgSecondary, shape: BoxShape.circle),
              child: Icon(icon, size: compact ? AppSizes.iconLg : AppSizes.iconXl * 0.8, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleMedium?.copyWith(color: AppColors.textInk), textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(message!, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add, size: AppSizes.iconMd),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry button (web `.error-state` / `.error-container`).
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.avatarXl,
              height: AppSizes.avatarXl,
              decoration: const BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: AppSizes.iconXl * 0.8, color: AppColors.errorText),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Une erreur est survenue', style: text.titleMedium?.copyWith(color: AppColors.textInk)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message ?? 'Impossible de charger les données. Vérifiez votre connexion puis réessayez.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: AppSizes.iconMd),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline feedback banner (web `.auth-error`, `.auth-success`, `.info-box`).
enum BannerKind { error, success, info }

class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.message, this.kind = BannerKind.error, this.onClose});

  final String message;
  final BannerKind kind;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (kind) {
      BannerKind.error => (AppColors.errorBg, AppColors.errorText, Icons.error_outline_rounded),
      BannerKind.success => (AppColors.successBg, AppColors.successText, Icons.check_circle_outline_rounded),
      BannerKind.info => (AppColors.bgSecondary, AppColors.primaryDark, Icons.info_outline_rounded),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
      child: Row(
        children: [
          Icon(icon, color: fg, size: AppSizes.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg))),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: fg, size: AppSizes.iconMd),
              tooltip: 'Fermer',
            ),
        ],
      ),
    );
  }
}
