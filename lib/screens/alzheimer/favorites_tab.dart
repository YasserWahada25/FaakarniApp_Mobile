import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/session.dart';
import '../../widgets/alzheimer/session_card.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';

/// Web `consultation/favorites.component`.
class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  // Filled by the sessions API (sessions flagged as favorite).
  final List<Session> _favorites = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _removeFavorite(Session session) {}

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          PageIntro(
            title: 'My Favorite Sessions',
            subtitle: 'Access your saved sessions quickly.',
            leading: Container(
              width: AppSizes.avatar + 4,
              height: AppSizes.avatar + 4,
              decoration: const BoxDecoration(gradient: AppGradients.favorite, borderRadius: AppRadius.mdAll),
              child: const Icon(Icons.star_rounded, color: AppColors.white),
            ),
          ),
          AsyncStateView(
            status: _status,
            isEmpty: _favorites.isEmpty,
            errorMessage: _error,
            onRetry: _load,
            loading: const LoadingView(message: 'Loading your favorites...'),
            empty: EmptyStateView(
              icon: Icons.star_border_rounded,
              title: 'No Favorites Yet',
              message: "Visit the calendar and click the star icon on sessions you'd like to save here.",
              actionLabel: 'Go to Calendar',
              actionIcon: Icons.calendar_today_outlined,
              onAction: () => context.go(AppRoutes.withTab(AppRoutes.alzheimer, 'consultation')),
            ),
            builder: (context) => Column(
              children: [
                for (final s in _favorites)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: FavoriteSessionCard(
                      session: s,
                      onRemove: () => _removeFavorite(s),
                      onJoin: () => context.push(AppRoutes.meeting(s.id)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
