import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
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
  final _service = PostService.instance;

  List<Post> _posts = [];
  Map<int, ReactionSummary> _reactions = {};
  ViewStatus _status = ViewStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.revision.addListener(_onPostsChanged);
    _load();
  }

  @override
  void dispose() {
    _service.revision.removeListener(_onPostsChanged);
    super.dispose();
  }

  void _onPostsChanged() => _load(silent: true);

  /// Posts of the signed-in user (the web page shows every post instead).
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _status = ViewStatus.loading;
        _error = null;
      });
    }
    try {
      final me = await AuthSession.instance.ensureSignedIn() ? AuthSession.instance.userId : null;
      if (me == null) throw const ApiException('Connectez-vous pour voir vos posts.');
      final posts = await _service.getByUser(me);
      final reactions = await _service.getReactionsFor(posts, userId: me);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _reactions = reactions;
        _status = ViewStatus.ready;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _status == ViewStatus.ready) {
        showAppSnackBar(context, ApiException.describe(e));
      } else {
        setState(() {
          _status = ViewStatus.error;
          _error = ApiException.describe(e);
        });
      }
    }
  }

  Future<void> _delete(Post post) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete post',
      message: 'Are you sure you want to delete this post?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.delete(post.id);
      if (mounted) showAppSnackBar(context, 'Post supprimé.');
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    }
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
                        reactions: _reactions[p.id] ?? ReactionSummary.empty,
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
