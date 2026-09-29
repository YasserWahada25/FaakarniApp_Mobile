import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// A zone drawn on the map (geofencing circles).
class MapZone {
  const MapZone({required this.center, required this.radiusMeters, required this.color, this.dashed = false});

  final LatLng center;
  final double radiusMeters;
  final Color color;
  final bool dashed;
}

/// A pin drawn on the map.
class MapPin {
  const MapPin({required this.point, required this.color, this.icon = Icons.location_on_rounded, this.label});

  final LatLng point;
  final Color color;
  final IconData icon;
  final String? label;
}

/// Map with the same Esri tiles as the web Leaflet maps.
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    this.center = AppConstants.defaultMapCenter,
    this.zoom = AppConstants.defaultMapZoom,
    this.zones = const [],
    this.pins = const [],
    this.onTap,
    this.height = AppSizes.mapHeight,
    this.controller,
  });

  final LatLng center;
  final double zoom;
  final List<MapZone> zones;
  final List<MapPin> pins;
  final ValueChanged<LatLng>? onTap;
  final double height;
  final MapController? controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        height: height,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            onTap: onTap == null ? null : (_, point) => onTap!(point),
          ),
          children: [
            TileLayer(urlTemplate: AppConstants.mapTileUrl, userAgentPackageName: AppConstants.mapUserAgent),
            if (zones.isNotEmpty)
              CircleLayer(
                circles: [
                  for (final z in zones)
                    CircleMarker(
                      point: z.center,
                      radius: z.radiusMeters,
                      useRadiusInMeter: true,
                      color: z.color.withValues(alpha: 0.15),
                      borderColor: z.color,
                      borderStrokeWidth: z.dashed ? 1.5 : 2,
                    ),
                ],
              ),
            if (pins.isNotEmpty)
              MarkerLayer(
                markers: [
                  for (final p in pins)
                    Marker(
                      point: p.point,
                      width: AppSizes.iconXl,
                      height: AppSizes.iconXl,
                      alignment: Alignment.topCenter,
                      child: Tooltip(
                        message: p.label ?? '',
                        child: Icon(p.icon, color: p.color, size: AppSizes.iconXl * 0.8),
                      ),
                    ),
                ],
              ),
            const RichAttributionWidget(
              showFlutterMapAttribution: false,
              popupBackgroundColor: AppColors.white,
              attributions: [TextSourceAttribution(AppConstants.mapAttribution, prependCopyright: false)],
            ),
          ],
        ),
      ),
    );
  }
}
