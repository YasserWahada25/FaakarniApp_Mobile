import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/communication.dart';
import '../../services/group_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
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
  final _service = GroupService.instance;

  late Group? _group = widget.group;
  late ViewStatus _status = widget.group == null ? ViewStatus.loading : ViewStatus.ready;
  String? _error;
  bool _busy = false;

  /// Id of the signed-in user (from the authenticated session).
  String? get _me => AuthSession.instance.userId;

  @override
  void initState() {
    super.initState();
    _service.revision.addListener(_onGroupsChanged);
    // The group passed by the list is shown at once and refreshed in the background.
    _load(silent: widget.group != null);
  }

  @override
  void dispose() {
    _service.revision.removeListener(_onGroupsChanged);
    super.dispose();
  }

  void _onGroupsChanged() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _status = ViewStatus.loading;
        _error = null;
      });
    }
    try {
      await AuthSession.instance.ensureSignedIn();
      final group = await _service.getById(widget.groupId);
      if (!mounted) return;
      setState(() {
        _group = group;
        _status = ViewStatus.ready;
      });
    } catch (e) {
      if (!mounted || _group != null) return;
      setState(() {
        _status = ViewStatus.error;
        _error = ApiException.describe(e);
      });
    }
  }

  /// Runs a write call; the group reloads through [GroupService.revision].
  Future<void> _run(Future<void> Function() call, {required String success, bool closeAfter = false}) async {
    setState(() => _busy = true);
    try {
      await call();
      if (!mounted) return;
      showAppSnackBar(context, success);
      if (closeAfter) context.pop();
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setRole(GroupMember member, MemberRole role) => _run(
    () => _service.setRole(widget.groupId, member.userId, role),
    success: '${member.displayName} est maintenant ${role.code}.',
  );

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Retirer du groupe',
      message: 'Retirer ${member.displayName} du groupe ?',
      confirmLabel: 'Retirer',
      destructive: true,
    );
    if (confirmed) {
      await _run(
        () => _service.removeMember(widget.groupId, member.userId),
        success: '${member.displayName} a été retiré du groupe.',
      );
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer le Groupe',
      message: 'Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (confirmed) await _run(() => _service.delete(widget.groupId), success: 'Groupe supprimé.', closeAfter: true);
  }

  Future<void> _leave() async {
    final me = _me;
    if (me == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Quitter le Groupe',
      message: 'Voulez-vous vraiment quitter ce groupe ?',
      confirmLabel: 'Quitter',
      destructive: true,
    );
    if (confirmed) {
      await _run(
        () => _service.removeMember(widget.groupId, me),
        success: 'Vous avez quitté le groupe.',
        closeAfter: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _status == ViewStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : ErrorStateView(message: _error ?? 'Groupe introuvable', onRetry: _load),
      );
    }
    final text = Theme.of(context).textTheme;
    final myRole = _me == null ? null : group.roleOf(_me!);
    final isAdmin = myRole == MemberRole.admin;
    final isModerator = isAdmin || myRole == MemberRole.moderator;
    final (typeBg, typeFg) = group.groupType.colors;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        edgeOffset: AppSizes.headerImageHeight,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: AppSizes.headerImageHeight,
              leading: IconButton.filledTonal(
                tooltip: 'Retour',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: GroupCover(
                  coverIndex: group.coverIndex,
                  imageUrl: group.coverUrl,
                  height: AppSizes.headerImageHeight,
                ),
              ),
              bottom: _busy
                  ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
                  : null,
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
                      _Stat(
                        icon: Icons.calendar_today_outlined,
                        label: 'Créé le ${Formatters.shortDate(group.createdAt)}',
                      ),
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
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => context.push(AppRoutes.groupEdit(group.id), extra: group),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Modifier le Groupe'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: _busy ? null : _deleteGroup,
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
                        canModerate: isModerator && m.userId != _me && !_busy,
                        isAdmin: isAdmin,
                        onSetRole: (role) => _setRole(m, role),
                        onRemove: () => _removeMember(m),
                      ),
                    ),
                  if (myRole != null && !isAdmin) ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _leave,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Quitter le Groupe'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
                    Flexible(
                      child: Text(member.displayName, style: text.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
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
