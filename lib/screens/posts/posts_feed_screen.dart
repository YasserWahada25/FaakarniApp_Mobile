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
import '../../widgets/common/state_views.dart';
import '../../widgets/posts/post_widgets.dart';

/// Web `/posts/list` ("Community Posts").
class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> {
  final _service = PostService.instance;

  List<Post> _posts = [];
  Map<int, ReactionSummary> _reactions = {};
  ViewStatus _status = ViewStatus.loading;
  String? _error;
  String _query = '';

  /// Id of the signed-in user (from the authenticated session).
  String? get _me => AuthSession.instance.userId;

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

  /// A post was created, edited or deleted on another screen.
  void _onPostsChanged() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _status = ViewStatus.loading;
        _error = null;
      });
    }
    try {
      await AuthSession.instance.ensureSignedIn();
      final posts = await _service.getAll();
      final reactions = await _service.getReactionsFor(posts, userId: _me);
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

  /// Optimistic toggle, then the counts returned by the service.
  Future<void> _react(Post post, ReactionType type) async {
    final me = _me;
    if (me == null) {
      showAppSnackBar(context, 'Connectez-vous pour réagir.');
      return;
    }
    final before = _reactions[post.id] ?? ReactionSummary.empty;
    setState(() => _reactions = {..._reactions, post.id: before.toggle(type)});
    try {
      final after = await _service.toggleReaction(post.id, userId: me, type: type);
      if (mounted) setState(() => _reactions = {..._reactions, post.id: after});
    } catch (e) {
      if (!mounted) return;
      setState(() => _reactions = {..._reactions, post.id: before});
      showAppSnackBar(context, ApiException.describe(e));
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

  List<Post> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _posts;
    return _posts
        .where((p) => p.content.toLowerCase().contains(q) || (p.author?.displayName.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // `context` is above this Scaffold, so it resolves to the shell's
        // Scaffold, which owns the drawer.
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
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
                        reactions: _reactions[p.id] ?? ReactionSummary.empty,
                        onReact: (type) => _react(p, type),
                        onComments: () => showCommentsSheet(context, postId: p.id),
                        // The web shows these to everyone; only the author may edit or delete.
                        onEdit: p.isOwnedBy(_me) ? () => context.push(AppRoutes.postEdit(p.id), extra: p) : null,
                        onDelete: p.isOwnedBy(_me) ? () => _delete(p) : null,
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
