import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/medical.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';

/// Web `records/patient-profile.component`: patient header, vitals,
/// medical history timeline and MMSE evolution.
class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  // Filled by the medical-record API.
  PatientProfile? _profile;
  Vitals? _vitals;
  final List<MedicalHistoryEntry> _history = [];
  final List<MmsePoint> _mmse = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          AsyncStateView(
            status: _status,
            isEmpty: _profile == null,
            errorMessage: _error,
            onRetry: _load,
            empty: const EmptyStateView(
              icon: Icons.folder_shared_outlined,
              title: 'Aucun dossier médical',
              message: 'Le dossier du patient apparaîtra ici.',
            ),
            builder: (context) => _content(context, _profile!),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, PatientProfile profile) {
    final text = Theme.of(context).textTheme;
    final vitals = _vitals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  const InitialsAvatar(size: AppSizes.avatarLg, color: ModuleColors.medical),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: text.headlineSmall),
                        Text('Age: ${profile.age} | Blood Type: ${profile.bloodType}', style: text.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        AppChip(
                          label: profile.condition,
                          background: ModuleColors.medicalActiveBg,
                          foreground: ModuleColors.medical,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (vitals != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _Vital(icon: Icons.monitor_heart_outlined, value: vitals.bloodPressure, unit: 'mmHg'),
                    _Vital(icon: Icons.favorite_border_rounded, value: '${vitals.heartRate}', unit: 'bpm'),
                    _Vital(icon: Icons.monitor_weight_outlined, value: '${vitals.weight}', unit: 'kg'),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Medical History', icon: Icons.history_rounded, color: ModuleColors.medical),
              if (_history.isEmpty)
                const EmptyStateView(compact: true, icon: Icons.history_rounded, title: 'Aucun antécédent enregistré')
              else
                for (final h in _history) _TimelineEntry(entry: h),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'MMSE Evolution',
                subtitle: 'Mini-Mental State Examination Scores',
                icon: Icons.show_chart_rounded,
                color: ModuleColors.medical,
              ),
              if (_mmse.isEmpty)
                const EmptyStateView(compact: true, icon: Icons.show_chart_rounded, title: 'Aucun score MMSE')
              else
                SimpleBarChart(
                  maxValue: MmsePoint.max.toDouble(),
                  bars: [for (final m in _mmse) ChartBar(label: m.label, value: m.score.toDouble(), color: ModuleColors.medical)],
                ),
              const SizedBox(height: AppSpacing.sm),
              Text('Standard Range: 24-30 (Normal)', style: text.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

class _Vital extends StatelessWidget {
  const _Vital({required this.icon, required this.value, required this.unit});

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: const BoxDecoration(color: ModuleColors.medicalActiveBg, borderRadius: AppRadius.mdAll),
        child: Column(
          children: [
            Icon(icon, color: ModuleColors.medical),
            Text(value, style: text.titleMedium),
            Text(unit, style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry});

  final MedicalHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: AppSizes.dot + 4,
                height: AppSizes.dot + 4,
                decoration: const BoxDecoration(gradient: AppGradients.neuro, shape: BoxShape.circle),
              ),
              const Expanded(child: VerticalDivider(color: ModuleColors.medicalActiveBg, thickness: 2)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Formatters.shortDate(entry.date), style: text.labelSmall?.copyWith(color: ModuleColors.medical)),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: entry.type, style: text.titleSmall),
                    TextSpan(text: '  with ${entry.doctor}', style: text.bodySmall),
                  ])),
                  Text('Diagnosis: ${entry.diagnosis}', style: text.bodySmall),
                  Text('Treatment: ${entry.treatment}', style: text.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
