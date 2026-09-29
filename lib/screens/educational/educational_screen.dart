import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../widgets/navigation/module_tab_scaffold.dart';
import 'activities_tab.dart';
import 'events_tab.dart';
import 'progress_tab.dart';

/// Web `/educational/*` (sidebar "Education").
class EducationalScreen extends StatelessWidget {
  const EducationalScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return ModuleTabScaffold(
      title: 'Education',
      initialIndex: ModuleTabs.indexOf(ModuleTabs.educational, initialTab),
      tabs: const [
        ModuleTab(label: 'Activities', icon: Icons.category_outlined, body: ActivitiesTab()),
        ModuleTab(label: 'Events', icon: Icons.event_outlined, body: EventsTab()),
        ModuleTab(label: 'Progress', icon: Icons.pie_chart_outline_rounded, body: ProgressTab()),
      ],
    );
  }
}
