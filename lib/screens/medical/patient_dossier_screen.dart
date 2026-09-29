import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/medical.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/medical/medical_widgets.dart';

/// Web `follow-up.component` — view 2: a patient's MRI dossier with the
/// Overview / Medical Record / Compare Scans / Statistics tabs.
class PatientDossierScreen extends StatefulWidget {
  const PatientDossierScreen({super.key, required this.patientId, this.patient});

  final String patientId;
  final FollowUpPatient? patient;

  @override
  State<PatientDossierScreen> createState() => _PatientDossierScreenState();
}

class _PatientDossierScreenState extends State<PatientDossierScreen> {
  // Filled by the dossiers API.
  MedicalDossier? _dossier;
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _exportDossier() {}

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final dossier = _dossier;
    final title = patient?.fullName ?? 'Dossier patient';
    if (dossier == null || _status != ViewStatus.ready) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AsyncStateView(
          status: _status,
          isEmpty: true,
          errorMessage: _error ?? 'Impossible de charger le dossier médical.',
          onRetry: _load,
          loading: const LoadingView(message: 'Chargement du dossier médical…'),
          empty: EmptyStateView(
            icon: Icons.folder_off_outlined,
            title: 'Aucun dossier médical',
            message: "Aucune analyse IRM n'a encore été enregistrée pour ce patient.",
            actionLabel: 'Réessayer',
            actionIcon: Icons.refresh_rounded,
            onAction: _load,
          ),
          builder: (_) => const SizedBox.shrink(),
        ),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(tooltip: 'Export Dossier', onPressed: _exportDossier, icon: const Icon(Icons.file_download_outlined)),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: ModuleColors.medical,
            indicatorColor: ModuleColors.medical,
            tabs: [
              Tab(icon: Icon(Icons.speed_rounded), text: 'Overview'),
              Tab(icon: Icon(Icons.folder_shared_outlined), text: 'Medical Record'),
              Tab(icon: Icon(Icons.compare_rounded), text: 'Compare Scans'),
              Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Statistics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Overview(dossier: dossier, patient: patient),
            _RecordTimeline(dossier: dossier),
            _Compare(dossier: dossier),
            _Stats(dossier: dossier),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.dossier, required this.patient});

  final MedicalDossier dossier;
  final FollowUpPatient? patient;

  CognitiveTrend get _trend {
    if (dossier.analyses.length < 2) return CognitiveTrend.insufficient;
    final diff = dossier.analyses[0].estimatedMmse - dossier.analyses[1].estimatedMmse;
    return diff > 0 ? CognitiveTrend.improving : (diff < 0 ? CognitiveTrend.declining : CognitiveTrend.stable);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final latest = dossier.latest;
    final stageColor = latest?.prediction.followUpColor ?? MedColors.stageUnknown;
    final trendColor = switch (_trend) {
      CognitiveTrend.declining => MedColors.stageModerate,
      CognitiveTrend.improving => MedColors.stageNon,
      _ => MedColors.stageVeryMild,
    };
    return ListView(
      padding: AppSpacing.screen,
      children: [
        AppCard(
          child: Row(
            children: [
              InitialsAvatar(initials: patient?.initials, color: stageColor, size: AppSizes.avatarLg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient?.fullName ?? '—', style: text.titleMedium),
                    Text('Dossier #${dossier.id}', style: text.bodySmall),
                  ],
                ),
              ),
              if (latest != null) ArcGauge(value: latest.estimatedMmse.toDouble(), max: 30, color: stageColor, caption: 'MMSE /30'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StatGrid(children: [
          StatCard(
            label: 'Total Scans',
            value: '${dossier.analyses.length}',
            icon: Icons.psychology_outlined,
            iconColor: MedColors.stageVeryMild,
          ),
          StatCard(
            label: 'Current Stage',
            value: latest == null ? '—' : 'Stage ${latest.prediction.number}',
            icon: latest?.prediction.icon ?? Icons.help_outline_rounded,
            iconColor: stageColor,
            valueColor: stageColor,
          ),
          StatCard(label: 'Cognitive Trend', value: _trend.label, icon: Icons.trending_up_rounded, iconColor: trendColor),
          StatCard(
            label: 'Last Updated',
            value: Formatters.shortDate(dossier.updatedAt),
            icon: Icons.event_available_outlined,
            iconColor: MedColors.slate,
          ),
        ]),
        if (latest != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ScanCard(analysis: latest, title: 'Latest Analysis'),
        ],
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.analysis, required this.title});

  final MriAnalysis analysis;
  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = analysis.prediction.followUpColor;
    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: text.labelMedium?.copyWith(color: MedColors.gray))),
              AppChip(
                label: 'Stage ${analysis.prediction.number} — ${analysis.riskLevel.label}',
                background: color.withValues(alpha: 0.12),
                foreground: color,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(analysis.prediction.label, style: text.titleMedium?.copyWith(color: color)),
          Text(Formatters.dateTime(analysis.date), style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: ProgressTrack(value: analysis.confidence / 100, color: color)),
              const SizedBox(width: AppSpacing.sm),
              Text('${analysis.confidence.toStringAsFixed(1)}%', style: text.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(analysis.fileName, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _RecordTimeline extends StatelessWidget {
  const _RecordTimeline({required this.dossier});

  final MedicalDossier dossier;

  @override
  Widget build(BuildContext context) {
    if (dossier.analyses.isEmpty) {
      return const EmptyStateView(icon: Icons.folder_off_outlined, title: 'Aucune analyse enregistrée');
    }
    return ListView(
      padding: AppSpacing.screen,
      children: [
        for (final a in dossier.analyses)
          Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _ScanCard(analysis: a, title: 'Analyse #${a.id}')),
      ],
    );
  }
}

class _Compare extends StatelessWidget {
  const _Compare({required this.dossier});

  final MedicalDossier dossier;

  @override
  Widget build(BuildContext context) {
    if (dossier.analyses.length < 2) {
      return const EmptyStateView(
        icon: Icons.compare_rounded,
        title: 'Comparaison indisponible',
        message: 'Au moins deux analyses sont nécessaires pour comparer les scans.',
      );
    }
    return ListView(
      padding: AppSpacing.screen,
      children: [
        _ScanCard(analysis: dossier.analyses[1], title: 'Scan précédent'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Icon(Icons.arrow_downward_rounded, color: MedColors.neuro),
        ),
        _ScanCard(analysis: dossier.analyses[0], title: 'Scan actuel'),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.dossier});

  final MedicalDossier dossier;

  @override
  Widget build(BuildContext context) {
    if (dossier.analyses.isEmpty) {
      return const EmptyStateView(icon: Icons.bar_chart_rounded, title: 'Aucune statistique disponible');
    }
    final text = Theme.of(context).textTheme;
    final chronological = dossier.analyses.reversed.toList();
    final counts = {for (final s in DementiaStage.values) s: dossier.analyses.where((a) => a.prediction == s).length};
    return ListView(
      padding: AppSpacing.screen,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'MMSE Score Evolution', icon: Icons.bar_chart_rounded, color: ModuleColors.medical),
              SimpleBarChart(
                maxValue: MmsePoint.max.toDouble(),
                bars: [
                  for (final a in chronological)
                    ChartBar(
                      label: Formatters.monthShort(a.date),
                      value: a.estimatedMmse.toDouble(),
                      color: a.prediction.followUpColor,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Stage Distribution', icon: Icons.pie_chart_outline_rounded, color: ModuleColors.medical),
              for (final e in counts.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(width: AppSizes.labelColumnWide, child: Text(e.key.label, style: text.bodySmall)),
                      Expanded(
                        child: ProgressTrack(value: e.value / dossier.analyses.length, color: e.key.followUpColor),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('${e.value}', style: text.labelMedium),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
