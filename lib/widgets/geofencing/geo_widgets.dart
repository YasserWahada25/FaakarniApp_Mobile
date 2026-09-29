import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/geofencing.dart';
import '../common/app_card.dart';
import '../common/app_chip.dart';

extension ZoneTypeStyle on ZoneType {
  Color get color => this == ZoneType.safe ? GeoColors.safe : GeoColors.danger;
  Color get background => this == ZoneType.safe ? GeoColors.safeBg : GeoColors.dangerBg;
}

extension AlertSeverityStyle on AlertSeverity {
  (Color, Color) get colors => switch (this) {
        AlertSeverity.high => (GeoColors.dangerBg, GeoColors.danger),
        AlertSeverity.medium => (GeoColors.warningBg, GeoColors.warning),
        AlertSeverity.low => (GeoColors.okBg, GeoColors.ok),
      };
}

extension PatientSafetyStatusStyle on PatientSafetyStatus {
  (Color, Color) get colors => switch (this) {
        PatientSafetyStatus.safe => (GeoColors.okBg, GeoColors.ok),
        PatientSafetyStatus.alert => (GeoColors.dangerBg, GeoColors.danger),
        PatientSafetyStatus.offline => (AppColors.borderLight, GeoColors.muted),
      };
}

/// Safety score color (supervision `scoreColor`).
Color safetyScoreColor(int score) => score >= 80
    ? GeoColors.ok
    : score >= 50
        ? GeoColors.warning
        : GeoColors.danger;

/// Zone card of the "Configured Zones" list.
class ZoneCard extends StatelessWidget {
  const ZoneCard({super.key, required this.zone, required this.onTap, required this.onEdit, required this.onDelete});

  final SafeZone zone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      accentColor: zone.type.color,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.nomZone, style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppChip(label: zone.type.code, background: zone.type.background, foreground: zone.type.color, dense: true),
                    Text('Patient: ${zone.patientName}', style: text.bodySmall),
                    Text('⭕ ${zone.rayon}m', style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          IconButton(tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: GeoColors.danger),
          ),
        ],
      ),
    );
  }
}

/// Mobile card version of an alerts-table row.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, this.onResolve});

  final GeoAlert alert;

  /// `null` hides the action (patients cannot resolve alerts).
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (sevBg, sevFg) = alert.severity.colors;
    return AppCard(
      accentColor: alert.isActive ? GeoColors.danger : GeoColors.ok,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppChip(
                      label: alert.status.label,
                      background: alert.isActive ? GeoColors.dangerBg : GeoColors.okBg,
                      foreground: alert.isActive ? GeoColors.danger : GeoColors.ok,
                      dense: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: AppChip(label: alert.kind.code, background: sevBg, foreground: sevFg, dense: true)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(alert.patientName, style: text.titleSmall),
                Text(Formatters.medium(alert.timestamp), style: text.bodySmall),
              ],
            ),
          ),
          if (onResolve != null)
            alert.isActive
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: GeoColors.ok,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),
                    onPressed: onResolve,
                    icon: const Icon(Icons.check_rounded, size: AppSizes.iconMd),
                    label: const Text('Resolve'),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all_rounded, color: GeoColors.ok, size: AppSizes.iconMd),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Done', style: text.labelMedium?.copyWith(color: GeoColors.ok)),
                    ],
                  ),
        ],
      ),
    );
  }
}

/// Legend under the live-tracking map.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget item(Color color, String label, {bool ring = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.dot + 4,
              height: AppSizes.dot + 4,
              decoration: BoxDecoration(
                color: ring ? AppColors.transparent : color,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: style),
          ],
        );
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        item(GeoColors.safe, 'Safe Zone', ring: true),
        item(GeoColors.danger, 'Danger Zone', ring: true),
        item(GeoColors.ok, 'Patient — OK'),
        item(GeoColors.danger, 'Patient — Alert'),
      ],
    );
  }
}
