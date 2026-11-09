import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/educational.dart';
import '../../services/educational_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/educational/activity_widgets.dart';
import '../../widgets/educational/games.dart';

/// Web `activities/activity-play.component`: runs the quiz, memory or
/// puzzle game (or shows the content sheet) of an activity.
class ActivityPlayScreen extends StatefulWidget {
  const ActivityPlayScreen({super.key, required this.activityId, this.activity});

  final int activityId;

  /// Passed by the catalogue; otherwise loaded from the API by [activityId].
  final EducationalActivity? activity;

  @override
  State<ActivityPlayScreen> createState() => _ActivityPlayScreenState();
}

class _ActivityPlayScreenState extends State<ActivityPlayScreen> {
  final _service = EducationalService.instance;

  late EducationalActivity? _activity = widget.activity;
  bool _loading = true;
  String? _error;

  /// Quiz / memory session started on the server.
  GameSession? _session;
  String? _puzzleImageUrl;

  GameResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activity = _activity ?? await _service.getActivity(widget.activityId);
      _activity = activity;
      switch (activity.type) {
        case ActivityType.quiz:
        case ActivityType.cognitiveGame:
        case ActivityType.imageGame:
          _session = await _service.startSession(activity.id);
        case ActivityType.puzzleGame:
          _puzzleImageUrl = await _loadPuzzleImage(activity);
        case ActivityType.content:
        case ActivityType.video:
          break;
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// First image card of the activity, or its thumbnail (web `puzzle-game.component`).
  Future<String?> _loadPuzzleImage(EducationalActivity activity) async {
    try {
      final cards = await _service.getImageCards(activity.id);
      for (final c in cards) {
        if (c.imageUrl.isNotEmpty) return c.imageUrl;
      }
    } catch (_) {
      // Falls back to the thumbnail below.
    }
    return activity.thumbnailUrl;
  }

  /// Web `QuizGameComponent.submitCurrent` + `handleSubmit`.
  Future<GameResult?> _answer(QuizQuestion question, String answer, bool isLast) async {
    final session = _session!;
    final feedback = await _service.submitAnswer(
      activityId: session.activityId == 0 ? _activity!.id : session.activityId,
      sessionId: session.sessionId,
      questionId: question.id,
      answer: answer,
    );
    if (feedback.sessionFinished && feedback.result != null) return feedback.result;
    if (feedback.sessionFinished || isLast) return _service.finishSession(session.sessionId);
    return null;
  }

  Future<MemoryMove> _move(int first, int second) =>
      _service.submitMemoryMove(sessionId: _session!.sessionId, firstCardId: first, secondCardId: second);

  void _finish(GameResult result) => setState(() => _result = result);

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    return Scaffold(
      appBar: AppBar(title: Text(activity?.name ?? 'Activité')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour aux activités'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ErrorStateView(message: _error, onRetry: _load)
            else if (activity == null)
              const EmptyStateView(icon: Icons.sports_esports_outlined, title: 'Activité introuvable.')
            else if (_result != null)
              GameResultCard(result: _result!, onDismiss: () => context.pop())
            else
              _game(activity),
          ],
        ),
      ),
    );
  }

  Widget _game(EducationalActivity activity) {
    final noContent = EmptyStateView(
      icon: activity.type.icon,
      title: 'Contenu indisponible',
      message: "Le contenu de cette activité n'est pas encore disponible.",
    );
    final session = _session;
    switch (activity.type) {
      case ActivityType.quiz:
      case ActivityType.cognitiveGame:
        return session == null || session.questions.isEmpty
            ? noContent
            : QuizGame(
                questions: session.questions,
                imageRecognition: activity.type == ActivityType.cognitiveGame,
                onAnswer: _answer,
                onCompleted: _finish,
                onCancel: () => context.pop(),
              );
      case ActivityType.imageGame:
        return session == null || session.cards.isEmpty
            ? noContent
            : MemoryGame(
                title: activity.name,
                cards: session.cards,
                pairTotal: session.totalQuestions,
                onMove: _move,
                onCompleted: _finish,
                onCancel: () => context.pop(),
              );
      case ActivityType.puzzleGame:
        final url = _puzzleImageUrl;
        return url == null
            ? noContent
            : PuzzleGame(
                title: activity.name,
                image: NetworkImage(url),
                onCancel: () => context.pop(),
                onSolved: () => _finish(const GameResult(
                  headline: 'Puzzle terminé',
                  detail: 'Bravo ! Vous avez reconstitué l’image.',
                  outcome: GameOutcome.success,
                )),
              );
      case ActivityType.content:
      case ActivityType.video:
        return _ContentSheet(activity: activity, onClose: () => context.pop());
    }
  }
}

/// Web `.content-sheet` (reading / video activities).
class _ContentSheet extends StatelessWidget {
  const _ContentSheet({required this.activity, required this.onClose});

  final EducationalActivity activity;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final body = activity.contentText ?? activity.description;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActivityThumbnail(type: activity.type, imageUrl: activity.thumbnailUrl),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(activity.name, style: text.headlineSmall?.copyWith(color: EduColors.title)),
                const SizedBox(height: AppSpacing.sm),
                Text(body.trim().isEmpty ? 'Aucune description.' : body, style: text.bodyLarge),
                if (activity.durationMin != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Durée indiquée : ${activity.durationMin} min', style: text.bodySmall),
                ],
                if (activity.videoUrl != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: EduColors.play),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: SelectableText(activity.videoUrl!, style: text.bodySmall)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: EduColors.play),
                  onPressed: onClose,
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
