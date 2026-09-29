import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';

/// White rounded card of the web app (border `--bg-secondary`, `--shadow-sm`),
/// optionally tappable and with a colored accent strip on the left or top.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.accentColor,
    this.accentOnTop = false,
    this.color = AppColors.bgCard,
    this.borderColor = AppColors.bgSecondary,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool accentOnTop;
  final Color color;
  final Color borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);
    if (accentColor != null) {
      final strip = accentOnTop
          ? Container(height: AppSizes.accentWidth, color: accentColor)
          : Container(width: AppSizes.accentWidth, color: accentColor);
      content = accentOnTop
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [strip, content])
          : IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [strip, Expanded(child: content)]),
            );
    }
    return DecoratedBox(
      decoration: AppDecorations.card(color: color, borderColor: borderColor).copyWith(gradient: gradient),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: ClipRRect(borderRadius: AppRadius.lgAll, child: content),
        ),
      ),
    );
  }
}
