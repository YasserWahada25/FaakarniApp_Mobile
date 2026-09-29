import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/navigation/module_tab_scaffold.dart';
import 'consultation_tab.dart';
import 'favorites_tab.dart';
import 'notifications_tab.dart';
import 'reports_tab.dart';
import 'reservations_tab.dart';

/// Web `/alzheimer_meeting/*` (sidebar "Alzheimer Care").
class AlzheimerScreen extends StatelessWidget {
  const AlzheimerScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return ModuleTabScaffold(
      title: 'Alzheimer Care',
      accentColor: ModuleColors.alzheimerDeep,
      initialIndex: ModuleTabs.indexOf(ModuleTabs.alzheimer, initialTab),
      floatingActionButtonBuilder: (index) => index == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.reservationNew),
              icon: const Icon(Icons.add),
              label: const Text('Réserver une séance'),
            )
          : null,
      tabs: const [
        ModuleTab(label: 'Consultation', icon: Icons.calendar_today_outlined, body: ConsultationTab()),
        ModuleTab(label: 'Réservations', icon: Icons.edit_calendar_outlined, body: ReservationsTab()),
        ModuleTab(label: 'Favorites', icon: Icons.star_border_rounded, body: FavoritesTab()),
        ModuleTab(label: 'Reports', icon: Icons.insights_outlined, body: ReportsTab()),
        ModuleTab(label: 'Notifications', icon: Icons.notifications_none_rounded, body: NotificationsTab()),
      ],
    );
  }
}
