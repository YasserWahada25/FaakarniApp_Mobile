import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../common/app_card.dart';
import '../common/initials_avatar.dart';
import '../common/network_picture.dart';
import '../common/dialogs.dart';
import '../common/state_views.dart';

extension ReactionStyle on ReactionType {
  IconData get icon => switch (this) {
    ReactionType.like => Icons.thumb_up_alt_rounded,
    ReactionType.heart => Icons.favorite_rounded,
    ReactionType.support => Icons.volunteer_activism_rounded,
  };

  Color get color => switch (this) {
    ReactionType.like => PostColors.like,
    ReactionType.heart => PostColors.heart,
    ReactionType.support => PostColors.support,
  };
}

/// Feed post (web `.feed-post`).
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.reactions,
    required this.onReact,
    required this.onComments,
    this.onEdit,
    this.onDelete,
  });

  final Post post;
  final ReactionSummary reactions;
  final ValueChanged<ReactionType> onReact;
  final VoidCallback onComments;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xs, 0),
            child: Row(
              children: [
                InitialsAvatar(initials: _initials(post.author?.displayName)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author?.displayName ?? 'Community Member',
                        style: text.titleSmall?.copyWith(color: PostColors.text),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: AppSizes.iconSm - 2,
                            color: PostColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            Formatters.relative(post.createdAt),
                            style: text.bodySmall?.copyWith(color: PostColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(post.content, style: text.bodyLarge?.copyWith(color: PostColors.text)),
          ),
          if (post.imageUrl != null) PostImage(source: post.imageUrl!, height: AppSizes.postImageHeight),
          ReactionsBar(summary: reactions, onReact: onReact),
          const Divider(height: 1),
          TextButton.icon(
            onPressed: onComments,
            icon: const Icon(Icons.mode_comment_outlined),
            label: const Text('View Comments'),
          ),
        ],
      ),
    );
  }
}

String? _initials(String? name) {
  final parts = (name ?? '').split(' ').where((p) => p.isNotEmpty).take(2);
  return parts.isEmpty ? null : parts.map((p) => p[0].toUpperCase()).join();
}

/// Image of a post. The web app stores images inline as `data:image/...;base64,`
/// URLs; those are decoded once, plain URLs are loaded from the network.
class PostImage extends StatefulWidget {
  const PostImage({super.key, required this.source, this.height, this.borderRadius = BorderRadius.zero});

  final String source;
  final double? height;
  final BorderRadius borderRadius;

  @override
  State<PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<PostImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(PostImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _decode();
  }

  void _decode() {
    _bytes = null;
    final source = widget.source;
    if (!source.startsWith('data:')) return;
    final comma = source.indexOf(',');
    if (comma < 0) return;
    try {
      _bytes = base64Decode(source.substring(comma + 1));
    } on FormatException {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Image.memory(
          bytes,
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    final url = ApiConfig.mediaUrl(widget.source);
    if (url == null || widget.source.startsWith('data:')) return _placeholder();
    return NetworkPicture(url: url, height: widget.height, width: double.infinity, borderRadius: widget.borderRadius);
  }

  Widget _placeholder() => Container(
    height: widget.height,
    color: AppColors.bgSecondary,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_outlined, color: AppColors.primarySoft, size: AppSizes.iconLg),
  );
}

/// Like / Love / Support buttons (web `post-reactions.component`).
class ReactionsBar extends StatelessWidget {
  const ReactionsBar({super.key, required this.summary, required this.onReact});

  final ReactionSummary summary;
  final ValueChanged<ReactionType> onReact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          for (final type in ReactionType.values)
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: summary.userReaction == type ? type.color : PostColors.textSecondary,
                  backgroundColor: summary.userReaction == type ? type.color.withValues(alpha: 0.1) : null,
                ),
                onPressed: () => onReact(type),
                icon: Icon(type.icon, size: AppSizes.iconMd),
                label: Text('${summary.count(type)}', style: text.labelMedium?.copyWith(color: null)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Comments of a post (web `post-comments.component`), as a bottom sheet.
Future<void> showCommentsSheet(BuildContext context, {required int postId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CommentsSheet(postId: postId),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId});

  final int postId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _service = PostService.instance;
  final _input = TextEditingController();

  List<PostComment> _comments = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  PostComment? _replyTo;

  /// Id of the signed-in user (from the authenticated session).
  String? get _me => AuthSession.instance.userId;

  int get _total => _comments.fold(0, (sum, c) => sum + 1 + c.replies.length);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthSession.instance.ensureSignedIn();
      final comments = await _service.getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.describe(e);
        _loading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final me = _me;
    final content = _input.text.trim();
    if (content.isEmpty || _sending) return;
    if (me == null) {
      showAppSnackBar(context, 'Connectez-vous pour commenter.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _service.addComment(widget.postId, userId: me, content: content, parentId: _replyTo?.id);
      _input.clear();
      _replyTo = null;
      await _load();
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(PostComment comment) async {
    final me = _me;
    if (me == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer',
      message: 'Supprimer ce commentaire ?',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.deleteComment(widget.postId, comment.id, userId: me);
      await _load();
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.forum_outlined, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Comments ($_total)', style: text.titleMedium),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ErrorStateView(message: _error, onRetry: _load)
                  : _comments.isEmpty
                  ? const EmptyStateView(
                      compact: true,
                      icon: Icons.speaker_notes_off_outlined,
                      title: 'No comments yet. Be the first to comment!',
                    )
                  : ListView(
                      controller: controller,
                      padding: AppSpacing.screen,
                      children: [
                        for (final c in _comments) ...[
                          _CommentTile(
                            comment: c,
                            onReply: () => setState(() => _replyTo = c),
                            onDelete: c.userId == _me ? () => _deleteComment(c) : null,
                          ),
                          for (final r in c.replies)
                            Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.xxxl),
                              child: _CommentTile(
                                comment: r,
                                onDelete: r.userId == _me ? () => _deleteComment(r) : null,
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.bgSecondary)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyTo != null)
                      Row(
                        children: [
                          Expanded(child: Text('Réponse à ${_replyTo!.displayName}', style: text.bodySmall)),
                          TextButton(onPressed: () => setState(() => _replyTo = null), child: const Text('Cancel')),
                        ],
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: AppConstants.commentMaxLength,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: _replyTo == null ? 'Add a comment...' : 'Write your reply...',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton.filled(
                          tooltip: _replyTo == null ? 'Post Comment' : 'Reply',
                          onPressed: _input.text.trim().isEmpty || _sending ? null : _addComment,
                          icon: _sending
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.onReply, this.onDelete});

  final PostComment comment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(color: PostColors.surface, borderRadius: AppRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, size: AppSizes.iconSm, color: PostColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(comment.displayName, style: text.labelMedium)),
              Text(
                Formatters.relative(comment.createdAt),
                style: text.labelSmall?.copyWith(color: PostColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(comment.content, style: text.bodyMedium?.copyWith(color: PostColors.text)),
          Row(
            children: [
              if (onReply != null)
                TextButton.icon(onPressed: onReply, icon: const Icon(Icons.reply_rounded), label: const Text('Reply')),
              if (onDelete != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Header banner of the posts pages (web `.page-header`, `.create-post-header`).
class PostsHeader extends StatelessWidget {
  const PostsHeader({super.key, required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: AppSizes.iconLg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.headlineSmall?.copyWith(color: AppColors.white)),
                Text(subtitle, style: text.bodySmall?.copyWith(color: AppColors.bgSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
