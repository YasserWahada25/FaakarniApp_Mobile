import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/session.dart';
import '../../providers/sessions_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/alzheimer/month_calendar.dart';
import '../../widgets/alzheimer/session_card.dart';
import '../../widgets/alzheimer/session_detail_sheet.dart';
import '../../widgets/alzheimer/session_styles.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/state_views.dart';

enum _ModeFilter { all, online, inPerson }

/// Web `consultation/calendar.component`: planned sessions calendar.
class ConsultationTab extends StatefulWidget {
  const ConsultationTab({super.key});

  @override
  State<ConsultationTab> createState() => _ConsultationTabState();
}

class _ConsultationTabState extends State<ConsultationTab> {
  final _provider = SessionsProvider.instance;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  _ModeFilter _filter = _ModeFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(_provider.load);
  }

  Future<void> _toggleFavorite(Session session) async {
    try {
      await _provider.toggleFavorite(session);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    }
  }

  List<Session> get _planned => _provider.sessions.where((s) => s.status.isPlanned).toList();

  List<Session> get _visible => _planned.where((s) {
        return switch (_filter) {
          _ModeFilter.all => true,
          _ModeFilter.online => s.mode == SessionMode.online,
          _ModeFilter.inPerson => s.mode == SessionMode.inPerson,
        };
      }).toList();

  List<Session> _sessionsOn(DateTime day) => _visible.where((s) => s.start.isSameDay(day)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  String get _filterLabel => switch (_filter) {
        _ModeFilter.all => 'Les deux',
        _ModeFilter.online => 'En ligne',
        _ModeFilter.inPerson => 'Presentielle',
      };

  void _openDay(DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (context, controller) => ListenableBuilder(
          listenable: _provider,
          builder: (context, _) {
            final sessions = _sessionsOn(day);
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              children: [
                Text('Sessions planifiees', style: Theme.of(context).textTheme.headlineSmall),
                Text(Formatters.fullDate(day), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                if (sessions.isEmpty)
                  const EmptyStateView(
                    compact: true,
                    icon: Icons.event_busy_outlined,
                    title: 'Aucune session planifiee',
                    message: "Il n'y a pas de session acceptee ou planifiee pour ce jour.",
                  )
                else
                  for (final s in sessions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DaySessionCard(
                        session: s,
                        onToggleFavorite: () => _toggleFavorite(s),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openSession(s);
                        },
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openSession(Session session) {
    showSessionDetailSheet(
      context,
      session: session,
      onToggleFavorite: () => _toggleFavorite(session),
      onJoin: () => context.push(AppRoutes.meeting(session.id), extra: session.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final status = _provider.status;
        final planned = _planned;
        final inMonth = planned.where((s) => s.start.year == _month.year && s.start.month == _month.month);
        return RefreshIndicator(
          onRefresh: _provider.load,
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              StatGrid(children: [
                StatCard(label: 'Sessions planifiees', value: '${planned.length}', tint: SessionColors.statTotal),
                StatCard(
                  label: 'En ligne',
                  value: '${planned.where((s) => s.mode == SessionMode.online).length}',
                  tint: SessionColors.statOnline,
                ),
                StatCard(
                  label: 'Presentielle',
                  value: '${planned.where((s) => s.mode == SessionMode.inPerson).length}',
                  tint: SessionColors.statPresential,
                ),
                StatCard(label: 'Ce mois', value: '${inMonth.length}', tint: SessionColors.statMonth),
              ]),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDecorations.card(borderColor: AppColors.borderViolet, radius: AppRadius.mdAll),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Filtrer le calendrier', style: text.titleSmall)),
                        Text(_filterLabel, style: text.labelMedium?.copyWith(color: ModuleColors.alzheimer)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<_ModeFilter>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: _ModeFilter.all, label: Text('Les deux')),
                        ButtonSegment(value: _ModeFilter.online, label: Text('En ligne')),
                        ButtonSegment(value: _ModeFilter.inPerson, label: Text('Presentielle')),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) => setState(() => _filter = s.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AsyncStateView(
                status: status,
                isEmpty: false,
                errorMessage: _provider.error,
                onRetry: _provider.load,
                loading: const SkeletonList(itemCount: 1, itemHeight: 360),
                empty: const SizedBox.shrink(),
                builder: (context) => MonthCalendar(
                  month: _month,
                  onPreviousMonth: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  onNextMonth: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  dotsForDay: (day) => [for (final s in _sessionsOn(day)) s.type.colors.accent],
                  onDayTap: _openDay,
                ),
              ),
              if (status == ViewStatus.ready && planned.isEmpty)
                const EmptyStateView(
                  compact: true,
                  icon: Icons.event_note_outlined,
                  title: 'Aucune session planifiee',
                  message: 'Les séances acceptées apparaîtront dans ce calendrier.',
                ),
            ],
          ),
        );
      },
    );
  }
}
