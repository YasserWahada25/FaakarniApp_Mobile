import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/medical.dart';
import '../../models/user.dart';
import '../../services/medical_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/medical/medical_widgets.dart';

/// Web `records/patient-profile.component`: the signed-in user's medical
/// dossier (MRI analyses from Dossier-Medical-Service) and the estimated
/// cognitive evolution. Caregivers open their patients' dossiers in Follow-up.
class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final _service = MedicalService.instance;

  MedicalDossier? _dossier;
  ViewStatus _status = ViewStatus.loading;
  String? _error;

  AppUser? get _user => AuthSession.instance.user;

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

  void _onChanged() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _status = ViewStatus.loading;
        _error = null;
      });
    }
    try {
      final me = await AuthSession.instance.ensureSignedIn() ? AuthSession.instance.userId : null;
      if (me == null) throw const ApiException('Connectez-vous pour consulter votre dossier médical.');
      final dossier = await _service.getDossier(me);
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

  @override
  Widget build(BuildContext context) {
    final isPatient = _user == null || _user!.role == UserRole.patient;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          AsyncStateView(
            status: _status,
            isEmpty: _dossier == null,
            errorMessage: _error,
            onRetry: _load,
            empty: Column(
              children: [
                _header(context, null),
                const SizedBox(height: AppSpacing.lg),
                EmptyStateView(
                  icon: Icons.folder_shared_outlined,
                  title: 'Aucun dossier médical pour le moment',
                  message: isPatient
                      ? 'Votre dossier sera créé automatiquement après votre première analyse IRM.'
                      : 'Cette page présente le dossier du patient connecté. '
                            'Les dossiers de vos patients sont dans l’onglet Follow-up.',
                ),
              ],
            ),
            builder: (context) => _content(context, _dossier!),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, MedicalDossier? dossier) {
    final text = Theme.of(context).textTheme;
    final user = _user;
    final latest = dossier?.latest;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(initials: user?.initials, size: AppSizes.avatarLg, color: ModuleColors.medical),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Mon dossier', style: text.headlineSmall),
                    if (user != null) Text(user.email, style: text.bodySmall),
                    if (user != null && user.numTel.isNotEmpty) Text(user.numTel, style: text.bodySmall),
                    if (latest != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppChip(
                        label: 'Dernier stade : ${latest.prediction.shortLabel}',
                        background: latest.prediction.followUpColor.withValues(alpha: 0.12),
                        foreground: latest.prediction.followUpColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (dossier != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _Vital(icon: Icons.psychology_outlined, value: '${dossier.analyses.length}', unit: 'analyse(s) IRM'),
                _Vital(icon: Icons.warning_amber_rounded, value: latest?.riskLevel.label ?? '—', unit: 'risque'),
                _Vital(
                  icon: Icons.event_available_outlined,
                  value: Formatters.shortDate(dossier.updatedAt),
                  unit: 'mise à jour',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _content(BuildContext context, MedicalDossier dossier) {
    final text = Theme.of(context).textTheme;
    final chronological = dossier.analyses.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, dossier),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Historique des analyses IRM',
                icon: Icons.history_rounded,
                color: ModuleColors.medical,
              ),
              for (final a in dossier.analyses) _TimelineEntry(analysis: a),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Évolution cognitive',
                subtitle: 'Score indicatif /30 déduit du stade détecté par l’IA',
                icon: Icons.show_chart_rounded,
                color: ModuleColors.medical,
              ),
              SimpleBarChart(
                maxValue: MmsePoint.max.toDouble(),
                bars: [
                  for (final a
                      in chronological.length > 8 ? chronological.sublist(chronological.length - 8) : chronological)
                    ChartBar(
                      label: Formatters.monthShort(a.date),
                      value: a.estimatedMmse.toDouble(),
                      color: a.prediction.followUpColor,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Repère : 24-30 = normal · indicatif, ne remplace pas un test MMSE',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        decoration: const BoxDecoration(color: ModuleColors.medicalActiveBg, borderRadius: AppRadius.mdAll),
        child: Column(
          children: [
            Icon(icon, color: ModuleColors.medical),
            Text(value, style: text.titleSmall, textAlign: TextAlign.center),
            Text(unit, style: text.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.analysis});

  final MriAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = analysis.prediction.followUpColor;
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
                  Text(
                    Formatters.shortDate(analysis.date),
                    style: text.labelSmall?.copyWith(color: ModuleColors.medical),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Stade ${analysis.prediction.shortLabel}',
                          style: text.titleSmall?.copyWith(color: color),
                        ),
                        TextSpan(
                          text: '  · confiance ${analysis.confidence.toStringAsFixed(1)} %',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text('Risque : ${analysis.riskLevel.label}', style: text.bodySmall),
                  if (analysis.description.isNotEmpty) Text(analysis.description, style: text.bodySmall),
                  if (analysis.doctorAdvice != null)
                    Text(
                      'Conseil du médecin : ${analysis.doctorAdvice}',
                      style: text.bodySmall?.copyWith(color: AppColors.textMain),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
