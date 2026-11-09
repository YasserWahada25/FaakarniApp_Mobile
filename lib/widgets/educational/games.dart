import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/educational.dart';
import '../common/app_card.dart';
import '../common/charts.dart';
import '../common/dialogs.dart';
import '../common/network_picture.dart';

// ─── Quiz (text and image recognition) ─────────────────────────────────────

/// Sends an answer to the server. Returns the session result when the quiz
/// is over, `null` to move on to the next question.
typedef QuizAnswerHandler = Future<GameResult?> Function(QuizQuestion question, String answer, bool isLast);

/// Web `quiz-game.component`.
class QuizGame extends StatefulWidget {
  const QuizGame({
    super.key,
    required this.questions,
    required this.onAnswer,
    required this.onCompleted,
    required this.onCancel,
    this.imageRecognition = false,
  });

  final List<QuizQuestion> questions;
  final QuizAnswerHandler onAnswer;
  final ValueChanged<GameResult> onCompleted;
  final VoidCallback onCancel;
  final bool imageRecognition;

  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  int _index = 0;
  String? _selected;
  bool _busy = false;

  QuizQuestion get _question => widget.questions[_index];

  Future<void> _validate() async {
    final answer = _selected;
    if (answer == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onAnswer(_question, answer, _index + 1 >= widget.questions.length);
      if (!mounted) return;
      if (result != null) {
        widget.onCompleted(result);
        return;
      }
      setState(() {
        _index++;
        _selected = null;
      });
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final q = _question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressTrack(value: _index / widget.questions.length, color: EduColors.play),
        const SizedBox(height: AppSpacing.sm),
        Text(widget.imageRecognition ? 'Reconnaissance d’images' : 'Quiz', style: text.labelMedium?.copyWith(color: EduColors.subtitle)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Question ${_index + 1} / ${widget.questions.length}', style: text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(q.prompt, style: text.titleLarge?.copyWith(color: EduColors.title)),
              if (q.imageUrl != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: const BoxDecoration(color: EduColors.thumbBg, borderRadius: AppRadius.lgAll),
                  child: NetworkPicture(
                    url: q.imageUrl!,
                    height: AppSizes.quizSceneHeight * 1.5,
                    fit: BoxFit.contain,
                    borderRadius: AppRadius.lgAll,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              for (final option in q.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _OptionTile(
                    option: option,
                    selected: _selected == option.label,
                    onTap: _busy ? null : () => setState(() => _selected = option.label),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EduColors.play),
                onPressed: _selected == null || _busy ? null : _validate,
                child: _busy
                    ? const SizedBox.square(
                        dimension: AppSizes.iconMd,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Valider la réponse'),
              ),
            ],
          ),
        ),
        TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.selected, required this.onTap});

  final QuizOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? EduColors.thumbBg : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: selected ? EduColors.play : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (option.imageUrl != null) ...[
                  NetworkPicture(
                    url: option.imageUrl!,
                    width: AppSizes.avatarXl,
                    height: AppSizes.avatarXl,
                    borderRadius: AppRadius.smAll,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: Text(option.label, style: text.bodyLarge)),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? EduColors.play : AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Memory (pairs of images) ──────────────────────────────────────────────

/// Sends a pair of flipped cards to the server, which tells whether they match.
typedef MemoryMoveHandler = Future<MemoryMove> Function(int firstCardId, int secondCardId);

/// Web `image-game.component`.
class MemoryGame extends StatefulWidget {
  const MemoryGame({
    super.key,
    required this.title,
    required this.cards,
    required this.pairTotal,
    required this.onMove,
    required this.onCompleted,
    required this.onCancel,
  });

  final String title;
  final List<MemoryCardData> cards;
  final int pairTotal;
  final MemoryMoveHandler onMove;
  final ValueChanged<GameResult> onCompleted;
  final VoidCallback onCancel;

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final Set<int> _matched = {};
  final List<int> _faceUp = [];
  int _moves = 0;
  int _pairsFound = 0;
  late int _pairTotal = widget.pairTotal;
  bool _busy = false;

  Future<void> _flip(MemoryCardData card) async {
    if (_busy || _faceUp.contains(card.id) || _matched.contains(card.id)) return;
    setState(() => _faceUp.add(card.id));
    if (_faceUp.length < 2) return;
    _busy = true;
    try {
      final move = await widget.onMove(_faceUp[0], _faceUp[1]);
      if (!mounted) return;
      setState(() {
        _moves = move.moves;
        _pairsFound = move.pairsFound;
        _pairTotal = move.pairTotal;
      });
      if (move.match) {
        setState(() {
          _matched.addAll(_faceUp);
          _faceUp.clear();
        });
        if (move.completed) {
          widget.onCompleted(move.result ??
              GameResult(
                headline: 'Toutes les paires trouvées !',
                detail: 'Terminé en $_moves coups.',
                outcome: GameOutcome.success,
              ));
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 750));
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e');
    } finally {
      if (mounted) {
        setState(() {
          _faceUp.clear();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: text.titleLarge?.copyWith(color: EduColors.title)),
        const SizedBox(height: AppSpacing.xs),
        Text('Coups : $_moves   ·   Paires : $_pairsFound / $_pairTotal', style: text.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: widget.cards.length > 12 ? 4 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: [
            for (final c in widget.cards)
              _MemoryTile(
                card: c,
                faceUp: _faceUp.contains(c.id) || _matched.contains(c.id),
                matched: _matched.contains(c.id),
                onTap: () => _flip(c),
              ),
          ],
        ),
        TextButton(onPressed: widget.onCancel, child: const Text('Quitter')),
      ],
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.card, required this.faceUp, required this.matched, required this.onTap});

  final MemoryCardData card;
  final bool faceUp;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: AppDurations.normal,
      decoration: BoxDecoration(
        gradient: faceUp ? null : AppGradients.eduPlay,
        color: faceUp ? (matched ? EduColors.correctBg : AppColors.white) : null,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: matched ? EduColors.correct : AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: matched ? null : onTap,
          child: Center(
            child: faceUp
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: card.imageUrl.isEmpty
                        ? Text(card.label ?? '?', textAlign: TextAlign.center, style: text.labelLarge)
                        : NetworkPicture(url: card.imageUrl, fit: BoxFit.contain, borderRadius: AppRadius.smAll),
                  )
                : Text('?', style: text.headlineMedium?.copyWith(color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}

// ─── Puzzle ────────────────────────────────────────────────────────────────

/// Web `puzzle-game.component`: pick a piece in the tray, then a slot.
class PuzzleGame extends StatefulWidget {
  const PuzzleGame({
    super.key,
    required this.title,
    required this.image,
    required this.onSolved,
    required this.onCancel,
    this.gridSize = 3,
  });

  final String title;
  final ImageProvider image;
  final VoidCallback onSolved;
  final VoidCallback onCancel;
  final int gridSize;

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  late List<int?> _board;
  late List<int> _tray;
  int? _selectedTray;
  int _moves = 0;

  int get _count => widget.gridSize * widget.gridSize;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.filled(_count, null);
    _tray = List.generate(_count, (i) => i)..shuffle(Random());
    _selectedTray = null;
    _moves = 0;
  }

  void _placeInSlot(int slot) {
    final trayIndex = _selectedTray;
    setState(() {
      if (trayIndex != null) {
        final previous = _board[slot];
        _board[slot] = _tray.removeAt(trayIndex);
        if (previous != null) _tray.add(previous);
        _selectedTray = null;
        _moves++;
      } else if (_board[slot] != null) {
        _tray.add(_board[slot]!);
        _board[slot] = null;
      }
    });
    if (_tray.isEmpty && List.generate(_count, (i) => _board[i] == i).every((ok) => ok)) {
      widget.onSolved();
    }
  }

  Widget _piece(int id) {
    final n = widget.gridSize;
    final col = id % n;
    final row = id ~/ n;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: AppSizes.puzzlePieceBase,
          height: AppSizes.puzzlePieceBase,
          child: OverflowBox(
            maxWidth: AppSizes.puzzlePieceBase * n,
            maxHeight: AppSizes.puzzlePieceBase * n,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * col / (n - 1), n == 1 ? 0 : -1 + 2 * row / (n - 1)),
            child: Image(image: widget.image, width: AppSizes.puzzlePieceBase * n, height: AppSizes.puzzlePieceBase * n, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.title, style: text.titleLarge?.copyWith(color: EduColors.title))),
            Text('Coups : $_moves', style: text.bodyMedium),
            TextButton(onPressed: () => setState(_reset), child: const Text('Mélanger')),
          ],
        ),
        Text('Sélectionne une pièce en bas, puis touche une case de la grille pour la placer.', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: widget.gridSize,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: [
              for (var slot = 0; slot < _count; slot++)
                GestureDetector(
                  onTap: () => _placeInSlot(slot),
                  child: Container(
                    decoration: BoxDecoration(
                      color: EduColors.thumbBg,
                      border: Border.all(
                        color: _board[slot] != null && _board[slot] != slot ? EduColors.wrong : AppColors.white,
                      ),
                    ),
                    child: _board[slot] == null
                        ? Center(child: Text('${slot + 1}', style: text.labelLarge?.copyWith(color: EduColors.subtitle)))
                        : _piece(_board[slot]!),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Pièces disponibles', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSizes.puzzleTray,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tray.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => setState(() => _selectedTray = i),
              child: Container(
                width: AppSizes.puzzleTray,
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedTray == i ? EduColors.play : AppColors.border, width: _selectedTray == i ? 3 : 1),
                  borderRadius: AppRadius.smAll,
                ),
                child: ClipRRect(borderRadius: AppRadius.smAll, child: _piece(_tray[i])),
              ),
            ),
          ),
        ),
        TextButton(onPressed: widget.onCancel, child: const Text('Quitter')),
      ],
    );
  }
}

