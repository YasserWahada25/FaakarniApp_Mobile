import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/communication.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/communication/communication_widgets.dart';

/// Web `groups/group-details/group-details.component`.
class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key, required this.groupId, this.group});

  final int groupId;

  /// Passed by the groups list; otherwise loaded from the API by [groupId].
  final Group? group;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late final Group? _group = widget.group;

  /// Id of the signed-in user (from the authenticated session).
  String? get _me => null;

  Future<void> _load() async {}

  void _setRole(GroupMember member, MemberRole role) {}

  Future<void> _removeMember(GroupMember member) async {
    await showConfirmDialog(
      context,
      title: 'Retirer du groupe',
      message: 'Retirer ${member.displayName} du groupe ?',
      confirmLabel: 'Retirer',
      destructive: true,
    );
  }

  Future<void> _deleteGroup() async {
    await showConfirmDialog(
      context,
      title: 'Supprimer le Groupe',
      message: 'Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
  }

  Future<void> _leave() async {
    await showConfirmDialog(
      context,
      title: 'Quitter le Groupe',
      message: 'Voulez-vous vraiment quitter ce groupe ?',
      confirmLabel: 'Quitter',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(message: 'Groupe introuvable', onRetry: _load),
      );
    }
    final text = Theme.of(context).textTheme;
    final myRole = _me == null ? null : group.roleOf(_me!);
    final isAdmin = myRole == MemberRole.admin;
    final isModerator = isAdmin || myRole == MemberRole.moderator;
    final (typeBg, typeFg) = group.groupType.colors;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: AppSizes.headerImageHeight,
            leading: IconButton.filledTonal(
              tooltip: 'Retour',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(background: GroupCover(coverIndex: group.coverIndex, height: AppSizes.headerImageHeight)),
          ),
          SliverPadding(
            padding: AppSpacing.screen,
            sliver: SliverList.list(
              children: [
                Text(group.name, style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppChip(
                      icon: group.groupType == GroupType.public ? Icons.public_rounded : Icons.lock_outline_rounded,
                      label: group.groupType.code,
                      background: typeBg,
                      foreground: typeFg,
                    ),
                    AppChip(
                      icon: Icons.circle,
                      label: group.status.name.toUpperCase(),
                      background: SessionColors.acceptedBg,
                      foreground: SessionColors.acceptedFg,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  children: [
                    _Stat(
                      icon: Icons.group_outlined,
                      label: '${group.memberCount}${group.maxMembers == null ? '' : '/${group.maxMembers}'} membres',
                    ),
                    _Stat(icon: Icons.calendar_today_outlined, label: 'Créé le ${Formatters.shortDate(group.createdAt)}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Description', icon: Icons.info_outline_rounded),
                      Text(group.description, style: text.bodyMedium),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(title: 'Actions Administrateur', icon: Icons.settings_outlined),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: _deleteGroup,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Supprimer le Groupe'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: 'Membres (${group.members.length})', icon: Icons.group_outlined),
                for (final m in group.members)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MemberCard(
                      member: m,
                      canModerate: isModerator && m.userId != _me,
                      isAdmin: isAdmin,
                      onSetRole: (role) => _setRole(m, role),
                      onRemove: () => _removeMember(m),
                    ),
                  ),
                if (myRole != null && !isAdmin) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _leave,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Quitter le Groupe'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.canModerate,
    required this.isAdmin,
    required this.onSetRole,
    required this.onRemove,
  });

  final GroupMember member;
  final bool canModerate;
  final bool isAdmin;
  final ValueChanged<MemberRole> onSetRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bg, fg, icon) = member.role.style;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const InitialsAvatar(size: AppSizes.avatarSm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(member.displayName, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: AppSpacing.xs),
                    AppChip(icon: icon, label: member.role.code, background: bg, foreground: fg, dense: true),
                  ],
                ),
                Text('Rejoint le ${Formatters.shortDate(member.joinedAt)}', style: text.bodySmall),
              ],
            ),
          ),
          if (canModerate)
            PopupMenuButton<String>(
              tooltip: 'Actions',
              onSelected: (action) => switch (action) {
                'moderator' => onSetRole(MemberRole.moderator),
                'admin' => onSetRole(MemberRole.admin),
                'member' => onSetRole(MemberRole.member),
                _ => onRemove(),
              },
              itemBuilder: (context) => [
                if (isAdmin && member.role == MemberRole.member)
                  const PopupMenuItem(value: 'moderator', child: Text('Promouvoir en modérateur')),
                if (isAdmin && member.role == MemberRole.moderator)
                  const PopupMenuItem(value: 'admin', child: Text('Promouvoir en admin')),
                if (isAdmin && member.role != MemberRole.member)
                  const PopupMenuItem(value: 'member', child: Text('Rétrograder en membre')),
                const PopupMenuItem(value: 'remove', child: Text('Retirer du groupe')),
              ],
            ),
        ],
      ),
    );
  }
}
