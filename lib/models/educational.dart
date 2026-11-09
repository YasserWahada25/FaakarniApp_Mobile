import '../core/config/api_config.dart';

/// Educational module models (web `educational-activity.model.ts`,
/// `educational-event.model.ts`, `activity.service.ts` DTOs and
/// `patient-engagement.model.ts`).
enum ActivityType {
  quiz('Quiz', 'QCM & mémoire'),
  cognitiveGame('Quiz images (reconnaissance)', 'Images'),
  imageGame('Memory — paires d’images', 'Memory'),
  puzzleGame('Puzzle — image', 'Puzzle'),
  video('Vidéo', 'Vidéo'),
  content('Contenu', 'Lecture');

  const ActivityType(this.label, this.thumbLabel);

  final String label;
  final String thumbLabel;

  /// API `type` + `gameType` → screen type (web `ActivityService.toFrontendType`).
  static ActivityType fromApi(String? type, String? gameType) {
    switch ((type ?? '').toUpperCase()) {
      case 'VIDEO':
        return ActivityType.video;
      case 'GAME':
      case 'QUIZ':
        return switch (_normalizeGameType(gameType)) {
          'MEMORY_MATCH' => ActivityType.imageGame,
          'PUZZLE' => ActivityType.puzzleGame,
          'IMAGE_RECOGNITION' => ActivityType.cognitiveGame,
          _ => ActivityType.quiz,
        };
      default:
        return ActivityType.content;
    }
  }

  static String _normalizeGameType(String? raw) =>
      (raw ?? '').trim().toUpperCase().replaceAll('-', '_').replaceAll(RegExp(r'\s+'), '_');
}

class EducationalActivity {
  const EducationalActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.active = true,
    this.lastScore,
    this.scoreThreshold,
    this.durationMin,
    this.contentText,
    this.videoUrl,
    this.thumbnailUrl,
  });

  /// Web stores the video URL and duration as suffixes of the description.
  static const _videoUrlMarker = '\n__VIDEO_URL__:';
  static const _videoDurationMarker = '\n__VIDEO_DURATION__:';

  factory EducationalActivity.fromJson(Map<String, dynamic> json) {
    final type = ActivityType.fromApi(json['type'] as String?, (json['gameType'] ?? json['game_type']) as String?);
    var description = (json['description'] as String?) ?? '';
    String? videoUrl;
    int? duration;
    if (type == ActivityType.video) {
      var rest = description.trimRight();
      final di = rest.lastIndexOf(_videoDurationMarker);
      if (di >= 0) {
        duration = int.tryParse(rest.substring(di + _videoDurationMarker.length).trim());
        rest = rest.substring(0, di).trimRight();
      }
      final ui = rest.indexOf(_videoUrlMarker);
      if (ui >= 0) {
        final url = rest.substring(ui + _videoUrlMarker.length).trim();
        videoUrl = url.isEmpty ? null : url;
        rest = rest.substring(0, ui).trimRight();
      }
      description = rest;
    }
    return EducationalActivity(
      id: _int(json['id']),
      name: (json['title'] as String?) ?? '',
      description: description,
      type: type,
      active: (json['status'] as String?)?.toUpperCase() != 'INACTIVE',
      lastScore: _intOrNull(json['latestScorePercent']),
      scoreThreshold: _intOrNull(json['scoreThreshold']),
      durationMin: duration,
      videoUrl: videoUrl,
      thumbnailUrl: ApiConfig.resolveMedia(json['thumbnailUrl'] as String?),
    );
  }

  final int id;
  final String name;
  final String description;
  final ActivityType type;
  final bool active;
  final int? lastScore;
  final int? scoreThreshold;
  final int? durationMin;
  final String? contentText;
  final String? videoUrl;
  final String? thumbnailUrl;
}

/// A quiz question (web `QuestionPlayDto`). The correct answer stays on the
/// server: each answer is checked by `submit-answer`.
class QuizQuestion {
  const QuizQuestion({required this.id, required this.prompt, required this.options, this.imageUrl});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final quizOptions = json['quizOptions'] ?? json['quiz_options'];
    final List<QuizOption> options;
    if (quizOptions is List && quizOptions.isNotEmpty) {
      options = [
        for (final o in quizOptions.whereType<Map<String, dynamic>>())
          QuizOption('${o['label'] ?? ''}', ApiConfig.resolveMedia((o['imageUrl'] ?? o['image_url']) as String?)),
      ];
    } else {
      options = [for (final o in (json['options'] as List?) ?? const []) QuizOption('$o')];
    }
    return QuizQuestion(
      id: _int(json['id']),
      prompt: '${json['prompt'] ?? ''}',
      imageUrl: ApiConfig.resolveMedia(
        (json['questionImageUrl'] ?? json['question_image_url'] ?? json['imageUrl'] ?? json['image_url']) as String?,
      ),
      options: options,
    );
  }

  final int id;
  final String prompt;
  final List<QuizOption> options;
  final String? imageUrl;
}

