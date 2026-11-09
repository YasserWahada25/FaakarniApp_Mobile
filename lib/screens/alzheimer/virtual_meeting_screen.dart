import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../providers/meeting_controller.dart';
import '../../services/api_client.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/initials_avatar.dart';

/// Web `meeting/virtual-meeting.component`: dark video room with controls
/// and a Chat / Participants panel (bottom sheet on mobile).
///
/// Joining happens here rather than before navigating (web session detail), so
/// every entry point (calendar, favorites) gets the same flow and errors.
class VirtualMeetingScreen extends StatefulWidget {
  const VirtualMeetingScreen({super.key, required this.sessionId, this.title});

  final int sessionId;
  final String? title;

  @override
  State<VirtualMeetingScreen> createState() => _VirtualMeetingScreenState();
}

enum _Panel { chat, participants }

class _VirtualMeetingScreenState extends State<VirtualMeetingScreen> {
  late final MeetingController _meeting = MeetingController(sessionId: widget.sessionId, title: widget.title);

  @override
  void initState() {
    super.initState();
    Future.microtask(_meeting.start);
  }

  @override
  void dispose() {
    _meeting.dispose();
    super.dispose();
  }

  void _openPanel(_Panel panel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MeetingColors.bar,
      builder: (context) => _MeetingPanel(initial: panel, meeting: _meeting),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeetingColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _meeting,
          builder: (context, _) => switch (_meeting.phase) {
            MeetingPhase.joining => const _JoiningView(),
            MeetingPhase.failed => _FailedView(
                message: _meeting.error ?? 'Impossible de rejoindre la session.',
                onRetry: _meeting.start,
              ),
            MeetingPhase.inRoom => _room(context),
          },
        ),
      ),
    );
  }

  Widget _room(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remotes = _meeting.remoteIds;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _meeting.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: MeetingColors.textOnDark),
                ),
              ),
              if (!_meeting.connected) ...[
                const SizedBox(width: AppSpacing.sm),
                Text('Connexion...', style: text.labelMedium?.copyWith(color: MeetingColors.textOnDarkMuted)),
              ],
            ],
          ),
        ),
        if (!_meeting.mediaAvailable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Caméra et micro indisponibles : vérifiez les autorisations de l’application.',
              style: text.bodySmall?.copyWith(color: MeetingColors.danger),
            ),
          ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(AppSpacing.sm),
            crossAxisCount: remotes.isEmpty ? 1 : 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: remotes.isEmpty ? 0.8 : 0.78,
            children: [
              _VideoTile(
                name: 'Vous',
                renderer: _meeting.media.renderer(null),
                muted: _meeting.muted,
                videoOff: _meeting.videoOff,
                mirror: true,
                highlighted: true,
              ),
              for (final id in remotes)
                _VideoTile(name: _meeting.nameOf(id), renderer: _meeting.media.renderer(id)),
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
                icon: _meeting.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                tooltip: 'Mute / Unmute',
                danger: _meeting.muted,
                onPressed: _meeting.toggleMute,
              ),
              _ControlButton(
                icon: _meeting.videoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                tooltip: 'Camera On / Off',
                danger: _meeting.videoOff,
                onPressed: _meeting.toggleVideo,
              ),
              _ControlButton(
                icon: Icons.cameraswitch_rounded,
                tooltip: 'Changer de caméra',
                onPressed: _meeting.switchCamera,
              ),
              _ControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Chat',
                onPressed: () => _openPanel(_Panel.chat),
              ),
              Badge.count(
                count: remotes.length + 1,
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
    );
  }
}

