import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/meeting.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';

/// Web `notifications/notification-settings.component`.
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  static const Map<String, String> _reminderOptions = {
    '5': '5 minutes',
    '15': '15 minutes',
    '30': '30 minutes',
    '60': '1 hour',
  };

  List<NotificationPreference> _preferences = const [
    NotificationPreference(id: 'session_reminder', label: 'Session Reminders', kind: PreferenceKind.toggle, enabled: true),
    NotificationPreference(
      id: 'reminder_time',
      label: 'Remind me before',
      kind: PreferenceKind.select,
      enabled: true,
      frequency: '15',
    ),
    NotificationPreference(id: 'daily_summary', label: 'Daily Activity Summary', kind: PreferenceKind.toggle, enabled: false),
    NotificationPreference(id: 'sound_alert', label: 'Play Sound on Reminder', kind: PreferenceKind.toggle, enabled: true),
  ];

  void _update(NotificationPreference pref) =>
      setState(() => _preferences = [for (final p in _preferences) p.id == pref.id ? pref : p]);

  void _saveSettings() {}

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: AppSpacing.screen,
      children: [
        const PageIntro(
          title: 'Notifications & Reminders',
          subtitle: 'Manage how you want to be notified about your sessions.',
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < _preferences.length; i++) ...[
                if (i > 0) const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                _preferenceRow(_preferences[i], text),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ModuleColors.alzheimer),
          onPressed: _saveSettings,
          child: const Text('Save Preferences'),
        ),
      ],
    );
  }

  Widget _preferenceRow(NotificationPreference pref, TextTheme text) {
    return switch (pref.kind) {
      PreferenceKind.toggle => SwitchListTile(
          title: Text(pref.label),
          value: pref.enabled,
          onChanged: (v) => _update(pref.copyWith(enabled: v)),
        ),
      PreferenceKind.select => ListTile(
          title: Text(pref.label),
          trailing: DropdownButton<String>(
            value: pref.frequency,
            underline: const SizedBox.shrink(),
            borderRadius: AppRadius.mdAll,
            onChanged: pref.enabled ? (v) => _update(pref.copyWith(frequency: v)) : null,
            items: [
              for (final e in _reminderOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        ),
    };
  }
}
