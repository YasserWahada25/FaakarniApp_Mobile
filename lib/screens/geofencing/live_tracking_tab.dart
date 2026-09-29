import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/geofencing.dart';
import '../../models/user.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/app_map.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/geofencing/geo_widgets.dart';

/// Web `live-tracking/live-tracking.component`.
class LiveTrackingTab extends StatelessWidget {
  const LiveTrackingTab({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) =>
      role == UserRole.patient ? const _PatientTracking() : const _CaregiverTracking();
}

// ─── Caregiver view ────────────────────────────────────────────────────────

class _CaregiverTracking extends StatefulWidget {
  const _CaregiverTracking();

  @override
  State<_CaregiverTracking> createState() => _CaregiverTrackingState();
}

class _CaregiverTrackingState extends State<_CaregiverTracking> {
  // Filled by the geofencing API.
  final List<SafeZone> _zones = [];
  final List<GeoAlert> _activeAlerts = [];
  final List<MonitoredPatient> _patients = [];

  final _mapController = MapController();

  Future<void> _load() async {}

  void _resolveAlert(GeoAlert alert) {}

  Future<void> _deleteZone(SafeZone zone) async {
    await showConfirmDialog(
      context,
      title: 'Delete zone',
      message: 'Delete "${zone.nomZone}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          PageIntro(
            title: 'Live Tracking',
            subtitle: 'Real-time monitoring & zone management',
            trailing: FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
              onPressed: () => context.push(AppRoutes.zoneNew),
              icon: const Icon(Icons.add),
              label: const Text('Add Zone'),
            ),
          ),
          for (final a in _activeAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: GeoColors.dangerBg, borderRadius: AppRadius.mdAll),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: GeoColors.danger),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${a.patientName} — ${a.kind.code} · ${a.distanceHorsZone.toStringAsFixed(0)}m outside zone',
                        style: text.bodySmall?.copyWith(color: GeoColors.danger),
                      ),
                    ),
                    TextButton(onPressed: () => _resolveAlert(a), child: const Text('✓ Resolve')),
                  ],
                ),
              ),
            ),
          AppMap(
            controller: _mapController,
            height: AppSizes.mapHeightLg,
            zones: [
              for (final z in _zones)
                MapZone(
                  center: LatLng(z.centreLat, z.centreLon),
                  radiusMeters: z.rayon.toDouble(),
                  color: z.type.color,
                  dashed: z.type == ZoneType.danger,
                ),
            ],
            pins: [
              for (final p in _patients)
                MapPin(
                  point: LatLng(p.latitude, p.longitude),
                  color: _activeAlerts.any((a) => a.patientName == p.fullName) ? GeoColors.danger : GeoColors.ok,
                  icon: Icons.person_pin_circle_rounded,
                  label: p.fullName,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const MapLegend(),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Configured Zones',
            icon: Icons.place_outlined,
            trailing: AppChip(label: '${_zones.length}', background: AppColors.bgSecondary, foreground: AppColors.primaryDark),
          ),
          if (_zones.isEmpty)
            const EmptyStateView(
              compact: true,
              icon: Icons.map_outlined,
              title: 'No zones configured',
              message: 'Tap "Add Zone" to get started.',
            )
          else
            for (final z in _zones)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ZoneCard(
                  zone: z,
                  onTap: () => _mapController.move(LatLng(z.centreLat, z.centreLon), 15),
                  onEdit: () => context.push(AppRoutes.zoneEdit, extra: z),
                  onDelete: () => _deleteZone(z),
                ),
              ),
        ],
      ),
    );
  }
}

// ─── Patient view ──────────────────────────────────────────────────────────

class _PatientTracking extends StatefulWidget {
  const _PatientTracking();

  @override
  State<_PatientTracking> createState() => _PatientTrackingState();
}

class _PatientTrackingState extends State<_PatientTracking> {
  // Filled by the device location + geofencing API.
  final GpsStatus _gps = GpsStatus.requesting;
  LatLng? _position;
  final double _accuracy = 0;
  SafeZone? _zone;
  final List<GeoAlert> _alerts = [];

  void _triggerSos() {}

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final zone = _zone;
    final position = _position;
    return ListView(
      padding: AppSpacing.screen,
      children: [
        _GpsBanner(status: _gps, position: position, accuracy: _accuracy),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'My Location',
                icon: Icons.place_outlined,
                trailing: zone == null
                    ? Text('ℹ️ No zone configured', style: text.bodySmall)
                    : AppChip(
                        label: '${zone.nomZone} — ${zone.rayon}m',
                        background: zone.type.background,
                        foreground: zone.type.color,
                      ),
              ),
              AppMap(
                center: position ?? AppConstants.defaultMapCenter,
                zones: [
                  if (zone != null)
                    MapZone(
                      center: LatLng(zone.centreLat, zone.centreLon),
                      radiusMeters: zone.rayon.toDouble(),
                      color: zone.type.color,
                    ),
                ],
                pins: [if (position != null) MapPin(point: position, color: GeoColors.safe, icon: Icons.my_location_rounded)],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (position != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Position', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(label: 'Latitude', value: Formatters.coordinate(position.latitude)),
                _InfoRow(label: 'Longitude', value: Formatters.coordinate(position.longitude)),
                if (zone != null) _InfoRow(label: 'Zone', value: zone.nomZone),
              ],
            ),
          ),
        if (_alerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          for (final a in _alerts) AlertTile(alert: a),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: AppSizes.sosButtonHeight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: GeoColors.sos,
              textStyle: text.headlineSmall?.copyWith(color: AppColors.white),
            ),
            onPressed: _gps == GpsStatus.active && zone?.soignantId != null ? _triggerSos : null,
            icon: const Icon(Icons.sos_rounded, size: AppSizes.iconLg),
            label: const Text('SOS'),
          ),
        ),
        if (_gps != GpsStatus.active) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Enable location to use the SOS button', style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _GpsBanner extends StatelessWidget {
  const _GpsBanner({required this.status, required this.position, required this.accuracy});

  final GpsStatus status;
  final LatLng? position;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      GpsStatus.requesting => (GeoColors.warningBg, GeoColors.warning, Icons.gps_not_fixed_rounded, 'Activating location…'),
      GpsStatus.denied => (
          GeoColors.dangerBg,
          GeoColors.danger,
          Icons.location_disabled_rounded,
          'Location denied — please enable it in your settings.'
        ),
      GpsStatus.active => (
          GeoColors.okBg,
          GeoColors.ok,
          Icons.gps_fixed_rounded,
          'Location active — your caregiver is tracking you in real time'
        ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg)),
                if (status == GpsStatus.active && position != null)
                  Text(
                    '${Formatters.coordinate(position!.latitude)}, ${Formatters.coordinate(position!.longitude)} (± ${accuracy.toStringAsFixed(0)}m)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodySmall)),
          Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
