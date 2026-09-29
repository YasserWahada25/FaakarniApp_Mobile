import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// KPI tile (web `.stat-card`, `.kpi-card`): label + big value, optional icon.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor = AppColors.primary,
    this.tint = AppColors.white,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color iconColor;

  /// Top color of the vertical gradient (white at the bottom).
  final Color tint;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(borderColor: AppColors.borderViolet).copyWith(
        gradient: AppGradients.vertical(tint),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: AppSizes.avatarSm,
              height: AppSizes.avatarSm,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.14), borderRadius: AppRadius.smAll),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: AppTypography.statValue.copyWith(color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out [children] as a 2-column grid of equal-width tiles.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: children[i]),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
        ],
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: AppSpacing.md));
    }
    return Column(children: rows);
  }
}