class QuizOption {
  const QuizOption(this.label, [this.imageUrl]);

  final String label;
  final String? imageUrl;
}

/// A memory card (web `ImageCardPlayDto`). Pairs are matched by the server.
class MemoryCardData {
  const MemoryCardData({required this.id, required this.imageUrl, this.label});

  factory MemoryCardData.fromJson(Map<String, dynamic> json) => MemoryCardData(
        id: _int(json['id']),
        imageUrl: ApiConfig.resolveMedia((json['imageUrl'] ?? json['image_url']) as String?) ?? '',
        label: (json['backLabel'] ?? json['back_label'] ?? json['label']) as String?,
      );

  final int id;
  final String imageUrl;
  final String? label;
}

/// Response of `POST /api/activities/{id}/start` (web `GameSessionStartResponseDto`).
class GameSession {
  const GameSession({
    required this.sessionId,
    required this.activityId,
    required this.totalQuestions,
    required this.questions,
    required this.cards,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final questions = [
      for (final q in ((json['questions'] as List?) ?? const []).whereType<Map<String, dynamic>>()) QuizQuestion.fromJson(q),
    ];
    final cards = [
      for (final c in ((json['imageCards'] ?? json['image_cards']) as List? ?? const []).whereType<Map<String, dynamic>>())
        MemoryCardData.fromJson(c),
    ];
    final fallbackTotal = questions.isNotEmpty ? questions.length : cards.length ~/ 2;
    return GameSession(
      sessionId: _int(json['sessionId'] ?? json['session_id']),
      activityId: _int(json['activityId'] ?? json['activity_id']),
      totalQuestions: _intOrNull(json['totalQuestions'] ?? json['total_questions']) ?? fallbackTotal,
      questions: questions,
      cards: cards,
    );
  }

  final int sessionId;
  final int activityId;
  final int totalQuestions;
  final List<QuizQuestion> questions;
  final List<MemoryCardData> cards;
}

/// Response of `submit-answer` (web `SubmitAnswerResponseDto`).
class AnswerFeedback {
  const AnswerFeedback({required this.correct, required this.sessionFinished, this.result});

  factory AnswerFeedback.fromJson(Map<String, dynamic> json) {
    final sr = json['sessionResult'] ?? json['session_result'];
    return AnswerFeedback(
      correct: json['correct'] == true,
      sessionFinished: (json['sessionFinished'] ?? json['session_finished']) == true,
      result: sr is Map<String, dynamic> ? GameResult.fromApi(sr) : null,
    );
  }

  final bool correct;
  final bool sessionFinished;
  final GameResult? result;
}

/// Response of `game-sessions/{id}/move` (web `MemoryMoveResponseDto`).
class MemoryMove {
  const MemoryMove({
    required this.match,
    required this.moves,
    required this.pairsFound,
    required this.pairTotal,
    required this.completed,
    this.result,
  });

  factory MemoryMove.fromJson(Map<String, dynamic> json) {
    final sr = json['sessionResult'] ?? json['session_result'];
    return MemoryMove(
      match: json['match'] == true,
      moves: _int(json['movesCount'] ?? json['moves_count']),
      pairsFound: _int(json['pairsFound'] ?? json['pairs_found']),
      pairTotal: _int(json['pairTotal'] ?? json['pair_total']),
      completed: (json['gameCompleted'] ?? json['game_completed']) == true,
      result: sr is Map<String, dynamic> ? GameResult.fromApi(sr) : null,
    );
  }

  final bool match;
  final int moves;
  final int pairsFound;
  final int pairTotal;
  final bool completed;
  final GameResult? result;
}

enum GameOutcome { success, failure, neutral }

class AnswerDetail {
  const AnswerDetail({
    required this.prompt,
    required this.userAnswer,
    required this.expectedAnswer,
    required this.correct,
  });

  factory AnswerDetail.fromJson(Map<String, dynamic> json) => AnswerDetail(
        prompt: '${json['prompt'] ?? ''}',
        userAnswer: '${json['userAnswer'] ?? json['user_answer'] ?? ''}',
        expectedAnswer:
            '${json['expectedAnswer'] ?? json['expected_answer'] ?? json['correctAnswer'] ?? json['correct_answer'] ?? ''}',
        correct: json['correct'] == true,
      );

  final String prompt;
  final String userAnswer;
  final String expectedAnswer;
  final bool correct;
}

/// Result card shown after a game (web `game-result.component`).
class GameResult {
  const GameResult({
    required this.headline,
    required this.detail,
    required this.outcome,
    this.scorePercent,
    this.answers = const [],
  });

