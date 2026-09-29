import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/educational.dart';
import '../../widgets/common/app_map.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/educational/activity_widgets.dart';

/// Web `events/events.component` ("Événements éducatifs").
class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  // Filled by the events API.
  final List<EducationalEvent> _events = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  /// Web `MapModalComponent`.
  void _openMap(EducationalEvent event) {
    final point = LatLng(event.latitude, event.longitude);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
              Text(event.location, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              AppMap(
                center: point,
                zoom: 15,
                height: AppSizes.mapHeightLg,
                pins: [MapPin(point: point, color: AppColors.primaryDark, label: event.location)],
              ),
            ],
          ),
        ),
      ),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Événements éducatifs', style: text.headlineSmall?.copyWith(color: EduColors.title)),
                    Text('Ateliers et rencontres à venir', style: text.bodyMedium?.copyWith(color: EduColors.subtitle)),
                  ],
                ),
              ),
              if (_events.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: AppDecorations.pill(EduColors.thumbBg),
                  child: Text(
                    '${_events.length} événement${_events.length > 1 ? 's' : ''}',
                    style: text.labelMedium?.copyWith(color: EduColors.title),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AsyncStateView(
            status: _status,
            isEmpty: _events.isEmpty,
            errorMessage: _error ?? 'Impossible de charger les événements. Vérifiez que le serveur est démarré.',
            onRetry: _load,
            loading: const SkeletonList(itemHeight: 220),
            empty: const EmptyStateView(
              icon: Icons.event_outlined,
              title: 'Aucun événement disponible pour le moment.',
            ),
            builder: (context) => Column(
              children: [
                for (final e in _events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: EventCard(event: e, onLocate: () => _openMap(e)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
