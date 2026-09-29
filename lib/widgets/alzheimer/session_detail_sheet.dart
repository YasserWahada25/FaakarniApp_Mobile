import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/session.dart';
import '../common/app_chip.dart';
import 'session_styles.dart';

/// Bottom-sheet version of the web `app-session-detail` panel.
Future<void> showSessionDetailSheet(
  BuildContext context, {
  required Session session,
  required VoidCallback onToggleFavorite,
  required VoidCallback onJoin,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SessionDetail(session: session, onToggleFavorite: onToggleFavorite, onJoin: onJoin),
  );
}

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.session, required this.onToggleFavorite, required this.onJoin});

  final Session session;
  final VoidCallback onToggleFavorite;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final type = session.type.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppChip(label: session.type.label, background: type.background, foreground: type.foreground, uppercase: true),
            const SizedBox(height: AppSpacing.sm),
            Text(session.title, style: text.headlineSmall?.copyWith(color: AppColors.textInk)),
            Text('${session.status.label} - ${session.visibility.label}', style: text.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            _MetaTile(icon: Icons.calendar_today_outlined, label: 'Date', value: Formatters.fullDate(session.start)),
            _MetaTile(
              icon: Icons.schedule_rounded,
              label: 'Horaire',
              value: Formatters.timeRange(session.start, session.end),
            ),
            _MetaTile(icon: Icons.group_outlined, label: 'Participants', value: '${session.participants}'),
            _MetaTile(
              icon: session.isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
              label: 'Mode',
              value: session.isOnline ? 'En ligne' : 'Presentielle${session.locationAddress == null ? '' : ' — ${session.locationAddress}'}',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              session.description.isEmpty ? 'Aucune description disponible.' : session.description,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (session.isOnline)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ModuleColors.alzheimer,
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onJoin();
                },
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Rejoindre la visio'),
              )
            else
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Session presentielle: pas de lien en ligne.', style: text.bodyMedium)),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.buttonHeight)),
              onPressed: () {
                Navigator.of(context).pop();
                onToggleFavorite();
              },
              icon: Icon(session.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: SessionColors.favorite),
              label: Text(session.isFavorite ? 'Retirer favori' : 'Favori'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(color: ModuleColors.alzheimerActiveBg, borderRadius: AppRadius.smAll),
            child: Icon(icon, size: AppSizes.iconMd, color: ModuleColors.alzheimerDeep),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
                Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
