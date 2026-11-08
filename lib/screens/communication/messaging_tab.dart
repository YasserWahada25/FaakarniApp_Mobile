import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/communication.dart';
import '../../services/user_directory_service.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/communication/communication_widgets.dart';

enum _MessagingView { chat, feed }

/// Web `messaging/messaging.component` (Chat / Feed).
///
/// Unlike the web page (fixed mock users `user1`…`user4`), contacts are the
/// real platform users and the sender is the signed-in user.
class MessagingTab extends StatefulWidget {
  const MessagingTab({super.key});

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab> {
  List<Contact> _contacts = [];
  // The web feed is hard-coded (no backend yet).
  final List<FeedPost> _feed = [];
  ViewStatus _status = ViewStatus.loading;
  String? _error;
  String _query = '';

  _MessagingView _view = _MessagingView.chat;
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.loading;
      _error = null;
    });
    try {
      final me = await AuthSession.instance.ensureSignedIn() ? AuthSession.instance.userId : null;
      if (me == null) throw const ApiException('Connectez-vous pour accéder à la messagerie.');
      final users = await UserDirectoryService.instance.everyone();
      if (!mounted) return;
      setState(() {
        _contacts = [
          for (final u in users)
            if (u.id != me) Contact(id: u.id, name: u.name, role: u.roleLabel),
        ];
        _status = ViewStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = ViewStatus.error;
        _error = ApiException.describe(e);
      });
    }
  }

  void _publish() {}

  void _like(FeedPost post) => setState(() {
    final i = _feed.indexOf(post);
    if (i >= 0) _feed[i] = post.toggleLike();
  });

  List<Contact> get _visibleContacts {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts.where((c) => c.name.toLowerCase().contains(q) || c.role.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
          child: SegmentedButton<_MessagingView>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _MessagingView.chat, icon: Icon(Icons.chat_outlined), label: Text('Chat')),
              ButtonSegment(value: _MessagingView.feed, icon: Icon(Icons.newspaper_outlined), label: Text('Feed')),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: _load, child: _view == _MessagingView.chat ? _chatList() : _feedList()),
        ),
      ],
    );
  }

  Widget _chatList() {
    final contacts = _visibleContacts;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (_status == ViewStatus.ready && _contacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        AsyncStateView(
          status: _status,
          isEmpty: contacts.isEmpty,
          errorMessage: _error,
          onRetry: _load,
          empty: EmptyStateView(
            icon: Icons.chat_bubble_outline_rounded,
            title: _contacts.isEmpty ? 'Aucune conversation' : 'Aucun contact trouvé',
            message: _contacts.isEmpty ? 'Vos contacts apparaîtront ici.' : 'Essayez un autre nom.',
          ),
          builder: (context) => Column(
            children: [
              for (final c in contacts)
                ContactTile(
                  contact: c,
                  onTap: () => context.push(AppRoutes.chat(c.id), extra: c),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedList() {
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: AppDecorations.card(),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _composer,
                  decoration: const InputDecoration(
                    hintText: 'Share something...',
                    filled: false,
                    border: InputBorder.none,
                  ),
                ),
              ),
              FilledButton(onPressed: _publish, child: const Text('Post')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_feed.isEmpty)
          const EmptyStateView(
            icon: Icons.newspaper_outlined,
            title: 'Aucune publication',
            message: 'Les publications de la communauté apparaîtront ici.',
          )
        else
          for (final p in _feed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: FeedPostCard(post: p, onLike: () => _like(p), onComment: () {}),
            ),
      ],
    );
  }
}
