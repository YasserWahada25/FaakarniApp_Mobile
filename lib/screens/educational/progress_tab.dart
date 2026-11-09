import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/educational.dart';
import '../../services/educational_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/state_views.dart';

/// Web `tracking/tracking.component` ("Your Progress").
class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  LearningProgress? _progress;
  ViewStatus _status = ViewStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final progress = await EducationalService.instance.getProgress();
      if (!mounted) return;
      setState(() {
        _progress = progress;
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = _progress;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, color: AppColors.heading),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text('Your Progress', style: text.headlineSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_status == ViewStatus.loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_status == ViewStatus.error && p == null) ...[
            ErrorStateView(message: _error ?? 'Impossible de charger la progression.', onRetry: _load),
            const SizedBox(height: AppSpacing.md),
          ],
          StatCard(
            label: 'Activities Done',
            value: '${p?.completedActivities ?? 0}',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Total Time', value: p?.totalTime ?? '—', icon: Icons.timer_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  label: 'Average Score',
                  value: p == null ? '—' : '${p.averageScore}%',
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Performance History', icon: Icons.bar_chart_rounded),
                if (p == null || p.history.isEmpty)
                  const EmptyStateView(
                    compact: true,
                    icon: Icons.bar_chart_rounded,
                    title: 'Aucune donnée',
                    message: 'Jouez à une activité pour suivre votre progression.',
                  )
                else
                  SimpleBarChart(
                    maxValue: 100,
                    valueSuffix: '%',
                    bars: [
                      for (var i = 0; i < p.history.length; i++)
                        ChartBar(label: '#${i + 1}', value: p.history[i].toDouble()),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
