import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

class ChartBar {
  const ChartBar({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;
}

/// Vertical bar chart drawn with plain widgets (the web uses CSS bars).
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.bars,
    this.maxValue,
    this.height = AppSizes.chartHeight,
    this.showValues = true,
    this.valueSuffix = '',
  });

  final List<ChartBar> bars;
  final double? maxValue;
  final double height;
  final bool showValues;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final max = maxValue ?? bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showValues && bar.value > 0)
                      Text(
                        '${bar.value.toStringAsFixed(0)}$valueSuffix',
                        style: text.labelSmall?.copyWith(color: bar.color ?? AppColors.primaryDark),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: max <= 0 ? 0.02 : (bar.value / max).clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [bar.color ?? AppColors.primary, (bar.color ?? AppColors.primarySoft).withValues(alpha: 0.6)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xs)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(bar.label, style: text.labelSmall?.copyWith(color: AppColors.textSecondary), maxLines: 1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal progress bar with rounded track (web `.progress-bar`, `.prob-track`).
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.trackColor = AppColors.bgSecondary,
    this.height = AppSizes.progressHeight,
  });

  /// Between 0 and 1.
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        color: color,
        backgroundColor: trackColor,
      ),
    );
  }
}
