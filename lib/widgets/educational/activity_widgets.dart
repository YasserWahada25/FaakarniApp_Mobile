import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/educational.dart';
import '../common/app_chip.dart';

extension ActivityTypeStyle on ActivityType {
  /// Badge colors (activities-list.component.css `.badge-*`).
  (Color, Color) get badge => switch (this) {
        ActivityType.quiz => (EduColors.quizBadgeBg, EduColors.quizBadgeFg),
        ActivityType.cognitiveGame => (EduColors.cognitiveBadgeBg, EduColors.cognitiveBadgeFg),
        ActivityType.imageGame || ActivityType.puzzleGame => (EduColors.memoryBadgeBg, EduColors.memoryBadgeFg),
        ActivityType.video => (EduColors.videoBadgeBg, EduColors.videoBadgeFg),
        ActivityType.content => (EduColors.contentBadgeBg, EduColors.contentBadgeFg),
      };

  /// Thumbnail gradient (assets/games/*.svg).
  List<Color> get thumbColors => switch (this) {
        ActivityType.quiz => const [EduColors.thumbQuiz, EduColors.thumbQuiz],
        ActivityType.cognitiveGame => const [EduColors.thumbImage, EduColors.thumbImage2],
        ActivityType.imageGame || ActivityType.puzzleGame => const [EduColors.thumbMemory, EduColors.thumbMemory],
        ActivityType.video => const [EduColors.thumbVideo, EduColors.thumbVideo],
        ActivityType.content => const [EduColors.thumbContent, EduColors.thumbContent],
      };

  IconData get icon => switch (this) {
        ActivityType.quiz => Icons.quiz_outlined,
        ActivityType.cognitiveGame => Icons.image_search_outlined,
        ActivityType.imageGame => Icons.grid_view_rounded,
        ActivityType.puzzleGame => Icons.extension_outlined,
        ActivityType.video => Icons.play_circle_outline_rounded,
        ActivityType.content => Icons.menu_book_outlined,
      };
}

/// Game thumbnail (native version of the web SVG catalogue).
class ActivityThumbnail extends StatelessWidget {
  const ActivityThumbnail({super.key, required this.type, this.height = AppSizes.thumbHeight});

  final ActivityType type;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = type.thumbColors;
    return Container(
      height: height,
      decoration: BoxDecoration(gradient: AppGradients.diagonal(colors.first, colors.last)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(type.icon, size: height * 0.8, color: AppColors.white.withValues(alpha: 0.12)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, color: AppColors.white, size: AppSizes.iconLg),
              const SizedBox(height: AppSpacing.xs),
              Text(type.thumbLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Activity card of the catalogue grid (web `.friv-card`).
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.onPlay});

  final EducationalActivity activity;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bg, fg) = activity.type.badge;
    final description = activity.description.length > 96 ? '${activity.description.substring(0, 96)}…' : activity.description;
    return Material(
      color: AppColors.white,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Ink(
          decoration: AppDecorations.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActivityThumbnail(type: activity.type, height: AppSizes.coverSm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppChip(label: activity.type.label, background: bg, foreground: fg, dense: true),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        activity.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(color: EduColors.title),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Expanded(
                        child: Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                      ),
                      Row(
                        children: [
                          if (activity.lastScore != null)
                            Text('Score ${activity.lastScore}%', style: text.labelSmall?.copyWith(color: EduColors.subtitle)),
                          const Spacer(),
                          Icon(Icons.play_circle_fill_rounded, color: EduColors.play, size: AppSizes.iconLg),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Event card (web `events.component` `.event-card`).
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onLocate});

  final EducationalEvent event;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cover = EduColors.eventCovers[event.coverIndex % EduColors.eventCovers.length];
    final start = event.startDateTime;
    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: AppSizes.coverHeight - 30,
            decoration: BoxDecoration(gradient: AppGradients.diagonal(cover.first, cover.last)),
            padding: const EdgeInsets.all(AppSpacing.md),
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: const BoxDecoration(color: AppColors.white, borderRadius: AppRadius.mdAll),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(start == null ? '—' : Formatters.day(start), style: text.titleLarge?.copyWith(color: cover.first, height: 1)),
                  Text(start == null ? 'À venir' : Formatters.monthShort(start), style: text.labelSmall),
                  if (start != null) Text(Formatters.time(start), style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(event.title, style: text.titleMedium?.copyWith(color: EduColors.title))),
                    if (event.remindEnabled)
                      const AppChip(
                        icon: Icons.notifications_active_outlined,
                        label: 'Rappel',
                        background: SessionColors.pendingBg,
                        foreground: SessionColors.pendingFg,
                        dense: true,
                      ),
                  ],
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: AppSizes.iconSm, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(event.location, style: text.bodySmall)),
                      TextButton.icon(
                        onPressed: onLocate,
                        icon: const Icon(Icons.map_outlined, size: AppSizes.iconMd),
                        label: const Text('Localiser'),
                      ),
                    ],
                  ),
                ],
                if (event.description.isNotEmpty) Text(event.description, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
