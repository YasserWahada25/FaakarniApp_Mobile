import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/clinical_scoring.dart';
import '../../models/medical.dart';
import '../common/charts.dart';

extension DementiaStageStyle on DementiaStage {
  /// Follow-up dossier palette (getStageColor).
  Color get followUpColor => switch (this) {
        DementiaStage.nonDemented => MedColors.stageNon,
        DementiaStage.veryMild => MedColors.stageVeryMild,
        DementiaStage.mild => MedColors.stageMild,
        DementiaStage.moderate => MedColors.stageModerate,
      };

  /// NeuroScan palette (getRiskColor / probability colors).
  Color get riskColor => switch (this) {
        DementiaStage.nonDemented => MedColors.riskGreen,
        DementiaStage.veryMild => MedColors.riskYellow,
        DementiaStage.mild => MedColors.riskOrange,
        DementiaStage.moderate => MedColors.riskRed,
      };

  IconData get icon => switch (this) {
        DementiaStage.nonDemented => Icons.health_and_safety_outlined,
        DementiaStage.veryMild => Icons.manage_search_rounded,
        DementiaStage.mild => Icons.warning_amber_rounded,
        DementiaStage.moderate => Icons.error_outline_rounded,
      };

  String get description => switch (this) {
        DementiaStage.nonDemented => 'Aucun signe de démence détecté sur cette IRM.',
        DementiaStage.veryMild => 'Signes très discrets, compatibles avec un déclin cognitif débutant.',
        DementiaStage.mild => 'Atteinte légère : suivi neurologique rapproché recommandé.',
        DementiaStage.moderate => 'Atteinte modérée : prise en charge spécialisée nécessaire.',
      };
}

extension RiskBandStyle on RiskBand {
  /// Global risk index colors.
  Color get globalColor => switch (this) {
        RiskBand.low => MedColors.riskLow,
        RiskBand.moderate => MedColors.riskYellow,
        RiskBand.high => MedColors.riskOrange,
        RiskBand.critical => MedColors.riskRed,
      };

  /// Questionnaire score colors.
  Color get questionnaireColor => switch (this) {
        RiskBand.low => MedColors.riskGreen,
        RiskBand.moderate => MedColors.riskYellow,
        RiskBand.high => MedColors.riskOrange,
        RiskBand.critical => MedColors.riskRed,
      };
}

/// Half-circle gauge (web `.arc-svg`), value between 0 and [max].
class ArcGauge extends StatelessWidget {
  const ArcGauge({super.key, required this.value, required this.color, this.max = 100, this.caption = '/100'});

  final double value;
  final Color color;
  final double max;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: AppSizes.gaugeWidth,
      height: AppSizes.gaugeHeight,
      child: CustomPaint(
        painter: _ArcPainter(fraction: (value / max).clamp(0, 1), color: color),
        child: Align(
          alignment: const Alignment(0, 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value.round().toString(), style: text.headlineLarge?.copyWith(color: color, height: 1)),
              Text(caption, style: text.labelSmall?.copyWith(color: MedColors.gray)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height - stroke),
      radius: min(size.width / 2, size.height) - stroke,
    );
    final track = Paint()
      ..color = MedColors.neuroBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, track);
    if (fraction > 0) canvas.drawArc(rect, pi, pi * fraction, false, fill);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.fraction != fraction || old.color != color;
}

/// Horizontal stage track (Stade 1 → 4) of the NeuroScan results panel.
class StageTrack extends StatelessWidget {
  const StageTrack({super.key, this.active});

  final DementiaStage? active;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final activeNumber = active?.number ?? 0;
    return Row(
      children: [
        for (final s in DementiaStage.values) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: AppSizes.avatarSm,
                  height: AppSizes.avatarSm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.number == activeNumber
                        ? s.riskColor
                        : (s.number < activeNumber ? s.riskColor.withValues(alpha: 0.3) : MedColors.neuroBg),
                  ),
                  child: Icon(
                    s.icon,
                    size: AppSizes.iconMd,
                    color: s.number == activeNumber ? AppColors.white : MedColors.neuro,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Stade ${s.number}', style: text.labelSmall?.copyWith(color: MedColors.gray)),
                Text(s.shortLabel, style: text.labelSmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Distribution des probabilités" list.
class ProbabilityList extends StatelessWidget {
  const ProbabilityList({super.key, required this.analysis});

  final MriAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final s in DementiaStage.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: AppSizes.iconSm - 6, color: s.riskColor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        s.label,
                        style: text.bodySmall?.copyWith(
                          fontWeight: s == analysis.prediction ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text('Stade ${s.roman}', style: text.labelSmall?.copyWith(color: MedColors.gray)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${(analysis.probabilities[s] ?? 0).toStringAsFixed(2)}%',
                      style: text.labelMedium?.copyWith(color: s.riskColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                ProgressTrack(value: (analysis.probabilities[s] ?? 0) / 100, color: s.riskColor, trackColor: MedColors.neuroBg),
              ],
            ),
          ),
      ],
    );
  }
}

/// Wizard stepper (web `.wizard-stepper`).
class WizardStepper extends StatelessWidget {
  const WizardStepper({
    super.key,
    required this.steps,
    required this.current,
    required this.completed,
    required this.onStepTap,
  });

  final List<(String, IconData)> steps;
  final int current;
  final Set<int> completed;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: InkWell(
              borderRadius: AppRadius.mdAll,
              onTap: () => onStepTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    Container(
                      width: AppSizes.avatar,
                      height: AppSizes.avatar,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == current
                            ? MedColors.neuro
                            : (completed.contains(i) ? MedColors.riskGreen : MedColors.neuroBg),
                      ),
                      child: Icon(
                        completed.contains(i) && i != current ? Icons.check_rounded : steps[i].$2,
                        color: i == current || completed.contains(i) ? AppColors.white : MedColors.neuro,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Étape ${i + 1}/${steps.length}', style: text.labelSmall?.copyWith(color: MedColors.gray)),
                    Text(
                      steps[i].$1,
                      textAlign: TextAlign.center,
                      style: text.labelMedium?.copyWith(color: i == current ? MedColors.neuroDeep : AppColors.textMain),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: AppSpacing.lg,
              height: AppSizes.stepConnector,
              color: completed.contains(i) ? MedColors.riskGreen : MedColors.neuroBg,
            ),
        ],
      ],
    );
  }
}