class _JoiningView extends StatelessWidget {
  const _JoiningView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: ModuleColors.alzheimer),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Connexion à la session...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MeetingColors.textOnDark),
          ),
        ],
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: MeetingColors.textOnDarkMuted, size: AppSizes.iconXl),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MeetingColors.textOnDark),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: ModuleColors.alzheimer),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Retour', style: TextStyle(color: MeetingColors.textOnDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.name,
    required this.renderer,
    this.muted = false,
    this.videoOff = false,
    this.mirror = false,
    this.highlighted = false,
  });

  final String name;
  final RTCVideoRenderer? renderer;
  final bool muted;
  final bool videoOff;
  final bool mirror;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();
    final video = renderer;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: highlighted ? MeetingColors.tileAlt : MeetingColors.tile,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: highlighted ? ModuleColors.alzheimer : MeetingColors.barBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video != null && !videoOff)
            RTCVideoView(
              video,
              mirror: mirror,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(child: InitialsAvatar(initials: initials, size: AppSizes.avatarXl, color: ModuleColors.alzheimer)),
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

class _MeetingPanel extends StatelessWidget {
  const _MeetingPanel({required this.initial, required this.meeting});

  final _Panel initial;
  final MeetingController meeting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: DefaultTabController(
          length: _Panel.values.length,
          initialIndex: initial.index,
          child: Column(
            children: [
              const TabBar(
                labelColor: MeetingColors.textOnDark,
                unselectedLabelColor: MeetingColors.textOnDarkMuted,
                indicatorColor: ModuleColors.alzheimer,
                tabAlignment: TabAlignment.fill,
                dividerColor: MeetingColors.barBorder,
                tabs: [
                  Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'Chat'),
                  Tab(icon: Icon(Icons.group_outlined), text: 'Participants'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ChatPanel(meeting: meeting),
                    _ParticipantsPanel(meeting: meeting),
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

class _ChatPanel extends StatefulWidget {
  const _ChatPanel({required this.meeting});

  final MeetingController meeting;

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    if (_input.text.trim().isEmpty) return;
    if (widget.meeting.sendMessage(_input.text)) {
      _input.clear();
    } else {
      showAppSnackBar(context, 'Connexion perdue : message non envoyé.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onDark = text.bodyMedium?.copyWith(color: MeetingColors.textOnDark);
    final muted = text.bodySmall?.copyWith(color: MeetingColors.textOnDarkMuted);
    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: widget.meeting,
            builder: (context, _) {
              final messages = widget.meeting.messages.reversed.toList();
              if (messages.isEmpty) return Center(child: Text('Aucun message pour le moment.', style: muted));
              // Reversed list: it stays on the latest message.
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final sender = m.isSelf ? 'Vous' : widget.meeting.nameOf(m.senderId);
                  return Align(
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
                          Text('$sender · ${Formatters.time(m.time)}', style: muted),
                          Text(m.text, style: onDark),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
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
              IconButton.filled(tooltip: 'Envoyer', onPressed: _send, icon: const Icon(Icons.send_rounded)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantsPanel extends StatefulWidget {
  const _ParticipantsPanel({required this.meeting});

  final MeetingController meeting;

  @override
  State<_ParticipantsPanel> createState() => _ParticipantsPanelState();
}

class _ParticipantsPanelState extends State<_ParticipantsPanel> {
  final _userId = TextEditingController();
  bool _adding = false;
  String? _feedback;

  @override
  void dispose() {
    _userId.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final id = _userId.text.trim();
    if (id.isEmpty || _adding) return;
    setState(() {
      _adding = true;
      _feedback = null;
    });
    String feedback;
    try {
      feedback = await widget.meeting.addParticipant(id);
      _userId.clear();
    } on ApiException catch (e) {
      feedback = e.message;
    }
    if (!mounted) return;
    setState(() {
      _adding = false;
      _feedback = feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onDark = text.bodyMedium?.copyWith(color: MeetingColors.textOnDark);
    final muted = text.bodySmall?.copyWith(color: MeetingColors.textOnDarkMuted);
    return ListenableBuilder(
      listenable: widget.meeting,
      builder: (context, _) {
        final participants = widget.meeting.participants;
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userId,
                      onSubmitted: (_) => _add(),
                      decoration: const InputDecoration(hintText: 'Identifiant du participant'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    tooltip: 'Ajouter un participant',
                    onPressed: _adding ? null : _add,
                    icon: const Icon(Icons.person_add_alt_rounded),
                  ),
                ],
              ),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(_feedback!, style: muted),
              ),
            for (final p in participants)
              ListTile(
                title: Text(p.userId == widget.meeting.userId ? '${p.displayName} (vous)' : p.displayName, style: onDark),
                subtitle: Text('${p.role.label} · ${p.joinStatus.label}', style: muted),
                trailing: Text(
                  p.isOnline ? 'Online' : 'Offline',
                  style: text.labelSmall?.copyWith(
                    color: p.isOnline ? ModuleColors.online : MeetingColors.textOnDarkMuted,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
