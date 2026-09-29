import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';

/// Small rounded badge (web `.badge`, `.status-chip`, `.type-pill`…).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.icon,
    this.uppercase = false,
    this.dense = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final IconData? icon;
  final bool uppercase;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: AppDecorations.pill(background, border: border),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm - 2, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, letterSpacing: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
