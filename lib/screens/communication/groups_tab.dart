import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/communication.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/communication/communication_widgets.dart';

/// Web `groups/groups.component`: my groups, discover, online support.
class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  // Filled by the groups API.
  final List<Group> _groups = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  /// Id of the signed-in user (from the authenticated session).
  String? get _me => null;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _join(Group group) {}

  Future<void> _leave(Group group) async {
    await showConfirmDialog(
      context,
      title: 'Quitter le groupe',
      message: 'Voulez-vous vraiment quitter "${group.name}" ?',
      confirmLabel: 'Quitter',
      destructive: true,
    );
  }

  bool _isMember(Group g) => _me != null && g.hasMember(_me!);

  @override
  Widget build(BuildContext context) {
    final mine = _groups.where(_isMember).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, 96),
        children: [
          if (_error != null && _status == ViewStatus.ready) ...[
            FeedbackBanner(message: _error!, onClose: () => setState(() => _error = null)),
            const SizedBox(height: AppSpacing.md),
          ],
          const SectionHeader(title: 'Mes Groupes', icon: Icons.groups_outlined),
          AsyncStateView(
            status: _status,
            isEmpty: mine.isEmpty,
            errorMessage: _error,
            onRetry: _load,
            empty: EmptyStateView(
              compact: true,
              icon: Icons.group_off_outlined,
              title: "Vous n'êtes membre d'aucun groupe",
              actionLabel: 'Créer votre premier groupe',
              onAction: () => context.push(AppRoutes.groupNew),
            ),
            builder: (context) => Column(
              children: [for (final g in mine) _card(g)],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Découvrir des Groupes', icon: Icons.public_rounded),
          if (_status == ViewStatus.ready)
            if (_groups.isEmpty)
              const EmptyStateView(compact: true, icon: Icons.travel_explore_rounded, title: 'Aucun groupe à découvrir')
            else
              for (final g in _groups) _card(g),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Support en Ligne', icon: Icons.headset_mic_outlined),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SupportCard(
                  icon: Icons.forum_outlined,
                  title: 'Chat en Direct',
                  body: 'Parlez à un agent de support maintenant.',
                  action: 'Démarrer le Chat',
                  onTap: () => context.push(AppRoutes.chat('support'), extra: 'Support en Ligne'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SupportCard(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Soumettre un Ticket',
                  body: 'Envoyez une demande détaillée par email.',
                  action: 'Ouvrir un Ticket',
                  onTap: () => showContactSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(Group g) {
    final member = _isMember(g);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GroupCard(
        group: g,
        isMember: member,
        isCreator: g.creatorId == _me,
        onOpen: () => context.push(AppRoutes.group(g.id), extra: g),
        onEdit: () => context.push(AppRoutes.groupEdit(g.id), extra: g),
        onLeave: () => _leave(g),
        onJoin: () => _join(g),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSizes.iconLg),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: text.titleSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md)),
            onPressed: onTap,
            child: Text(action, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
