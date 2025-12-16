import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_service.dart';

/// Game types for tracking performance
enum GameType {
  letters,
  numbers,
  colors,
  shapes,
  animals,
  stories,
}

/// Performance record for a single exercise
class ExerciseResult {
  final DateTime timestamp;
  final bool correct;
  final int responseTimeMs;
  final double difficultyLevel;

  ExerciseResult({
    required this.timestamp,
    required this.correct,
    required this.responseTimeMs,
    required this.difficultyLevel,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'correct': correct,
    'responseTimeMs': responseTimeMs,
    'difficultyLevel': difficultyLevel,
  };

  factory ExerciseResult.fromJson(Map<String, dynamic> json) => ExerciseResult(
    timestamp: DateTime.parse(json['timestamp']),
    correct: json['correct'],
    responseTimeMs: json['responseTimeMs'],
    difficultyLevel: json['difficultyLevel'],
  );
}

/// Game performance data
class GamePerformance {
  final GameType gameType;
  final List<ExerciseResult> results;
  double currentDifficulty;
  int averageResponseTimeMs;

  GamePerformance({
    required this.gameType,
    List<ExerciseResult>? results,
    this.currentDifficulty = 1.0,
    this.averageResponseTimeMs = 5000,
  }) : results = results ?? [];

  /// Get accuracy for last N exercises
  double getRecentAccuracy(int count) {
    if (results.isEmpty) return 0.5;
    final recent = results.length > count
        ? results.sublist(results.length - count)
        : results;
    final correct = recent.where((r) => r.correct).length;
    return correct / recent.length;
  }

  /// Get average response time for last N exercises
  int getAverageResponseTime(int count) {
    if (results.isEmpty) return 5000;
    final recent = results.length > count
        ? results.sublist(results.length - count)
        : results;
    final total = recent.fold<int>(0, (sum, r) => sum + r.responseTimeMs);
    return total ~/ recent.length;
  }

  Map<String, dynamic> toJson() => {
    'gameType': gameType.name,
    'results': results.map((r) => r.toJson()).toList(),
    'currentDifficulty': currentDifficulty,
    'averageResponseTimeMs': averageResponseTimeMs,
  };

  factory GamePerformance.fromJson(Map<String, dynamic> json) {
    return GamePerformance(
      gameType: GameType.values.firstWhere((g) => g.name == json['gameType']),
      results: (json['results'] as List?)
          ?.map((r) => ExerciseResult.fromJson(r))
          .toList() ?? [],
      currentDifficulty: json['currentDifficulty'] ?? 1.0,
      averageResponseTimeMs: json['averageResponseTimeMs'] ?? 5000,
    );
  }
}

/// Adaptive Learning Service - manages difficulty and timing per game per child
class AdaptiveLearningService {
  static const String _storageKey = 'adaptive_learning_data';

  final Ref _ref;
  Map<String, Map<GameType, GamePerformance>> _profilePerformance = {};

  AdaptiveLearningService(this._ref) {
    _loadData();
  }

