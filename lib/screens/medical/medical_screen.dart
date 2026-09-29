import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/navigation/module_tab_scaffold.dart';
import 'detection_tab.dart';
import 'follow_up_tab.dart';
import 'records_tab.dart';

/// Web `/medical/*` (sidebar "Medical Care"). Full-screen module.
class MedicalScreen extends StatelessWidget {
  const MedicalScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return ModuleTabScaffold(
      title: 'Medical Care',
      accentColor: ModuleColors.medical,
      showDrawerButton: false,
      initialIndex: ModuleTabs.indexOf(ModuleTabs.medical, initialTab),
      tabs: const [
        ModuleTab(label: 'Medical Records', icon: Icons.folder_shared_outlined, body: RecordsTab()),
        ModuleTab(label: 'Disease Detection', icon: Icons.biotech_outlined, body: DetectionTab()),
        ModuleTab(label: 'Follow-up', icon: Icons.monitor_heart_outlined, body: FollowUpTab()),
      ],
    );
  }
}
