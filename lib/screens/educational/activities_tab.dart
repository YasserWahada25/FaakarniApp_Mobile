import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/educational.dart';
import '../../services/educational_service.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/shimmer.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/educational/activity_widgets.dart';

/// Web `activities/activities-list.component` ("Jeux & activités").
class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  List<EducationalActivity> _activities = [];
  ViewStatus _status = ViewStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      if (_activities.isEmpty) _status = ViewStatus.loading;
      _error = null;
    });
    try {
      final list = await EducationalService.instance.getActivities();
      if (!mounted) return;
      setState(() {
        _activities = list;
        _status = ViewStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _status = ViewStatus.error;
      });
    }
  }

  /// Reloads the catalogue on return so the card shows the latest score.
  Future<void> _play(EducationalActivity activity) async {
    await context.push(AppRoutes.activityPlay(activity.id), extra: activity);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: AppSizes.gridItemMaxWidth,
      mainAxisExtent: AppSizes.activityCardHeight,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports_outlined, color: EduColors.title),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text('Jeux & activités', style: text.headlineSmall?.copyWith(color: EduColors.title))),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text('Choisissez une activité — images et quiz visuels.', style: text.bodyMedium?.copyWith(color: EduColors.subtitle)),
          const SizedBox(height: AppSpacing.lg),
          AsyncStateView(
            status: _status,
            isEmpty: _activities.isEmpty,
            errorMessage: _error ?? 'Impossible de charger les activités.',
            onRetry: _load,
            loading: Shimmer(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: gridDelegate,
                itemCount: 4,
                itemBuilder: (_, _) => const SkeletonBox(height: AppSizes.activityCardHeight),
              ),
            ),
            empty: const EmptyStateView(icon: Icons.sports_esports_outlined, title: 'Aucune activité à afficher.'),
            builder: (context) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: gridDelegate,
              itemCount: _activities.length,
              itemBuilder: (context, i) => ActivityCard(
                activity: _activities[i],
                onPlay: () => _play(_activities[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
