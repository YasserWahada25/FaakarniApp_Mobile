import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/session.dart';
import '../../providers/sessions_provider.dart';
import '../../widgets/alzheimer/month_calendar.dart';
import '../../widgets/alzheimer/session_card.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/state_views.dart';

/// Web `sessions/calendar-view.component`: the user's session requests.
class ReservationsTab extends StatefulWidget {
  const ReservationsTab({super.key});

  @override
  State<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<ReservationsTab> {
  final _provider = SessionsProvider.instance;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  Session? _lastCreated;

  @override
  void initState() {
    super.initState();
    _lastCreated = _provider.lastCreated;
    _provider.addListener(_showCreatedDay);
    Future.microtask(_provider.load);
  }

  @override
  void dispose() {
    _provider.removeListener(_showCreatedDay);
    super.dispose();
  }

  /// After a new request, shows its day (web `onFormSubmitted`).
  void _showCreatedDay() {
    final created = _provider.lastCreated;
    if (created == null || identical(created, _lastCreated)) return;
    _lastCreated = created;
    setState(() {
      _selectedDay = created.start;
      _month = DateTime(created.start.year, created.start.month);
    });
  }

  int _count(SessionStatus status) => _provider.sessions.where((s) => s.status == status).length;

  List<Session> _on(DateTime day) => _provider.sessions.where((s) => s.start.isSameDay(day)).toList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final daySessions = _on(_selectedDay);
        return RefreshIndicator(
          onRefresh: _provider.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppGradients.reservationHeader,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: SessionColors.reservationBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réservations des séances', style: text.titleLarge?.copyWith(color: SessionColors.reservationTitle)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Créez une demande de séance en ligne ou présentielle. Le docteur validera ensuite votre demande.',
                      style: text.bodySmall?.copyWith(color: SessionColors.reservationText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StatGrid(children: [
                StatCard(label: 'Total', value: '${_provider.sessions.length}'),
                StatCard(
                  label: 'En attente',
                  value: '${_count(SessionStatus.draft)}',
                  valueColor: SessionColors.pendingFg,
                  tint: SessionColors.pendingBg,
                ),
                StatCard(
                  label: 'Acceptées',
                  value: '${_count(SessionStatus.scheduled)}',
                  valueColor: SessionColors.acceptedFg,
                  tint: SessionColors.acceptedBg,
                ),
                StatCard(
                  label: 'Refusées',
                  value: '${_count(SessionStatus.cancelled)}',
                  valueColor: SessionColors.refusedFg,
                  tint: SessionColors.refusedBg,
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              AsyncStateView(
                status: _provider.status,
                isEmpty: false,
                errorMessage: _provider.error,
                onRetry: _provider.load,
                loading: const LoadingView(message: 'Chargement des réservations...'),
                empty: const SizedBox.shrink(),
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MonthCalendar(
                      month: _month,
                      locale: 'fr',
                      selectedDay: _selectedDay,
                      onPreviousMonth: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                      onNextMonth: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                      dotsForDay: (day) => [
                        for (final s in _on(day))
                          s.isOnline ? SessionColors.cognitiveAccent : SessionColors.physicalAccent,
                      ],
                      onDayTap: (day) => setState(() => _selectedDay = day),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Demandes du ${Formatters.dayMonthYearFr(_selectedDay)}',
                            style: text.titleMedium?.copyWith(color: SessionColors.reservationTitle),
                          ),
                        ),
                        Text('${daySessions.length} séance(s)', style: text.labelMedium?.copyWith(color: ModuleColors.alzheimer)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (daySessions.isEmpty)
                      EmptyStateView(
                        compact: true,
                        icon: Icons.event_busy_outlined,
                        title: 'Aucune demande prévue pour ce jour.',
                        actionLabel: 'Créer une réservation',
                        onAction: () => context.push(AppRoutes.reservationNew, extra: _selectedDay),
                      )
                    else
                      for (final s in daySessions)
                        Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: ReservationCard(session: s)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
