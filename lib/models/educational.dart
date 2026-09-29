/// Educational module models (web `educational-activity.model.ts`,
/// `educational-event.model.ts`, quiz/memory/puzzle sessions).
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
}

class EducationalActivity {
  const EducationalActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.lastScore,
    this.durationMin,
    this.contentText,
    this.videoUrl,
  });

  final int id;
  final String name;
  final String description;
  final ActivityType type;
  final int? lastScore;
  final int? durationMin;
  final String? contentText;
  final String? videoUrl;

  EducationalActivity withScore(int score) => EducationalActivity(
        id: id,
        name: name,
        description: description,
        type: type,
        lastScore: score,
        durationMin: durationMin,
        contentText: contentText,
        videoUrl: videoUrl,
      );
}

/// A quiz question. Options carry an emoji used as the "image" of the
/// image-recognition game (no network images in phase 1).
class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    this.sceneEmoji,
  });

  final String prompt;
  final List<QuizOption> options;
  final String answer;
  final String? sceneEmoji;
}

class QuizOption {
  const QuizOption(this.label, [this.emoji]);

  final String label;
  final String? emoji;
}

class MemoryCardData {
  const MemoryCardData({required this.id, required this.pairKey, required this.emoji, required this.label});

  final int id;
  final String pairKey;
  final String emoji;
  final String label;
}

enum GameOutcome { success, failure, neutral }

class AnswerDetail {
  const AnswerDetail({
    required this.prompt,
    required this.userAnswer,
    required this.expectedAnswer,
    required this.correct,
  });

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
    required this.latitude,
    required this.longitude,
    required this.coverIndex,
  });

  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime? startDateTime;
  final bool remindEnabled;
  final double latitude;
  final double longitude;

  /// Index into the cover gradient palette (event-cover-image.util.ts).
  final int coverIndex;
}

class LearningProgress {
  const LearningProgress({
    required this.completedActivities,
    required this.totalTime,
    required this.averageScore,
    required this.history,
  });

  final int completedActivities;
  final String totalTime;
  final int averageScore;

  /// Last scores (percent), oldest first.
  final List<int> history;
}
