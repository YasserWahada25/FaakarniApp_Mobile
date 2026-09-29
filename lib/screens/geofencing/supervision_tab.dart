import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/geofencing.dart';
import '../../models/user.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/app_map.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/geofencing/geo_widgets.dart';

/// Web `supervision/supervision-dashboard.component`.
class SupervisionTab extends StatelessWidget {
  const SupervisionTab({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) =>
      role == UserRole.patient ? const _PatientDashboard() : const _CaregiverDashboard();
}

// ─── Caregiver: Supervision & Statistics ───────────────────────────────────

class _CaregiverDashboard extends StatefulWidget {
  const _CaregiverDashboard();

  @override
  State<_CaregiverDashboard> createState() => _CaregiverDashboardState();
}

enum _SupervisionView { overview, patients }

class _CaregiverDashboardState extends State<_CaregiverDashboard> {
  // Filled by the supervision API.
  final List<PatientStat> _patientStats = [];
  final List<GeoAlert> _alerts = [];
  final List<SafeZone> _zones = [];

  _SupervisionView _view = _SupervisionView.overview;

  void _exportReport() {}

  List<DailyCount> get _last7Days {
    final today = DateTime.now().dateOnly;
    return [
      for (var i = 6; i >= 0; i--)
        DailyCount(
          Formatters.day(today.subtract(Duration(days: i))),
          _alerts.where((a) => a.timestamp.isSameDay(today.subtract(Duration(days: i)))).length,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final active = _alerts.where((a) => a.isActive).length;
    final last24h = _alerts.where((a) => DateTime.now().difference(a.timestamp).inHours < 24).length;
    final online = _patientStats.where((p) => p.patient.isOnline).length;
    return ListView(
      padding: AppSpacing.screen,
      children: [
        PageIntro(
          title: 'Supervision & Statistics',
          subtitle: 'Mise à jour automatique toutes les 30s',
          trailing: IconButton.filledTonal(
            tooltip: 'Export PDF',
            onPressed: _exportReport,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ),
        StatGrid(children: [
          StatCard(label: 'Zones actives', value: '${_zones.length}', icon: Icons.map_outlined, iconColor: GeoColors.safe),
          StatCard(label: 'Patients en ligne', value: '$online', icon: Icons.wifi_rounded, iconColor: GeoColors.ok),
          StatCard(label: 'Alertes actives', value: '$active', icon: Icons.warning_amber_rounded, iconColor: GeoColors.warning),
          StatCard(label: 'Alertes (24h)', value: '$last24h', icon: Icons.event_outlined, iconColor: GeoColors.purple),
        ]),
        const SizedBox(height: AppSpacing.lg),
        SegmentedButton<_SupervisionView>(
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(value: _SupervisionView.overview, icon: Icon(Icons.insights_rounded), label: Text('Vue globale')),
            ButtonSegment(
              value: _SupervisionView.patients,
              icon: const Icon(Icons.group_outlined),
              label: Text('Patients (${_patientStats.length})'),
            ),
          ],
          selected: {_view},
          onSelectionChanged: (s) => setState(() => _view = s.first),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_view == _SupervisionView.overview) ..._overview(text) else ..._patients(),
      ],
    );
  }

  List<Widget> _overview(TextTheme text) {
    final byType = {for (final k in AlertKind.values) k: _alerts.where((a) => a.kind == k).length}
      ..removeWhere((_, v) => v == 0);
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Alertes par Type', style: text.titleSmall),
            const SizedBox(height: AppSpacing.md),
            if (byType.isEmpty)
              const EmptyStateView(compact: true, icon: Icons.inbox_outlined, title: 'Aucune alerte')
            else
              for (final e in byType.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(width: AppSizes.labelColumn, child: Text(e.key.code, style: text.bodySmall)),
                      Expanded(child: ProgressTrack(value: e.value / _alerts.length)),
                      const SizedBox(width: AppSpacing.sm),
                      Text('${e.value} · ${(e.value * 100 / _alerts.length).round()}%', style: text.labelSmall),
                    ],
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Alertes — 7 derniers jours', style: text.titleSmall),
            const SizedBox(height: AppSpacing.md),
            SimpleBarChart(
              bars: [for (final d in _last7Days) ChartBar(label: d.label, value: d.count.toDouble())],
              maxValue: _last7Days.fold<int>(1, (m, d) => d.count > m ? d.count : m).toDouble(),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const SectionHeader(title: 'Zone Safety Analysis', icon: Icons.shield_outlined),
      if (_patientStats.isEmpty)
        const EmptyStateView(compact: true, icon: Icons.group_off_outlined, title: 'Aucun patient lié.')
      else
        for (final ps in _patientStats)
          Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _ZoneSafetyRow(stat: ps)),
    ];
  }

  List<Widget> _patients() {
    if (_patientStats.isEmpty) {
      return const [
        EmptyStateView(
          icon: Icons.group_outlined,
          title: 'Aucun patient lié.',
          message: 'Créez une zone dans Live Tracking.',
        ),
      ];
    }
    return [
      for (final ps in _patientStats)
        Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _PatientStatCard(stat: ps)),
    ];
  }
}

class _ZoneSafetyRow extends StatelessWidget {
  const _ZoneSafetyRow({required this.stat});