// ─── Result card ───────────────────────────────────────────────────────────

/// Web `game-result.component`.
class GameResultCard extends StatefulWidget {
  const GameResultCard({super.key, required this.result, required this.onDismiss});

  final GameResult result;
  final VoidCallback onDismiss;

  @override
  State<GameResultCard> createState() => _GameResultCardState();
}

class _GameResultCardState extends State<GameResultCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = widget.result;
    final (bg, fg) = switch (r.outcome) {
      GameOutcome.success => (EduColors.correctBg, EduColors.correct),
      GameOutcome.failure => (EduColors.wrongBg, EduColors.wrong),
      GameOutcome.neutral => (EduColors.thumbBg, EduColors.title),
    };
    return AppCard(
      color: bg,
      borderColor: fg.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.headline, style: text.headlineSmall?.copyWith(color: fg)),
          const SizedBox(height: AppSpacing.xs),
          Text(r.detail, style: text.bodyMedium),
          if (r.scorePercent != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Score final : ${r.scorePercent} %', style: text.titleMedium),
          ],
          if (r.answers.isNotEmpty && !_revealed) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: () => setState(() => _revealed = true), child: const Text('Valider et voir le corrigé')),
          ],
          if (_revealed) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Questions et réponses', style: text.titleSmall),
            for (var i = 0; i < r.answers.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  r.answers[i].correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: r.answers[i].correct ? EduColors.correct : EduColors.wrong,
                ),
                title: Text('${i + 1}. ${r.answers[i].prompt}'),
                subtitle: Text(
                  'Votre réponse : ${r.answers[i].userAnswer}'
                  '${r.answers[i].correct ? '' : '\nBonne réponse : ${r.answers[i].expectedAnswer}'}',
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduColors.play),
            onPressed: widget.onDismiss,
            child: const Text('Retour aux activités'),
          ),
        ],
      ),
    );
  }
}
