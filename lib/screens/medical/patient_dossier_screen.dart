import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/medical.dart';
import '../../services/medical_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/network_picture.dart';
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
  final _service = MedicalService.instance;

  MedicalDossier? _dossier;
  ViewStatus _status = ViewStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.revision.addListener(_onChanged);
    _load();
  }

  @override
  void dispose() {
    _service.revision.removeListener(_onChanged);
    super.dispose();
  }

  /// A new MRI analysis was run for a patient (NeuroScan tab).
  void _onChanged() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _status = ViewStatus.loading;
        _error = null;
      });
    }
    try {
      await AuthSession.instance.ensureSignedIn();
      final dossier = await _service.getDossier(widget.patientId);
      if (!mounted) return;
      setState(() {
        _dossier = dossier;
        _status = ViewStatus.ready;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _status = ViewStatus.error;
        _error = ApiException.describe(e);
      });
    }
  }

  /// Doctor's description, advice and clinical notes (web "Modifier").
  Future<void> _edit(MriAnalysis analysis) async {
    final result = await showModalBottomSheet<(String, String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditAnalysisSheet(analysis: analysis),
    );
    if (result == null) return;
    try {
      final dossier = await _service.updateAnalysis(
        analysis.id,
        description: result.$1,
        doctorAdvice: result.$2.isEmpty ? null : result.$2,
        clinicalNotes: result.$3.isEmpty ? null : result.$3,
      );
      if (!mounted) return;
      setState(() => _dossier = dossier);
      showAppSnackBar(context, 'Analyse mise à jour.');
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    }
  }

  Future<void> _delete(MriAnalysis analysis) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer l'analyse",
      message: "Supprimer l'analyse #${analysis.id} du ${Formatters.shortDate(analysis.date)} ?",
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      final dossier = await _service.deleteAnalysis(analysis.id);
      if (!mounted) return;
      setState(() => _dossier = dossier);
      showAppSnackBar(context, 'Analyse supprimée.');
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    }
  }

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
          actions: [IconButton(tooltip: 'Actualiser', onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
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
            _RecordTimeline(dossier: dossier, onEdit: _edit, onDelete: _delete),
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
              if (latest != null)
                ArcGauge(value: latest.estimatedMmse.toDouble(), max: 30, color: stageColor, caption: 'MMSE /30'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StatGrid(
          children: [
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
            StatCard(
              label: 'Cognitive Trend',
              value: _trend.label,
              icon: Icons.trending_up_rounded,
              iconColor: trendColor,
            ),
            StatCard(
              label: 'Last Updated',
              value: Formatters.shortDate(dossier.updatedAt),
              icon: Icons.event_available_outlined,
              iconColor: MedColors.slate,
            ),
          ],
        ),
        if (latest != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ScanCard(analysis: latest, title: 'Latest Analysis'),
        ],
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.analysis, required this.title, this.onEdit, this.onDelete});

  final MriAnalysis analysis;
  final String title;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
              Expanded(
                child: Text(title, style: text.labelMedium?.copyWith(color: MedColors.gray)),
              ),
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
              Expanded(
                child: ProgressTrack(value: analysis.confidence / 100, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${analysis.confidence.toStringAsFixed(1)}%', style: text.labelMedium),
            ],
          ),
          if (analysis.fileName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _MriThumbnail(fileName: analysis.fileName),
          ],
          if (analysis.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(analysis.description, style: text.bodySmall),
          ],
          if (analysis.doctorAdvice != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Conseil du médecin : ', style: text.labelMedium),
                  TextSpan(text: analysis.doctorAdvice, style: text.bodySmall),
                ],
              ),
            ),
          ],
          if (analysis.clinicalNotes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Notes cliniques : ', style: text.labelMedium),
                  TextSpan(text: analysis.clinicalNotes, style: text.bodySmall),
                ],
              ),
            ),
          ],
          if (onEdit != null || onDelete != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Modifier'),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Supprimer'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Stored MRI scan (Detection service); tap to zoom.
class _MriThumbnail extends StatelessWidget {
  const _MriThumbnail({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final url = MedicalService.imageUrl(fileName);
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(maxScale: 5, child: Image.network(url, fit: BoxFit.contain)),
              ),
              SafeArea(
                child: IconButton(
                  tooltip: 'Fermer',
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        color: MedColors.scanBg,
        child: NetworkPicture(
          url: url,
          height: 160,
          width: double.infinity,
          fit: BoxFit.contain,
          borderRadius: AppRadius.mdAll,
        ),
      ),
    );
  }
}

class _EditAnalysisSheet extends StatefulWidget {
  const _EditAnalysisSheet({required this.analysis});

  final MriAnalysis analysis;

  @override
  State<_EditAnalysisSheet> createState() => _EditAnalysisSheetState();
}

class _EditAnalysisSheetState extends State<_EditAnalysisSheet> {
  late final _description = TextEditingController(text: widget.analysis.description);
  late final _advice = TextEditingController(text: widget.analysis.doctorAdvice);
  late final _notes = TextEditingController(text: widget.analysis.clinicalNotes);

  @override
  void dispose() {
    _description.dispose();
    _advice.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.gutter + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Analyse #${widget.analysis.id} — ${widget.analysis.prediction.label}', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description du risque'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _advice,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Conseil du médecin'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes cliniques'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop((_description.text.trim(), _advice.text.trim(), _notes.text.trim())),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _RecordTimeline extends StatelessWidget {
  const _RecordTimeline({required this.dossier, required this.onEdit, required this.onDelete});

  final MedicalDossier dossier;
  final ValueChanged<MriAnalysis> onEdit;
  final ValueChanged<MriAnalysis> onDelete;

  @override
  Widget build(BuildContext context) {
    if (dossier.analyses.isEmpty) {
      return const EmptyStateView(icon: Icons.folder_off_outlined, title: 'Aucune analyse enregistrée');
    }
    return ListView(
      padding: AppSpacing.screen,
      children: [
        for (final a in dossier.analyses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ScanCard(
              analysis: a,
              title: 'Analyse #${a.id}',
              onEdit: () => onEdit(a),
              onDelete: () => onDelete(a),
            ),
          ),
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
              const SectionHeader(
                title: 'MMSE Score Evolution',
                icon: Icons.bar_chart_rounded,
                color: ModuleColors.medical,
              ),
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
              const SectionHeader(
                title: 'Stage Distribution',
                icon: Icons.pie_chart_outline_rounded,
                color: ModuleColors.medical,
              ),
              for (final e in counts.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: AppSizes.labelColumnWide,
                        child: Text(e.key.label, style: text.bodySmall),
                      ),
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