  /// Load saved performance data
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _profilePerformance = {};
        data.forEach((profileId, games) {
          _profilePerformance[profileId] = {};
          (games as Map<String, dynamic>).forEach((gameKey, perfData) {
            final gameType = GameType.values.firstWhere((g) => g.name == gameKey);
            _profilePerformance[profileId]![gameType] = GamePerformance.fromJson(perfData);
          });
        });
      } catch (e) {
        _profilePerformance = {};
      }
    }
  }

  /// Save performance data
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    _profilePerformance.forEach((profileId, games) {
      data[profileId] = {};
      games.forEach((gameType, perf) {
        data[profileId][gameType.name] = perf.toJson();
      });
    });
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Get current profile ID
  String _getCurrentProfileId() {
    final profile = _ref.read(activeProfileProvider);
    return profile?.id ?? 'default';
  }

  /// Get or create performance record for game
  GamePerformance _getGamePerformance(GameType gameType) {
    final profileId = _getCurrentProfileId();
    _profilePerformance[profileId] ??= {};
    _profilePerformance[profileId]![gameType] ??= GamePerformance(
      gameType: gameType,
      currentDifficulty: _getInitialDifficulty(),
    );
    return _profilePerformance[profileId]![gameType]!;
  }

  /// Get initial difficulty based on age
  double _getInitialDifficulty() {
    final profile = _ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;

    if (age <= 4) return 0.5;  // Very easy
    if (age <= 6) return 0.7;  // Easy
    if (age <= 8) return 1.0;  // Normal
    if (age <= 10) return 1.3; // Medium
    return 1.5;                 // Harder
  }

  /// Record an exercise result
  Future<void> recordResult({
    required GameType gameType,
    required bool correct,
    required int responseTimeMs,
  }) async {
    final performance = _getGamePerformance(gameType);

    performance.results.add(ExerciseResult(
      timestamp: DateTime.now(),
      correct: correct,
      responseTimeMs: responseTimeMs,
      difficultyLevel: performance.currentDifficulty,
    ));

    // Keep only last 100 results to save storage
    if (performance.results.length > 100) {
      performance.results.removeRange(0, performance.results.length - 100);
    }

    // Update average response time
    performance.averageResponseTimeMs = performance.getAverageResponseTime(10);

    // Check if difficulty should be adjusted (every 10 exercises)
    if (performance.results.length % 10 == 0) {
      _adjustDifficulty(performance);
    }

    await _saveData();
  }

  /// Adjust difficulty based on recent performance
  void _adjustDifficulty(GamePerformance performance) {
    final accuracy = performance.getRecentAccuracy(10);

    if (accuracy >= 0.7) {
      // Child is doing well - increase difficulty by 10%
      performance.currentDifficulty = (performance.currentDifficulty * 1.1).clamp(0.3, 2.0);
    } else if (accuracy < 0.5) {
      // Child is struggling - decrease difficulty by 10%
      performance.currentDifficulty = (performance.currentDifficulty * 0.9).clamp(0.3, 2.0);
    }
    // If 50-70%, keep same difficulty
  }

  /// Get current difficulty level for a game (1.0 = normal)
  double getDifficulty(GameType gameType) {
    return _getGamePerformance(gameType).currentDifficulty;
  }

  /// Get recommended delay before next question (in milliseconds)
  /// Adapts to child's pace
  int getNextQuestionDelay(GameType gameType) {
    final performance = _getGamePerformance(gameType);
    final avgTime = performance.averageResponseTimeMs;
    final accuracy = performance.getRecentAccuracy(5);

    // Base delay after answer shown
    int baseDelay = 1500;

    if (accuracy < 0.5) {
      // Child struggling - give more time to understand
      baseDelay = 2500;
    } else if (accuracy >= 0.8) {
      // Child doing great - can move faster
      baseDelay = 1000;
    }

    // Adjust based on response time
    if (avgTime > 8000) {
      // Child is slow - add more thinking time
      baseDelay += 500;
    } else if (avgTime < 3000) {
      // Child is fast - can reduce delay
      baseDelay -= 300;
    }

    return baseDelay.clamp(800, 4000);
  }

  /// Get difficulty-adjusted parameters for games
  Map<String, dynamic> getGameParameters(GameType gameType) {
    final difficulty = getDifficulty(gameType);
    final profile = _ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;

    switch (gameType) {
      case GameType.letters:
        return {
          'includeHardLetters': difficulty > 1.2, // Q, X, Y for higher difficulty
          'showHint': difficulty < 0.8,
          'optionCount': difficulty < 0.8 ? 3 : 4,
        };

      case GameType.numbers:
        final maxNum = (difficulty * 10 * (age / 6)).round().clamp(5, 100);
        return {
          'maxNumber': maxNum,
          'includeSubtraction': difficulty > 0.9 && age >= 5,
          'includeMultiplication': difficulty > 1.3 && age >= 7,
          'optionCount': difficulty < 0.8 ? 3 : 4,
        };

      case GameType.colors:
        return {
          'includeAdvancedColors': difficulty > 1.0, // purple, orange, etc.
          'questionType': difficulty > 1.2 ? 'mixed' : 'simple',
          'optionCount': difficulty < 0.8 ? 3 : difficulty > 1.2 ? 5 : 4,
        };

      case GameType.shapes:
        return {
          'includeAdvancedShapes': difficulty > 1.0, // pentagon, hexagon
          'askSides': difficulty > 0.9,
          'optionCount': difficulty < 0.8 ? 3 : 4,
        };

      case GameType.animals:
        return {
          'includeExoticAnimals': difficulty > 1.0,
          'askHabitat': difficulty > 1.2,
          'askDiet': difficulty > 1.3,
        };

      case GameType.stories:
        return {
          'storyLength': difficulty < 0.8 ? 'short' : difficulty > 1.2 ? 'medium' : 'normal',
          'vocabulary': difficulty < 0.8 ? 'simple' : 'normal',
        };
    }
  }

  /// Get performance summary for a game
  Map<String, dynamic> getPerformanceSummary(GameType gameType) {
    final performance = _getGamePerformance(gameType);
    return {
      'totalExercises': performance.results.length,
      'recentAccuracy': (performance.getRecentAccuracy(10) * 100).round(),
      'currentDifficulty': performance.currentDifficulty,
      'averageResponseTime': performance.averageResponseTimeMs,
    };
  }

  /// Reset progress for a game (for testing or user request)
  Future<void> resetGame(GameType gameType) async {
    final profileId = _getCurrentProfileId();
    _profilePerformance[profileId]?.remove(gameType);
    await _saveData();
  }
}

// Provider
final adaptiveLearningServiceProvider = Provider<AdaptiveLearningService>((ref) {
  return AdaptiveLearningService(ref);
});
