import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/meeting.dart';
import '../../widgets/common/initials_avatar.dart';

/// Web `meeting/virtual-meeting.component`: dark video room with controls
/// and a Chat / Participants / Agenda panel (bottom sheet on mobile).
class VirtualMeetingScreen extends StatefulWidget {
  const VirtualMeetingScreen({super.key, required this.sessionId, this.title});

  final int sessionId;
  final String? title;

  @override
  State<VirtualMeetingScreen> createState() => _VirtualMeetingScreenState();
}

/// Initial tab of the panel (the Agenda tab is reached by swiping).
enum _Panel { chat, participants }

class _VirtualMeetingScreenState extends State<VirtualMeetingScreen> {
  // Filled by the meeting (WebRTC / STOMP) layer.
  final List<MeetingParticipant> _participants = [];
  final List<MeetingChatMessage> _messages = [];
  final List<AgendaItem> _agenda = [];

  bool _muted = false;
  bool _videoOff = false;

  void _shareScreen() {}

  void _openPanel(_Panel panel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MeetingColors.bar,
      builder: (context) => _MeetingPanel(
        initial: panel,
        participants: _participants,
        messages: _messages,
        agenda: _agenda,
        onSend: (text) => setState(
          () => _messages.add(MeetingChatMessage(sender: 'Vous', text: text, time: DateTime.now(), isSelf: true)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = widget.title ?? 'Session #${widget.sessionId}';
    return Scaffold(
      backgroundColor: MeetingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: MeetingColors.textOnDark),
                    ),
                  ),
                  const Icon(Icons.circle, color: MeetingColors.recording, size: AppSizes.iconSm - 4),
                  const SizedBox(width: AppSpacing.xs),
                  Text('REC', style: text.labelMedium?.copyWith(color: MeetingColors.recording)),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(AppSpacing.sm),
                crossAxisCount: _participants.isEmpty ? 1 : 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: _participants.isEmpty ? 0.8 : 0.78,
                children: [
                  _VideoTile(name: 'Vous', muted: _muted, videoOff: _videoOff, highlighted: true),
                  for (final p in _participants)
                    _VideoTile(name: p.displayName, muted: p.isMuted, videoOff: p.isVideoOff || !p.isOnline),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: const BoxDecoration(
                color: MeetingColors.bar,
                border: Border(top: BorderSide(color: MeetingColors.barBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    tooltip: 'Mute / Unmute',
                    danger: _muted,
                    onPressed: () => setState(() => _muted = !_muted),
                  ),
                  _ControlButton(
                    icon: _videoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    tooltip: 'Camera On / Off',
                    danger: _videoOff,
                    onPressed: () => setState(() => _videoOff = !_videoOff),
                  ),
                  _ControlButton(icon: Icons.screen_share_outlined, tooltip: 'Share Screen', onPressed: _shareScreen),
                  _ControlButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: 'Chat',
                    onPressed: () => _openPanel(_Panel.chat),
                  ),
                  Badge.count(
                    count: _participants.length + 1,
                    backgroundColor: ModuleColors.alzheimer,
                    child: _ControlButton(
                      icon: Icons.group_outlined,
                      tooltip: 'Participants',
                      onPressed: () => _openPanel(_Panel.participants),
                    ),
                  ),
                  _ControlButton(
                    icon: Icons.call_end_rounded,
                    tooltip: 'Leave Meeting',
                    danger: true,
                    filled: true,
                    onPressed: () => context.pop(),
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

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.name, required this.muted, required this.videoOff, this.highlighted = false});

  final String name;
  final bool muted;
  final bool videoOff;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? MeetingColors.tileAlt : MeetingColors.tile,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: highlighted ? ModuleColors.alzheimer : MeetingColors.barBorder),
      ),
      child: Stack(
        children: [
          Center(
            child: videoOff
                ? InitialsAvatar(initials: initials, size: AppSizes.avatarXl, color: ModuleColors.alzheimer)
                : const Icon(Icons.videocam_rounded, color: MeetingColors.textOnDarkMuted, size: AppSizes.iconXl),
          ),
          Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              children: [
                if (muted) const Icon(Icons.mic_off_rounded, color: MeetingColors.danger, size: AppSizes.iconSm),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: MeetingColors.textOnDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool danger;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled || danger ? MeetingColors.danger : MeetingColors.control,
        foregroundColor: MeetingColors.textOnDark,
      ),
      icon: Icon(icon),
    );
  }
}

class _MeetingPanel extends StatefulWidget {
  const _MeetingPanel({
    required this.initial,
    required this.participants,
    required this.messages,
    required this.agenda,
    required this.onSend,
  });

