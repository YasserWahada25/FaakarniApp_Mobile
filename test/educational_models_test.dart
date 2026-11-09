import 'package:fakarniapp/core/config/api_config.dart';
import 'package:fakarniapp/models/educational.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity maps API type/gameType and splits video metadata', () {
    final memory = EducationalActivity.fromJson({
      'id': 3,
      'title': 'Paires',
      'type': 'GAME',
      'gameType': 'memory_match',
      'status': 'ACTIVE',
      'latestScorePercent': 80.4,
      'thumbnailUrl': '/uploads/activities/a.png',
    });
    expect(memory.type, ActivityType.imageGame);
    expect(memory.lastScore, 80);
    expect(memory.thumbnailUrl, '${ApiConfig.baseUrl}/uploads/activities/a.png');

    final video = EducationalActivity.fromJson({
      'id': 4,
      'title': 'Vidéo',
      'type': 'VIDEO',
      'status': 'INACTIVE',
      'description': 'Intro\n__VIDEO_URL__:https://youtu.be/x\n__VIDEO_DURATION__:12',
    });
    expect(video.type, ActivityType.video);
    expect(video.active, isFalse);
    expect(video.description, 'Intro');
    expect(video.videoUrl, 'https://youtu.be/x');
    expect(video.durationMin, 12);
  });

  test('game session parses questions with image options', () {
    final s = GameSession.fromJson({
      'sessionId': 10,
      'activityId': 2,
      'questions': [
        {
          'id': 5,
          'prompt': 'Quel animal ?',
          'questionImageUrl': 'https://x/img.png',
          'options': ['Chat', 'Chien'],
          'quizOptions': [
            {'label': 'Chat', 'imageUrl': '/uploads/questions/c.png'},
            {'label': 'Chien'},
          ],
        },
      ],
    });
    expect(s.totalQuestions, 1);
    expect(s.questions.single.imageUrl, 'https://x/img.png');
    expect(s.questions.single.options.first.imageUrl, endsWith('/uploads/questions/c.png'));
    expect(s.questions.single.options.last.imageUrl, isNull);
  });

  test('result and answer feedback follow web game-result rules', () {
    final f = AnswerFeedback.fromJson({
      'correct': true,
      'sessionFinished': true,
      'sessionResult': {
        'status': 'FAILURE',
        'scorePercent': 40,
        'answers': [
          {'prompt': 'Q', 'userAnswer': 'A', 'expectedAnswer': 'B', 'correct': false},
        ],
      },
    });
    expect(f.result!.outcome, GameOutcome.failure);
    expect(f.result!.scorePercent, 40);
    expect(f.result!.answers.single.expectedAnswer, 'B');
  });

  test('progress aggregates engagement rows', () {
    final p = LearningProgress.fromEngagement([
      EngagementRow.fromJson({
        'status': 'COMPLETED',
        'score': 80,
        'startDate': '2026-10-01T10:00:00',
        'endDate': '2026-10-01T10:30:00',
      }),
      EngagementRow.fromJson({
        'status': 'COMPLETED',
        'score': 60,
        'startDate': '2026-10-02T10:00:00',
        'endDate': '2026-10-02T11:15:00',
      }),
      EngagementRow.fromJson({'status': 'IN_PROGRESS'}),
    ]);
    expect(p.completedActivities, 2);
    expect(p.averageScore, 70);
    expect(p.totalTime, '1h 45m');
    expect(p.history, [80, 60]);
  });

  test('event keeps missing coordinates as null', () {
    final e = EducationalEvent.fromJson({'id': 1, 'title': 'Atelier', 'startDateTime': '2026-11-01T14:00:00'});
    expect(e.hasCoordinates, isFalse);
    expect(e.startDateTime, DateTime(2026, 11, 1, 14));
  });

  test('media URLs resolve against the gateway, localhost ones included', () {
    expect(ApiConfig.resolveMedia('/uploads/events/a.png'), '${ApiConfig.baseUrl}/uploads/events/a.png');
    expect(ApiConfig.resolveMedia('http://localhost:8087/uploads/events/b.png'), '${ApiConfig.baseUrl}/uploads/events/b.png');
    expect(ApiConfig.resolveMedia('https://cdn.example.com/c.png'), 'https://cdn.example.com/c.png');
    expect(ApiConfig.resolveMedia('  '), isNull);
  });
}
