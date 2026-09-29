import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/session.dart';
import '../common/app_card.dart';
import '../common/app_chip.dart';
import 'session_styles.dart';

/// Session card of the "Sessions planifiees" day list (web `.day-session-card`).
class DaySessionCard extends StatelessWidget {
  const DaySessionCard({super.key, required this.session, required this.onTap, this.onToggleFavorite});

  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final type = session.type.colors;
    final status = session.status.plannedColors;
    return AppCard(
      onTap: onTap,
      accentColor: type.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppChip(label: session.type.label, background: type.background, foreground: type.foreground, uppercase: true),
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: session.status.plannedLabel,
                background: status.background,
                foreground: status.foreground,
                border: status.accent,
              ),
              const Spacer(),
              if (onToggleFavorite != null)
                IconButton(
                  tooltip: session.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    session.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: SessionColors.favorite,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(session.title, style: text.titleMedium?.copyWith(color: AppColors.textInk)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            session.description.isEmpty ? 'Aucune description disponible.' : session.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(icon: Icons.schedule_rounded, label: Formatters.time(session.start)),
              _Meta(icon: Icons.group_outlined, label: '${session.participants} participants'),
              _Meta(
                icon: session.isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
                label: session.mode.label,
              ),
              _Meta(icon: Icons.visibility_outlined, label: session.visibility.label),
            ],
          ),
        ],
      ),
    );
  }
}

/// Favorite card (web `.fav-card`).
class FavoriteSessionCard extends StatelessWidget {
  const FavoriteSessionCard({super.key, required this.session, required this.onRemove, required this.onJoin});

  final Session session;
  final VoidCallback onRemove;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final type = session.type.colors;
    return AppCard(
      accentColor: type.accent,
      accentOnTop: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppChip(label: session.type.label, background: type.background, foreground: type.foreground, uppercase: true),
              const Spacer(),
              IconButton(
                tooltip: 'Remove from favorites',
                onPressed: onRemove,
                icon: const Icon(Icons.star_rounded, color: SessionColors.favorite),
              ),
            ],
          ),
          Text(session.title, style: text.titleMedium?.copyWith(color: AppColors.textInk)),
          const SizedBox(height: AppSpacing.sm),
          _Meta(icon: Icons.calendar_today_outlined, label: Formatters.fullDate(session.start)),
          const SizedBox(height: AppSpacing.xxs),
          _Meta(icon: Icons.schedule_rounded, label: Formatters.timeRange(session.start, session.end)),
          if (session.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(session.description, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: session.isOnline ? AppGradients.alzheimer : null,
              color: session.isOnline ? null : AppColors.borderLight,
              borderRadius: AppRadius.pillAll,
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.transparent,
                disabledBackgroundColor: AppColors.transparent,
                disabledForegroundColor: AppColors.textSecondary,
                minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
              ),
              onPressed: session.isOnline ? onJoin : null,
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reservation request card (web reservations `.session-card`).
class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = session.status.reservationColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                decoration: BoxDecoration(
                  color: session.isOnline ? SessionColors.cognitiveBg : SessionColors.physicalBg,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  session.isOnline ? Icons.videocam_outlined : Icons.person_pin_circle_outlined,
                  color: session.isOnline ? SessionColors.cognitiveFg : SessionColors.physicalFg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: text.titleSmall?.copyWith(color: SessionColors.reservationTitle)),
                    Text(Formatters.timeRange(session.start, session.end), style: text.bodySmall),
                  ],
                ),
              ),
              AppChip(label: session.status.label, background: status.background, foreground: status.foreground),
            ],
          ),
          if (session.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(session.description, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(
                icon: session.isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
                label: session.mode == SessionMode.online ? 'En ligne' : 'Présentielle',
                background: AppColors.bgMain,
                foreground: AppColors.primaryDark,
              ),
              AppChip(
                icon: Icons.group_outlined,
                label: session.audience.label,
                background: AppColors.bgMain,
                foreground: AppColors.primaryDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}
