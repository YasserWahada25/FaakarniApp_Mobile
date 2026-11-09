import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../models/user.dart';
import '../../widgets/navigation/module_tab_scaffold.dart';
import 'alerts_history_tab.dart';
import 'live_tracking_tab.dart';
import 'supervision_tab.dart';

/// Web `/geofencing/*`. The web shows a patient view or a caregiver view
/// depending on the connected user's role; [role] will come from the
/// authenticated session.
class GeofencingScreen extends StatelessWidget {
  const GeofencingScreen({super.key, this.initialTab, this.role = UserRole.careOwner});

  final String? initialTab;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return ModuleTabScaffold(
      title: 'Geofencing',
      showDrawerButton: false,
      initialIndex: ModuleTabs.indexOf(ModuleTabs.geofencing, initialTab),
      tabs: [
        ModuleTab(label: 'Live Tracking', icon: Icons.share_location_outlined, body: LiveTrackingTab(role: role)),
        ModuleTab(label: 'Alerts & History', icon: Icons.notifications_active_outlined, body: AlertsHistoryTab(role: role)),
        ModuleTab(label: 'Supervision', icon: Icons.pie_chart_outline_rounded, body: SupervisionTab(role: role)),
      ],
    );
  }
}