  final _Panel initial;
  final List<MeetingParticipant> participants;
  final List<MeetingChatMessage> messages;
  final List<AgendaItem> agenda;
  final ValueChanged<String> onSend;

  @override
  State<_MeetingPanel> createState() => _MeetingPanelState();
}

class _MeetingPanelState extends State<_MeetingPanel> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    widget.onSend(value);
    _input.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onDark = text.bodyMedium?.copyWith(color: MeetingColors.textOnDark);
    final muted = text.bodySmall?.copyWith(color: MeetingColors.textOnDarkMuted);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: DefaultTabController(
          length: 3,
          initialIndex: widget.initial.index,
          child: Column(
            children: [
              TabBar(
                labelColor: MeetingColors.textOnDark,
                unselectedLabelColor: MeetingColors.textOnDarkMuted,
                indicatorColor: ModuleColors.alzheimer,
                tabAlignment: TabAlignment.fill,
                dividerColor: MeetingColors.barBorder,
                tabs: const [
                  Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'Chat'),
                  Tab(icon: Icon(Icons.group_outlined), text: 'Participants'),
                  Tab(icon: Icon(Icons.list_rounded), text: 'Agenda'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: widget.messages.isEmpty
                              ? Center(child: Text('Aucun message pour le moment.', style: muted))
                              : ListView(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  children: [
                                    for (final m in widget.messages)
                                      Align(
                                        alignment: m.isSelf ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: m.isSelf ? ModuleColors.alzheimer : MeetingColors.control,
                                            borderRadius: AppRadius.mdAll,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${m.sender} · ${Formatters.time(m.time)}', style: muted),
                                              Text(m.text, style: onDark),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _input,
                                  onSubmitted: (_) => _send(),
                                  decoration: const InputDecoration(hintText: 'Tapez un message...'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton.filled(
                                tooltip: 'Envoyer',
                                onPressed: _send,
                                icon: const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    widget.participants.isEmpty
                        ? Center(child: Text('Aucun participant charge.', style: muted))
                        : ListView(
                            children: [
                              for (final p in widget.participants)
                                ListTile(
                                  title: Text(p.displayName, style: onDark),
                                  subtitle: Text(p.role.label, style: muted),
                                  trailing: Text(
                                    p.isOnline ? 'Online' : 'Offline',
                                    style: text.labelSmall?.copyWith(
                                      color: p.isOnline ? ModuleColors.online : MeetingColors.textOnDarkMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    widget.agenda.isEmpty
                        ? Center(child: Text("Aucun point à l'ordre du jour.", style: muted))
                        : ListView(
                            children: [
                              for (final a in widget.agenda)
                                ListTile(
                                  leading: Icon(
                                    switch (a.state) {
                                      AgendaState.completed => Icons.check_circle_rounded,
                                      AgendaState.active => Icons.radio_button_checked_rounded,
                                      AgendaState.upcoming => Icons.radio_button_unchecked_rounded,
                                    },
                                    color: a.state == AgendaState.upcoming
                                        ? MeetingColors.textOnDarkMuted
                                        : ModuleColors.alzheimer,
                                  ),
                                  title: Text('${a.title} (${a.minutes}m)', style: onDark),
                                ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
