import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/geofencing.dart';
import '../../models/user.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/geofencing/geo_widgets.dart';

/// Web `alerts-history/alerts-history.component`.
class AlertsHistoryTab extends StatefulWidget {
  const AlertsHistoryTab({super.key, required this.role});

  final UserRole role;

  @override
  State<AlertsHistoryTab> createState() => _AlertsHistoryTabState();
}

class _AlertsHistoryTabState extends State<AlertsHistoryTab> {
  // Filled by the alerts API.
  final List<GeoAlert> _alerts = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  AlertKind? _typeFilter;
  AlertStatus? _statusFilter;
  AlertChannelPreferences _prefs = const AlertChannelPreferences(emailEnabled: false, voiceEnabled: false);

  bool get _isCaregiver => widget.role.isCaregiver;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _resolve(GeoAlert alert) {}

  void _saveSettings() {}

  List<GeoAlert> get _filtered => _alerts
      .where((a) => _typeFilter == null || a.kind == _typeFilter)
      .where((a) => _statusFilter == null || a.status == _statusFilter)
      .toList();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final active = _alerts.where((a) => a.isActive).length;
    final recent = [..._alerts]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          SectionHeader(
            title: 'Alerts History',
            icon: Icons.history_rounded,
            trailing: Wrap(
              spacing: AppSpacing.xs,
              children: [
                AppChip(label: '$active Active', background: GeoColors.dangerBg, foreground: GeoColors.danger, dense: true),
                AppChip(
                  label: '${_alerts.length - active} Resolved',
                  background: GeoColors.okBg,
                  foreground: GeoColors.ok,
                  dense: true,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AlertKind?>(
                  initialValue: _typeFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    for (final k in AlertKind.values) DropdownMenuItem(value: k, child: Text(k.code)),
                  ],
                  onChanged: (v) => setState(() => _typeFilter = v),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<AlertStatus?>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Status')),
                    for (final s in AlertStatus.values) DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AsyncStateView(
            status: _status,
            isEmpty: _filtered.isEmpty,
            errorMessage: _error,
            onRetry: _load,
            empty: const EmptyStateView(compact: true, icon: Icons.inbox_outlined, title: 'No alerts available.'),
            builder: (context) => Column(
              children: [
                for (final a in _filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AlertTile(alert: a, onResolve: _isCaregiver ? () => _resolve(a) : null),
                  ),
              ],
            ),
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Recent Activity', style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final a in recent.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.circle, size: AppSizes.iconSm - 4, color: a.isActive ? GeoColors.danger : GeoColors.ok),
                title: Text('${a.kind.code} — ${a.patientName}'),
                subtitle: Text(Formatters.time(a.timestamp)),
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_isCaregiver) _notificationSettings(text) else _patientInfo(text, active),
        ],
      ),
    );
  }

  Widget _notificationSettings(TextTheme text) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Notification Settings', icon: Icons.notifications_outlined),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.mail_outline_rounded),
            title: const Text('Email Alerts'),
            subtitle: _prefs.emailEnabled ? const Text('Un email sera envoyé à votre adresse lors de chaque alerte.') : null,
            value: _prefs.emailEnabled,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(emailEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.phone_outlined),
            title: const Text('Voice Call (SOS)'),
            subtitle: _prefs.voiceEnabled
                ? const Text("Un appel vocal automatique sera lancé vers votre numéro lors d'un SOS patient.")
                : null,
            value: _prefs.voiceEnabled,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(voiceEnabled: v)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _channelChip(Icons.mail_outline_rounded, 'Email', _prefs.emailEnabled),
              _channelChip(Icons.phone_outlined, 'Voice', _prefs.voiceEnabled),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const FeedbackBanner(
            kind: BannerKind.info,
            message: 'Vos coordonnées (email & téléphone) sont récupérées depuis votre profil.',
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(onPressed: _saveSettings, icon: const Icon(Icons.save_outlined), label: const Text('Sauvegarder')),
        ],
      ),
    );
  }

  Widget _channelChip(IconData icon, String label, bool on) => AppChip(
        icon: icon,
        label: '$label ${on ? 'ON' : 'OFF'}',
        background: on ? GeoColors.okBg : AppColors.borderLight,
        foreground: on ? GeoColors.ok : GeoColors.muted,
      );

  Widget _patientInfo(TextTheme text, int active) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Informations', icon: Icons.info_outline_rounded),
          Text(
            'Vos alertes sont listées ici. Votre soignant reçoit automatiquement une notification à chaque alerte.',
            style: text.bodyMedium,
          ),
          if (active > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FeedbackBanner(message: 'Vous avez $active alerte(s) active(s).'),
          ],
        ],
      ),
    );
  }
}
