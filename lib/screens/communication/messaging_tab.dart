import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/communication.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/communication/communication_widgets.dart';

enum _MessagingView { chat, feed }

/// Web `messaging/messaging.component` (Chat / Feed).
class MessagingTab extends StatefulWidget {
  const MessagingTab({super.key});

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab> {
  // Filled by the messaging API.
  final List<Contact> _contacts = [];
  final List<FeedPost> _feed = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;

  _MessagingView _view = _MessagingView.chat;
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _publish() {}

  void _like(FeedPost post) => setState(() {
        final i = _feed.indexOf(post);
        if (i >= 0) _feed[i] = post.toggleLike();
      });

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
          child: RefreshIndicator(
            onRefresh: _load,
            child: _view == _MessagingView.chat ? _chatList() : _feedList(),
          ),
        ),
      ],
    );
  }

  Widget _chatList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        AsyncStateView(
          status: _status,
          isEmpty: _contacts.isEmpty,
          errorMessage: _error,
          onRetry: _load,
          empty: const EmptyStateView(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Aucune conversation',
            message: 'Vos contacts apparaîtront ici.',
          ),
          builder: (context) => Column(
            children: [
              for (final c in _contacts)
                ContactTile(contact: c, onTap: () => context.push(AppRoutes.chat(c.id), extra: c)),
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
                  decoration: const InputDecoration(hintText: 'Share something...', filled: false, border: InputBorder.none),
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
