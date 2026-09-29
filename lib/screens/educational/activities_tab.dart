import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/educational.dart';
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
  // Filled by the activities API.
  final List<EducationalActivity> _activities = [];
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
                onPlay: () => context.push(AppRoutes.activityPlay(_activities[i].id), extra: _activities[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