  /// Web `GameResultComponent.fromApi` (`GameSessionResultDto`).
  factory GameResult.fromApi(Map<String, dynamic> json) {
    final pct = _numOrNull(json['scorePercent'] ?? json['score_percent'] ?? json['percentage']);
    final score = pct?.round();
    final label = score == null ? '—' : '$score %';
    final answers = [
      for (final a in ((json['answers'] as List?) ?? const []).whereType<Map<String, dynamic>>()) AnswerDetail.fromJson(a),
    ];
    return switch ('${json['status'] ?? ''}'.toUpperCase()) {
      'SUCCESS' => GameResult(
          headline: 'Bravo, session réussie',
          detail: 'Votre score : $label (seuil atteint ou dépassé).',
          outcome: GameOutcome.success,
          scorePercent: score,
          answers: answers,
        ),
      'FAILURE' => GameResult(
          headline: 'Session terminée — non validée',
          detail: 'Score : $label. Vous pouvez relancer l’activité pour réessayer.',
          outcome: GameOutcome.failure,
          scorePercent: score,
          answers: answers,
        ),
      _ => GameResult(
          headline: 'Session terminée',
          detail: 'Score : $label.',
          outcome: GameOutcome.neutral,
          scorePercent: score,
          answers: answers,
        ),
    };
  }

  final String headline;
  final String detail;
  final GameOutcome outcome;
  final int? scorePercent;
  final List<AnswerDetail> answers;
}

class EducationalEvent {
  const EducationalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDateTime,
    required this.remindEnabled,
    required this.coverIndex,
    this.latitude,
    this.longitude,
    this.coverImageUrl,
  });

  /// Event-Service `EventResponse`.
  factory EducationalEvent.fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    return EducationalEvent(
      id: id,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      location: (json['location'] as String?)?.trim() ?? '',
      startDateTime: DateTime.tryParse('${json['startDateTime'] ?? ''}'),
      remindEnabled: json['remindEnabled'] == true,
      latitude: _numOrNull(json['lat'])?.toDouble(),
      longitude: _numOrNull(json['lng'])?.toDouble(),
      coverImageUrl: ApiConfig.resolveMedia(json['coverImageUrl'] as String?),
      coverIndex: id,
    );
  }

  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime? startDateTime;
  final bool remindEnabled;
  final double? latitude;
  final double? longitude;
  final String? coverImageUrl;

  /// Index into the cover gradient palette (event-cover-image.util.ts).
  final int coverIndex;

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// One row of `GET /api/engagement/patients/{patientId}` (`EngagementRowResponse`).
class EngagementRow {
  const EngagementRow({
    required this.title,
    required this.status,
    this.activityType,
    this.score,
    this.progression,
    this.startDate,
    this.endDate,
  });

  factory EngagementRow.fromJson(Map<String, dynamic> json) => EngagementRow(
        title: (json['activityTitle'] as String?) ?? '',
        status: '${json['status'] ?? 'NOT_STARTED'}'.toUpperCase(),
        activityType: json['activityType'] as String?,
        score: _intOrNull(json['score']),
        progression: _intOrNull(json['progression']),
        startDate: DateTime.tryParse('${json['startDate'] ?? ''}'),
        endDate: DateTime.tryParse('${json['endDate'] ?? ''}'),
      );

  final String title;

  /// COMPLETED, IN_PROGRESS, NOT_STARTED or ABANDONED.
  final String status;

  /// QUIZ, GAME, VIDEO or EVENT.
  final String? activityType;
  final int? score;
  final int? progression;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get completed => status == 'COMPLETED';
}

class LearningProgress {
  const LearningProgress({
    required this.completedActivities,
    required this.totalTime,
    required this.averageScore,
    required this.history,
  });

  /// Aggregates the patient's engagement rows into the web tracking cards
  /// (completed activities, time spent, average score, last scores).
  factory LearningProgress.fromEngagement(List<EngagementRow> rows) {
    final completed = rows.where((r) => r.completed).toList()
      ..sort((a, b) => (a.endDate ?? DateTime(0)).compareTo(b.endDate ?? DateTime(0)));
    final scores = [for (final r in completed) if (r.score != null) r.score!.clamp(0, 100)];
    var spent = Duration.zero;
    for (final r in rows) {
      final start = r.startDate;
      final end = r.endDate;
      if (start != null && end != null && end.isAfter(start)) spent += end.difference(start);
    }
    return LearningProgress(
      completedActivities: completed.length,
      totalTime: _formatDuration(spent),
      averageScore: scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round(),
      history: scores.length > 10 ? scores.sublist(scores.length - 10) : scores,
    );
  }

  final int completedActivities;
  final String totalTime;
  final int averageScore;

  /// Last scores (percent), oldest first.
  final List<int> history;

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

int _int(Object? v) => _intOrNull(v) ?? 0;

int? _intOrNull(Object? v) => _numOrNull(v)?.round();

num? _numOrNull(Object? v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}
