import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/post.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/posts/post_widgets.dart';

/// Web `/posts/list` ("Community Posts").
class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> {
  // Filled by the posts / reactions API.
  final List<Post> _posts = [];
  final Map<int, ReactionSummary> _reactions = {};
  ViewStatus _status = ViewStatus.ready;
  String? _error;
  String _query = '';

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _react(Post post, ReactionType type) =>
      setState(() => _reactions[post.id] = (_reactions[post.id] ?? const ReactionSummary(counts: {})).toggle(type));

  Future<void> _delete(Post post) async {
    await showConfirmDialog(
      context,
      title: 'Delete post',
      message: 'Are you sure you want to delete this post?',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  List<Post> get _filtered {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ? _posts : _posts.where((p) => p.content.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Posts'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.myPosts),
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('My Posts'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.postCreate),
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, 96),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const PostsHeader(
              title: 'Community Posts',
              subtitle: 'Share and discover stories from our community',
              icon: Icons.share_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Search posts...', prefixIcon: Icon(Icons.search_rounded)),
            ),
            const SizedBox(height: AppSpacing.lg),
            AsyncStateView(
              status: _status,
              isEmpty: posts.isEmpty,
              errorMessage: _error,
              onRetry: _load,
              loading: const SkeletonList(itemHeight: 220),
              empty: EmptyStateView(
                icon: Icons.inbox_outlined,
                title: 'No posts yet',
                message: 'Be the first to share something with the community!',
                actionLabel: 'Create Post',
                onAction: () => context.push(AppRoutes.postCreate),
              ),
              builder: (context) => Column(
                children: [
                  for (final p in posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: PostCard(
                        post: p,
                        reactions: _reactions[p.id] ?? const ReactionSummary(counts: {}),
                        onReact: (type) => _react(p, type),
                        onComments: () => showCommentsSheet(context, postId: p.id),
                        onEdit: () => context.push(AppRoutes.postEdit(p.id), extra: p),
                        onDelete: () => _delete(p),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
