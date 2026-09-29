import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../widgets/navigation/module_tab_scaffold.dart';
import 'groups_tab.dart';
import 'messaging_tab.dart';

/// Web `/communication/*` (sidebar "Communication"). The admin
/// "Moderation" page is out of the mobile scope.
class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return ModuleTabScaffold(
      title: 'Communication',
      initialIndex: ModuleTabs.indexOf(ModuleTabs.communication, initialTab),
      floatingActionButtonBuilder: (index) => index == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.groupNew),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Créer un Groupe'),
            )
          : null,
      tabs: const [
        ModuleTab(label: 'Messaging & Feed', icon: Icons.forum_outlined, body: MessagingTab()),
        ModuleTab(label: 'Groups & Support', icon: Icons.groups_outlined, body: GroupsTab()),
      ],
    );
  }
}
