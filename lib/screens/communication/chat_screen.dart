import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/communication.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/communication/communication_widgets.dart';

/// Conversation screen: the right panel of the web messaging page.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contactId, this.contact, this.title});

  final String contactId;
  final Contact? contact;

  /// Header title when no [contact] is given (e.g. "Support en Ligne").
  final String? title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  // Filled by the messaging API / WebSocket.
  final List<ChatMessage> _messages = [];
  ViewStatus _status = ViewStatus.ready;
  String? _error;
  final bool _contactTyping = false;

  /// Id of the signed-in user (from the authenticated session).
  String get _me => 'me';

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.ready;
      _error = null;
    });
  }

  void _send() {
    final content = _input.text.trim();
    if (content.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        senderId: _me,
        receiverId: widget.contactId,
        content: content,
        timestamp: DateTime.now(),
      ));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: AppDurations.normal, curve: Curves.easeOut);
      }
    });
  }

  Future<void> _delete(ChatMessage message) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer',
      message: 'Supprimer ce message ?',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (confirmed) setState(() => _messages.remove(message));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final contact = widget.contact;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(
              initials: contact?.initials,
              size: AppSizes.avatarSm,
              icon: contact == null ? Icons.support_agent_rounded : Icons.person_rounded,
              statusColor: contact?.status.color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact?.name ?? widget.title ?? 'Conversation', style: text.titleSmall),
                  if (contact != null)
                    Text(contact.status.label, style: text.labelSmall?.copyWith(color: contact.status.color)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Appel vidéo', onPressed: null, icon: const Icon(Icons.videocam_outlined)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (_status) {
                ViewStatus.loading => const Center(child: CircularProgressIndicator()),
                ViewStatus.error => ErrorStateView(message: _error, onRetry: _load),
                ViewStatus.ready when _messages.isEmpty => Center(
                    child: Text('Aucun message. Commencez la conversation!', style: text.bodyMedium),
                  ),
                ViewStatus.ready => ListView.builder(
                    controller: _scroll,
                    padding: AppSpacing.screen,
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => MessageBubble(
                      message: _messages[i],
                      isMine: _messages[i].senderId == _me,
                      onDelete: () => _delete(_messages[i]),
                    ),
                  ),
              },
            ),
            if (_contactTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs),
                child: Text("${contact?.name ?? ''} est en train d'écrire…", style: text.bodySmall),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.bgSecondary)),
              ),
              child: Row(
                children: [
                  IconButton(tooltip: 'Message vocal', onPressed: null, icon: const Icon(Icons.mic_none_rounded)),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Tapez un message...'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    tooltip: 'Envoyer',
                    onPressed: _input.text.trim().isEmpty ? null : _send,
                    icon: const Icon(Icons.send_rounded),
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
