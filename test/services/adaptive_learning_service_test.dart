import 'package:flutter_test/flutter_test.dart';
import 'package:alanko_ai/services/adaptive_learning_service.dart';

void main() {
  group('GameType', () {
    test('has all expected game types', () {
      expect(GameType.values.length, 6);
      expect(GameType.values, contains(GameType.letters));
      expect(GameType.values, contains(GameType.numbers));
      expect(GameType.values, contains(GameType.colors));
      expect(GameType.values, contains(GameType.shapes));
      expect(GameType.values, contains(GameType.animals));
      expect(GameType.values, contains(GameType.stories));
    });
  });

  group('ExerciseResult', () {
    test('creates result with all fields', () {
      final result = ExerciseResult(
        correct: true,
        responseTimeMs: 2500,
        timestamp: DateTime(2025, 1, 1),
        difficultyLevel: 1.0,
      );

      expect(result.correct, true);
      expect(result.responseTimeMs, 2500);
      expect(result.timestamp, DateTime(2025, 1, 1));
      expect(result.difficultyLevel, 1.0);
    });

    test('toJson and fromJson work correctly', () {
      final original = ExerciseResult(
        correct: false,
        responseTimeMs: 3000,
        timestamp: DateTime(2025, 6, 15, 10, 30),
        difficultyLevel: 1.2,
      );

      final json = original.toJson();
      final restored = ExerciseResult.fromJson(json);

      expect(restored.correct, original.correct);
      expect(restored.responseTimeMs, original.responseTimeMs);
      expect(restored.difficultyLevel, original.difficultyLevel);
      expect(restored.timestamp.year, original.timestamp.year);
      expect(restored.timestamp.month, original.timestamp.month);
      expect(restored.timestamp.day, original.timestamp.day);
    });
  });

  group('GamePerformance', () {
    test('initializes with default values', () {
      final performance = GamePerformance(gameType: GameType.letters);

      expect(performance.results, isEmpty);
      expect(performance.currentDifficulty, 1.0);
      expect(performance.gameType, GameType.letters);
    });

    test('getRecentAccuracy returns 0.5 for empty results', () {
      final performance = GamePerformance(gameType: GameType.numbers);
      expect(performance.getRecentAccuracy(10), 0.5);
    });

    test('getRecentAccuracy calculates correctly', () {
      final performance = GamePerformance(gameType: GameType.colors);

      // Add 10 results: 7 correct, 3 wrong = 70%
      for (int i = 0; i < 7; i++) {
        performance.results.add(ExerciseResult(
          correct: true,
          responseTimeMs: 2000,
          timestamp: DateTime.now(),
          difficultyLevel: 1.0,
        ));
      }
      for (int i = 0; i < 3; i++) {
        performance.results.add(ExerciseResult(
          correct: false,
          responseTimeMs: 2000,
          timestamp: DateTime.now(),
          difficultyLevel: 1.0,
        ));
      }

      expect(performance.getRecentAccuracy(10), 0.7);
    });

    test('getAverageResponseTime returns 5000 for empty results', () {
      final performance = GamePerformance(gameType: GameType.shapes);
      expect(performance.getAverageResponseTime(10), 5000);
    });

    test('getAverageResponseTime calculates correctly', () {
      final performance = GamePerformance(gameType: GameType.animals);

      performance.results.add(ExerciseResult(
        correct: true,
        responseTimeMs: 1000,
        timestamp: DateTime.now(),
        difficultyLevel: 1.0,
      ));
      performance.results.add(ExerciseResult(
        correct: true,
        responseTimeMs: 3000,
        timestamp: DateTime.now(),
        difficultyLevel: 1.0,
      ));

      expect(performance.getAverageResponseTime(10), 2000);
    });

    test('toJson and fromJson preserve all data', () {
      final original = GamePerformance(gameType: GameType.stories);
      original.currentDifficulty = 1.5;
      original.results.add(ExerciseResult(
        correct: true,
        responseTimeMs: 2500,
        timestamp: DateTime.now(),
        difficultyLevel: 1.5,
      ));

      final json = original.toJson();
      final restored = GamePerformance.fromJson(json);

      expect(restored.currentDifficulty, original.currentDifficulty);
      expect(restored.gameType, original.gameType);
      expect(restored.results.length, original.results.length);
      expect(restored.results.first.correct, original.results.first.correct);
    });
  });

  // Note: AdaptiveLearningService requires Riverpod Ref and SharedPreferences
  // Full integration tests would need a test environment with mocked dependencies
}
