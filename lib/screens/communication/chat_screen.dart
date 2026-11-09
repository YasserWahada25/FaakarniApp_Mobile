import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/communication.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/communication/communication_widgets.dart';

/// Conversation screen: the right panel of the web messaging page.
///
/// History and sending go through the REST API; new messages and typing
/// notifications arrive over the STOMP socket. While the socket is not
/// connected the conversation is polled instead, so the chat keeps working.
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
  static const _pollInterval = Duration(seconds: 4);

  final _service = ChatService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();

  List<ChatMessage> _messages = [];
  ViewStatus _status = ViewStatus.loading;
  String? _error;
  bool _sending = false;
  bool _contactTyping = false;

  ChatSocket? _socket;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<({String senderId, bool typing})>? _typingSub;
  Timer? _poll;
  Timer? _typingOff;
  Timer? _typingStop;
  bool _typingSent = false;

  /// Id of the signed-in user (from the authenticated session).
  String? get _me => AuthSession.instance.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stopTyping();
    _poll?.cancel();
    _typingOff?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _socket?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.loading;
      _error = null;
    });
    try {
      final me = await AuthSession.instance.ensureSignedIn() ? _me : null;
      if (me == null) throw const ApiException('Connectez-vous pour discuter.');
      final messages = await _service.getConversation(me, widget.contactId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _status = ViewStatus.ready;
      });
      _scrollToBottom(animate: false);
      _startRealtime(me);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = ViewStatus.error;
        _error = ApiException.describe(e);
      });
    }
  }

  void _startRealtime(String me) {
    if (_socket != null) return;
    final socket = _socket = ChatSocket(userId: me)..connect();
    _messageSub = socket.messages.listen((m) {
      if (m.isBetween(me, widget.contactId)) _merge([m]);
    });
    _typingSub = socket.typing.listen((event) {
      if (event.senderId != widget.contactId || !mounted) return;
      _typingOff?.cancel();
      setState(() => _contactTyping = event.typing);
      if (event.typing) {
        _typingOff = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _contactTyping = false);
        });
      }
    });
    _poll = Timer.periodic(_pollInterval, (_) {
      if (!socket.connected) _refresh();
    });
  }

  /// Polling fallback: reloads the conversation when it changed.
  Future<void> _refresh() async {
    final me = _me;
    if (me == null || _status != ViewStatus.ready) return;
    try {
      final messages = await _service.getConversation(me, widget.contactId);
      if (!mounted) return;
      final changed =
          messages.length != _messages.length || (messages.isNotEmpty && messages.last.id != _messages.last.id);
      if (!changed) return;
      final follow = _isAtBottom;
      setState(() => _messages = messages);
      if (follow) _scrollToBottom();
    } catch (_) {
      // Keep the current list; the next tick retries.
    }
  }

  /// Adds messages not shown yet (the socket echoes our own messages too).
  void _merge(List<ChatMessage> incoming) {
    if (!mounted) return;
    final known = {for (final m in _messages) m.id};
    final fresh = incoming.where((m) => !known.contains(m.id)).toList();
    if (fresh.isEmpty) return;
    setState(() => _messages = [..._messages, ...fresh]..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
    _scrollToBottom();
  }

  Future<void> _send() async {
    final me = _me;
    final content = _input.text.trim();
    if (me == null || content.isEmpty || _sending) return;
    _stopTyping();
    setState(() {
      _sending = true;
      _input.clear();
    });
    try {
      final message = await _service.send(senderId: me, receiverId: widget.contactId, content: content);
      _merge([message]);
    } catch (e) {
      if (!mounted) return;
      _input.text = content;
      showAppSnackBar(context, ApiException.describe(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(ChatMessage message) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer',
      message: 'Supprimer ce message ?',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.delete(message.id);
      if (mounted) setState(() => _messages = _messages.where((m) => m.id != message.id).toList());
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    }
  }

  void _onInputChanged(String _) {
    setState(() {});
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    if (!_typingSent) {
      socket.sendTyping(widget.contactId, true);
      _typingSent = true;
    }
    _typingStop?.cancel();
    _typingStop = Timer(const Duration(seconds: 1), _stopTyping);
  }

  void _stopTyping() {
    _typingStop?.cancel();
    if (_typingSent) {
      _socket?.sendTyping(widget.contactId, false);
      _typingSent = false;
    }
  }

  bool get _isAtBottom => !_scroll.hasClients || _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(target, duration: AppDurations.normal, curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final contact = widget.contact;
    final status = contact?.status;
    final canSend = _status == ViewStatus.ready && !_sending && _input.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(
              initials: contact?.initials,
              size: AppSizes.avatarSm,
              icon: contact == null ? Icons.support_agent_rounded : Icons.person_rounded,
              statusColor: status?.color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact?.name ?? widget.title ?? 'Conversation', style: text.titleSmall),
                  if (status != null)
                    Text(status.label, style: text.labelSmall?.copyWith(color: status.color))
                  else if (contact != null)
                    Text(contact.role, style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [IconButton(tooltip: 'Appel vidéo', onPressed: null, icon: const Icon(Icons.videocam_outlined))],
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
                      enabled: _status == ViewStatus.ready,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      onChanged: _onInputChanged,
                      decoration: const InputDecoration(hintText: 'Tapez un message...'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    tooltip: 'Envoyer',
                    onPressed: canSend ? _send : null,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : const Icon(Icons.send_rounded),
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
