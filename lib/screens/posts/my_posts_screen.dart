import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/post.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/posts/post_widgets.dart';

/// Web `/posts/my-posts`.
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  // Filled by the posts API (posts of the signed-in user).
  final List<Post> _posts = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  Future<void> _delete(Post post) async {
    await showConfirmDialog(
      context,
      title: 'Delete post',
      message: 'Are you sure you want to delete this post?',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.postCreate),
            icon: const Icon(Icons.add),
            label: const Text('New Post'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            const PostsHeader(
              title: 'My Posts',
              subtitle: 'Manage your posts and track engagement',
              icon: Icons.account_circle_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'My Posts (${_posts.length})', icon: Icons.check_circle_outline_rounded),
            AsyncStateView(
              status: _status,
              isEmpty: _posts.isEmpty,
              errorMessage: _error,
              onRetry: _load,
              loading: const LoadingView(message: 'Loading your posts...'),
              empty: const EmptyStateView(icon: Icons.inbox_outlined, title: "You haven't created any posts yet"),
              builder: (context) => Column(
                children: [
                  for (final p in _posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: PostCard(
                        post: p,
                        reactions: const ReactionSummary(counts: {}),
                        onReact: (_) {},
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