  final PatientStat stat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bg, fg) = stat.status.colors;
    final zone = stat.zone;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(zone?.nomZone ?? '—', style: text.titleSmall)),
              if (zone != null)
                AppChip(label: zone.type.code, background: zone.type.background, foreground: zone.type.color, dense: true),
              const SizedBox(width: AppSpacing.xs),
              AppChip(label: stat.status.label, background: bg, foreground: fg, dense: true),
            ],
          ),
          Text(stat.patient.fullName, style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: ProgressTrack(value: stat.safetyScore / 100, color: safetyScoreColor(stat.safetyScore))),
              const SizedBox(width: AppSpacing.sm),
              Text('${stat.safetyScore}%', style: text.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientStatCard extends StatelessWidget {
  const _PatientStatCard({required this.stat});

  final PatientStat stat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bg, fg) = stat.status.colors;
    Widget cell(String label, String value, [Color? color]) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall?.copyWith(color: GeoColors.muted)),
              Text(value, style: text.titleSmall?.copyWith(color: color)),
            ],
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(initials: stat.patient.initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat.patient.fullName, style: text.titleSmall),
                    Text(stat.patient.email, style: text.bodySmall),
                  ],
                ),
              ),
              AppChip(label: stat.status.label, background: bg, foreground: fg, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            cell('Zone', stat.zone?.nomZone ?? '—'),
            cell('Alertes totales', '${stat.totalAlerts}'),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            cell('Alertes actives', '${stat.activeAlerts}', stat.activeAlerts > 0 ? GeoColors.danger : GeoColors.ok),
            cell('Dernière position', Formatters.relative(stat.patient.lastSeen)),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('Score sécurité', style: text.labelSmall?.copyWith(color: GeoColors.muted)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: ProgressTrack(value: stat.safetyScore / 100, color: safetyScoreColor(stat.safetyScore))),
              const SizedBox(width: AppSpacing.sm),
              Text('${stat.safetyScore}%', style: text.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Patient: Mon Espace Santé ─────────────────────────────────────────────

class _PatientDashboard extends StatefulWidget {
  const _PatientDashboard();

  @override
  State<_PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<_PatientDashboard> {
  // Filled by the geofencing API.
  final List<GeoAlert> _alerts = [];
  SafeZone? _zone;

  Future<void> _load() async {}

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final active = _alerts.where((a) => a.isActive).length;
    final score = _alerts.isEmpty ? 100 : (100 - active * 25).clamp(0, 100);
    final scoreColor = safetyScoreColor(score);
    final zone = _zone;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          const PageIntro(title: 'Mon Espace Santé', subtitle: 'Voici votre tableau de bord'),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: AppSizes.avatarXl,
                  height: AppSizes.avatarXl,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scoreColor, width: 5)),
                  child: Text('$score%', style: text.titleLarge?.copyWith(color: scoreColor)),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score Sécurité', style: text.titleMedium),
                      Text(
                        score >= 80 ? '✅ Excellent' : (score >= 50 ? '⚠️ Attention' : '🚨 Critique'),
                        style: text.bodyMedium?.copyWith(color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Alertes totales', value: '${_alerts.length}', icon: Icons.notifications_outlined)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  label: 'Actives',
                  value: '$active',
                  icon: Icons.warning_amber_rounded,
                  iconColor: GeoColors.danger,
                  valueColor: active > 0 ? GeoColors.danger : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  label: 'Résolues',
                  value: '${_alerts.length - active}',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: GeoColors.ok,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Ma Zone de Sécurité',
                  icon: Icons.map_outlined,
                  trailing: zone == null
                      ? const AppChip(label: 'Aucune zone', background: AppColors.borderLight, foreground: GeoColors.muted)
                      : AppChip(label: zone.nomZone, background: zone.type.background, foreground: zone.type.color),
                ),
                AppMap(
                  center: zone == null ? AppConstants.defaultMapCenter : LatLng(zone.centreLat, zone.centreLon),
                  zones: [
                    if (zone != null)
                      MapZone(
                        center: LatLng(zone.centreLat, zone.centreLon),
                        radiusMeters: zone.rayon.toDouble(),
                        color: zone.type.color,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (zone == null)
                  Text("Votre soignant n'a pas encore configuré de zone.", style: text.bodySmall)
                else
                  Text('${zone.type.code} · ${zone.rayon}m · ${Formatters.coordinate(zone.centreLat, 4)}, '
                      '${Formatters.coordinate(zone.centreLon, 4)}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: active == 0 ? GeoColors.okBg : GeoColors.dangerBg,
            child: Row(
              children: [
                Icon(
                  active == 0 ? Icons.shield_outlined : Icons.warning_amber_rounded,
                  size: AppSizes.iconXl * 0.8,
                  color: active == 0 ? GeoColors.ok : GeoColors.danger,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active == 0 ? 'Vous êtes en sécurité' : 'Alerte en cours !', style: text.titleMedium),
                      Text(
                        active == 0
                            ? 'Votre position est dans votre zone.'
                            : '$active alerte(s) — votre soignant est notifié.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Historique des Alertes', icon: Icons.list_alt_rounded),
          if (_alerts.isEmpty)
            const EmptyStateView(compact: true, icon: Icons.celebration_outlined, title: 'Aucune alerte — continuez comme ça !')
          else
            for (final a in _alerts.take(5))
              Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: AlertTile(alert: a)),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 Conseils', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(active == 0 ? '✅ Restez dans votre zone de sécurité.' : '⚠️ Retournez dans votre zone ou appuyez sur SOS.'),
                const Text('📱 Gardez votre téléphone chargé.'),
                const Text('🆘 En urgence, utilisez le bouton SOS dans Live Tracking.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
