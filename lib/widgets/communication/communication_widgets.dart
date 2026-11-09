import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/communication.dart';
import '../common/app_card.dart';
import '../common/app_chip.dart';
import '../common/initials_avatar.dart';
import '../common/network_picture.dart';

extension PresenceStyle on PresenceStatus {
  Color get color => switch (this) {
    PresenceStatus.online => ModuleColors.online,
    PresenceStatus.away => AppColors.warning,
    PresenceStatus.offline => AppColors.border,
  };
}

extension GroupTypeStyle on GroupType {
  (Color, Color) get colors => this == GroupType.public
      ? (SessionColors.acceptedBg, SessionColors.acceptedFg)
      : (SessionColors.pendingBg, SessionColors.pendingFg);
}

extension MemberRoleStyle on MemberRole {
  (Color, Color, IconData) get style => switch (this) {
    MemberRole.admin => (SessionColors.pendingBg, SessionColors.pendingFg, Icons.workspace_premium_outlined),
    MemberRole.moderator => (SessionColors.finishedBg, SessionColors.finishedFg, Icons.shield_outlined),
    MemberRole.member => (AppColors.bgMain, AppColors.primaryDark, Icons.person_outline_rounded),
  };
}

/// Contact row of the messaging list.
class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.contact, required this.onTap});

  final Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
      leading: InitialsAvatar(initials: contact.initials, statusColor: contact.status?.color),
      title: Text(contact.name),
      subtitle: Text(contact.lastMessage ?? contact.role, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: contact.unreadCount > 0
          ? Badge.count(count: contact.unreadCount, backgroundColor: AppColors.primary)
          : contact.status != null
          ? Text(contact.status!.label, style: text.labelSmall?.copyWith(color: contact.status!.color))
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
    );
  }
}

/// Chat bubble (web `.message` / `.message.self`).
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine, this.onDelete});

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: GestureDetector(
          onLongPress: isMine ? onDelete : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            decoration: BoxDecoration(
              gradient: isMine ? AppGradients.primary : null,
              color: isMine ? null : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.lg),
                topRight: const Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppRadius.xs),
                bottomRight: Radius.circular(isMine ? AppRadius.xs : AppRadius.lg),
              ),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: text.bodyMedium?.copyWith(color: isMine ? AppColors.white : AppColors.textMain),
                ),
                Text(
                  Formatters.time(message.timestamp),
                  style: text.labelSmall?.copyWith(color: isMine ? AppColors.bgSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Post of the messaging "Feed" tab.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post, required this.onLike, required this.onComment});

  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const InitialsAvatar(size: AppSizes.avatarSm),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author, style: text.titleSmall),
                    Text(Formatters.relative(post.date), style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(post.title, style: text.titleMedium?.copyWith(color: AppColors.heading)),
          const SizedBox(height: AppSpacing.xxs),
          Text(post.content, style: text.bodyMedium),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(post.liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined),
                label: Text('Like${post.likes > 0 ? ' · ${post.likes}' : ''}'),
              ),
              TextButton.icon(
                onPressed: onComment,
                icon: const Icon(Icons.mode_comment_outlined),
                label: const Text('Comment'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Group cover: uploaded image, gradient from the palette, or the web
/// "Pas d'image" placeholder.
class GroupCover extends StatelessWidget {
  const GroupCover({super.key, required this.coverIndex, this.imageUrl, this.height = AppSizes.thumbHeight});

  final int coverIndex;

  /// Absolute URL of the uploaded cover; wins over [coverIndex].
  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) return NetworkPicture(url: imageUrl!, height: height, width: double.infinity);
    if (coverIndex < 0) {
      return Container(
        height: height,
        color: AppColors.bgMain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: AppColors.primarySoft, size: AppSizes.iconLg),
            Text("Pas d'image", style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }
    final colors = EduColors.eventCovers[coverIndex % EduColors.eventCovers.length];
    return Container(
      height: height,
      decoration: BoxDecoration(gradient: AppGradients.diagonal(colors.first, colors.last)),
      child: Icon(Icons.groups_rounded, color: AppColors.white.withValues(alpha: 0.35), size: height * 0.5),
    );
  }
}

/// Group card (web `.group-card`).
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.isCreator,
    required this.isMember,
    this.onOpen,
    this.onEdit,
    this.onLeave,
    this.onJoin,
  });

  final Group group;
  final bool isCreator;
  final bool isMember;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onLeave;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (typeBg, typeFg) = group.groupType.colors;
    final locked = !group.isJoinable && !isMember;
    return Opacity(
      opacity: locked ? 0.7 : 1,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: isMember ? onOpen : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupCover(coverIndex: group.coverIndex, imageUrl: group.coverUrl, height: AppSizes.coverSm),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(group.name, style: text.titleMedium)),
                      const Icon(Icons.group_outlined, size: AppSizes.iconSm, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${group.memberCount}${group.maxMembers == null ? '' : '/${group.maxMembers}'}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      AppChip(label: group.groupType.code, background: typeBg, foreground: typeFg, dense: true),
                      if (isCreator)
                        const AppChip(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Créateur',
                          background: SessionColors.pendingBg,
                          foreground: SessionColors.pendingFg,
                          dense: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(group.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  _actions(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(TextTheme text) {
    if (isMember) {
      return Wrap(
        spacing: AppSpacing.sm,
        children: [
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Voir Détails'),
          ),
          if (isCreator)
            TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Modifier'))
          else
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: onLeave,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Quitter'),
            ),
        ],
      );
    }
    if (!group.isJoinable) {
      return Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: AppSizes.iconSm, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text('Sur invitation uniquement', style: text.bodySmall),
        ],
      );
    }
    return FilledButton.icon(
      onPressed: group.isFull ? null : onJoin,
      icon: const Icon(Icons.person_add_alt_rounded),
      label: Text(group.isFull ? 'Complet' : 'Rejoindre'),
    );
  }
}
