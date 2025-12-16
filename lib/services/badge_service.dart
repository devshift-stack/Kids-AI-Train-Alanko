import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Badge types for different achievements
enum BadgeType {
  // Learning Badges
  firstLesson,
  tenLessons,
  fiftyLessons,
  hundredLessons,

  // Streak Badges
  threeDayStreak,
  sevenDayStreak,
  thirtyDayStreak,

  // Accuracy Badges
  perfectScore,
  tenPerfectScores,
  accuracyMaster,

  // Topic Badges
  mathExplorer,
  languageExplorer,
  scienceExplorer,

  // Special Badges
  earlyBird,
  nightOwl,
  weekendLearner,
  helpfulFriend,
}

/// Badge definition with metadata
class Badge {
  final BadgeType type;
  final String name;
  final String description;
  final String icon;
  final int requiredProgress;
  final bool isSecret;

  const Badge({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredProgress,
    this.isSecret = false,
  });

  static const Map<BadgeType, Badge> all = {
    // Learning Badges
    BadgeType.firstLesson: Badge(
      type: BadgeType.firstLesson,
      name: 'Erste Schritte',
      description: 'Erste Lektion abgeschlossen',
      icon: '🌟',
      requiredProgress: 1,
    ),
    BadgeType.tenLessons: Badge(
      type: BadgeType.tenLessons,
      name: 'Fleissiger Lerner',
      description: '10 Lektionen abgeschlossen',
      icon: '📚',
      requiredProgress: 10,
    ),
    BadgeType.fiftyLessons: Badge(
      type: BadgeType.fiftyLessons,
      name: 'Wissensjäger',
      description: '50 Lektionen abgeschlossen',
      icon: '🎯',
      requiredProgress: 50,
    ),
    BadgeType.hundredLessons: Badge(
      type: BadgeType.hundredLessons,
      name: 'Meisterschüler',
      description: '100 Lektionen abgeschlossen',
      icon: '🏆',
      requiredProgress: 100,
    ),

    // Streak Badges
    BadgeType.threeDayStreak: Badge(
      type: BadgeType.threeDayStreak,
      name: 'Durchstarter',
      description: '3 Tage in Folge gelernt',
      icon: '🔥',
      requiredProgress: 3,
    ),
    BadgeType.sevenDayStreak: Badge(
      type: BadgeType.sevenDayStreak,
      name: 'Wochenmeister',
      description: '7 Tage in Folge gelernt',
      icon: '💪',
      requiredProgress: 7,
    ),
    BadgeType.thirtyDayStreak: Badge(
      type: BadgeType.thirtyDayStreak,
      name: 'Monats-Champion',
      description: '30 Tage in Folge gelernt',
      icon: '👑',
      requiredProgress: 30,
    ),

    // Accuracy Badges
    BadgeType.perfectScore: Badge(
      type: BadgeType.perfectScore,
      name: 'Perfekt!',
      description: 'Alle Fragen richtig beantwortet',
      icon: '💯',
      requiredProgress: 1,
    ),
    BadgeType.tenPerfectScores: Badge(
      type: BadgeType.tenPerfectScores,
      name: 'Genauigkeitsprofi',
      description: '10 perfekte Runden',
      icon: '🎖️',
      requiredProgress: 10,
    ),
    BadgeType.accuracyMaster: Badge(
      type: BadgeType.accuracyMaster,
      name: 'Präzisionsmeister',
      description: '90% Genauigkeit über 50 Lektionen',
      icon: '🏅',
      requiredProgress: 50,
    ),

    // Topic Badges
    BadgeType.mathExplorer: Badge(
      type: BadgeType.mathExplorer,
      name: 'Mathe-Entdecker',
      description: '20 Mathe-Aufgaben gelöst',
      icon: '🔢',
      requiredProgress: 20,
    ),
    BadgeType.languageExplorer: Badge(
      type: BadgeType.languageExplorer,
      name: 'Sprach-Entdecker',
      description: '20 Sprach-Aufgaben gelöst',
      icon: '📖',
      requiredProgress: 20,
    ),
    BadgeType.scienceExplorer: Badge(
      type: BadgeType.scienceExplorer,
      name: 'Wissenschafts-Entdecker',
      description: '20 Wissenschafts-Aufgaben gelöst',
      icon: '🔬',
      requiredProgress: 20,
    ),

    // Special Badges (Secret)
    BadgeType.earlyBird: Badge(
      type: BadgeType.earlyBird,
      name: 'Frühaufsteher',
      description: 'Vor 8 Uhr gelernt',
      icon: '🌅',
      requiredProgress: 1,
      isSecret: true,
    ),
    BadgeType.nightOwl: Badge(
      type: BadgeType.nightOwl,
      name: 'Nachteule',
      description: 'Nach 20 Uhr gelernt',
      icon: '🦉',
      requiredProgress: 1,
      isSecret: true,
    ),
    BadgeType.weekendLearner: Badge(
      type: BadgeType.weekendLearner,
      name: 'Wochenend-Lerner',
      description: 'Am Wochenende gelernt',
      icon: '🎉',
      requiredProgress: 1,
      isSecret: true,
    ),
    BadgeType.helpfulFriend: Badge(
      type: BadgeType.helpfulFriend,
      name: 'Hilfsbereit',
      description: 'Einem Freund geholfen',
      icon: '🤝',
      requiredProgress: 1,
      isSecret: true,
    ),
  };
}

/// Earned badge with timestamp
class EarnedBadge {
  final BadgeType type;
  final DateTime earnedAt;

  EarnedBadge({required this.type, required this.earnedAt});

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'earnedAt': earnedAt.toIso8601String(),
      };

  factory EarnedBadge.fromJson(Map<String, dynamic> json) => EarnedBadge(
        type: BadgeType.values.firstWhere((e) => e.name == json['type']),
        earnedAt: DateTime.parse(json['earnedAt']),
      );
}

/// Badge progress tracker
class BadgeProgress {
  final Map<BadgeType, int> progress;

  BadgeProgress({Map<BadgeType, int>? progress})
      : progress = progress ?? {};

  int getProgress(BadgeType type) => progress[type] ?? 0;

  BadgeProgress copyWith({Map<BadgeType, int>? progress}) {
    return BadgeProgress(progress: progress ?? this.progress);
  }

  Map<String, dynamic> toJson() => progress.map(
        (key, value) => MapEntry(key.name, value),
      );

  factory BadgeProgress.fromJson(Map<String, dynamic> json) => BadgeProgress(
        progress: json.map(
          (key, value) => MapEntry(
            BadgeType.values.firstWhere((e) => e.name == key),
            value as int,
          ),
        ),
      );
}

/// Badge service state
class BadgeState {
  final List<EarnedBadge> earnedBadges;
  final BadgeProgress progress;
  final EarnedBadge? newlyEarnedBadge;

  BadgeState({
    this.earnedBadges = const [],
    BadgeProgress? progress,
    this.newlyEarnedBadge,
  }) : progress = progress ?? BadgeProgress();

  bool hasBadge(BadgeType type) =>
      earnedBadges.any((b) => b.type == type);

  BadgeState copyWith({
    List<EarnedBadge>? earnedBadges,
    BadgeProgress? progress,
    EarnedBadge? newlyEarnedBadge,
  }) {
    return BadgeState(
      earnedBadges: earnedBadges ?? this.earnedBadges,
      progress: progress ?? this.progress,
      newlyEarnedBadge: newlyEarnedBadge,
    );
  }
}

/// Badge service notifier
class BadgeNotifier extends StateNotifier<BadgeState> {
  final String profileId;

  BadgeNotifier({required this.profileId}) : super(BadgeState()) {
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgesJson = prefs.getString('badges_$profileId');
      final progressJson = prefs.getString('badge_progress_$profileId');

      List<EarnedBadge> badges = [];
      BadgeProgress progress = BadgeProgress();

      if (badgesJson != null) {
        final List<dynamic> decoded = jsonDecode(badgesJson);
        badges = decoded.map((e) => EarnedBadge.fromJson(e)).toList();
      }

      if (progressJson != null) {
        progress = BadgeProgress.fromJson(jsonDecode(progressJson));
      }

      state = BadgeState(earnedBadges: badges, progress: progress);
    } catch (e) {
      debugPrint('Badge Load Error: $e');
    }
  }

  Future<void> _saveBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'badges_$profileId',
        jsonEncode(state.earnedBadges.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'badge_progress_$profileId',
        jsonEncode(state.progress.toJson()),
      );
    } catch (e) {
      debugPrint('Badge Save Error: $e');
    }
  }

  /// Record lesson completion
  Future<void> recordLessonCompleted({
    required String topic,
    required int score,
    required int totalQuestions,
  }) async {
    final newProgress = Map<BadgeType, int>.from(state.progress.progress);

    // Increment lesson count
    newProgress[BadgeType.firstLesson] =
        (newProgress[BadgeType.firstLesson] ?? 0) + 1;
    newProgress[BadgeType.tenLessons] =
        (newProgress[BadgeType.tenLessons] ?? 0) + 1;
    newProgress[BadgeType.fiftyLessons] =
        (newProgress[BadgeType.fiftyLessons] ?? 0) + 1;
    newProgress[BadgeType.hundredLessons] =
        (newProgress[BadgeType.hundredLessons] ?? 0) + 1;

    // Check for perfect score
    if (score == totalQuestions && totalQuestions > 0) {
      newProgress[BadgeType.perfectScore] =
          (newProgress[BadgeType.perfectScore] ?? 0) + 1;
      newProgress[BadgeType.tenPerfectScores] =
          (newProgress[BadgeType.tenPerfectScores] ?? 0) + 1;
    }

    // Topic-specific progress
    if (topic.toLowerCase().contains('math') || topic.toLowerCase().contains('mathe')) {
      newProgress[BadgeType.mathExplorer] =
          (newProgress[BadgeType.mathExplorer] ?? 0) + 1;
    } else if (topic.toLowerCase().contains('language') ||
        topic.toLowerCase().contains('sprache')) {
      newProgress[BadgeType.languageExplorer] =
          (newProgress[BadgeType.languageExplorer] ?? 0) + 1;
    } else if (topic.toLowerCase().contains('science') ||
        topic.toLowerCase().contains('wissenschaft')) {
      newProgress[BadgeType.scienceExplorer] =
          (newProgress[BadgeType.scienceExplorer] ?? 0) + 1;
    }

    // Check time-based badges
    final now = DateTime.now();
    if (now.hour < 8) {
      newProgress[BadgeType.earlyBird] = 1;
    }
    if (now.hour >= 20) {
      newProgress[BadgeType.nightOwl] = 1;
    }
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      newProgress[BadgeType.weekendLearner] = 1;
    }

    state = state.copyWith(
      progress: BadgeProgress(progress: newProgress),
    );

    await _checkAndAwardBadges();
    await _saveBadges();
  }

  /// Record daily streak
  Future<void> recordDailyActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityStr = prefs.getString('last_activity_$profileId');
    final streakCount = prefs.getInt('streak_$profileId') ?? 0;

    final today = DateTime.now();
    int newStreak = 1;

    if (lastActivityStr != null) {
      final lastActivity = DateTime.parse(lastActivityStr);
      final difference = today.difference(lastActivity).inDays;

      if (difference == 1) {
        newStreak = streakCount + 1;
      } else if (difference == 0) {
        newStreak = streakCount; // Same day
      }
    }

    await prefs.setString('last_activity_$profileId', today.toIso8601String());
    await prefs.setInt('streak_$profileId', newStreak);

    final newProgress = Map<BadgeType, int>.from(state.progress.progress);
    newProgress[BadgeType.threeDayStreak] = newStreak;
    newProgress[BadgeType.sevenDayStreak] = newStreak;
    newProgress[BadgeType.thirtyDayStreak] = newStreak;

    state = state.copyWith(
      progress: BadgeProgress(progress: newProgress),
    );

    await _checkAndAwardBadges();
    await _saveBadges();
  }

  Future<void> _checkAndAwardBadges() async {
    for (final entry in Badge.all.entries) {
      final badgeType = entry.key;
      final badge = entry.value;

      if (state.hasBadge(badgeType)) continue;

      final currentProgress = state.progress.getProgress(badgeType);
      if (currentProgress >= badge.requiredProgress) {
        await _awardBadge(badgeType);
      }
    }
  }

  Future<void> _awardBadge(BadgeType type) async {
    final newBadge = EarnedBadge(type: type, earnedAt: DateTime.now());
    final newBadges = [...state.earnedBadges, newBadge];

    state = state.copyWith(
      earnedBadges: newBadges,
      newlyEarnedBadge: newBadge,
    );

    debugPrint('Badge earned: ${Badge.all[type]?.name}');
  }

  /// Clear the newly earned badge notification
  void clearNewBadgeNotification() {
    state = state.copyWith(newlyEarnedBadge: null);
  }

  /// Get all visible badges (earned + locked)
  List<(Badge, bool, int)> getAllBadges() {
    return Badge.all.entries.map((entry) {
      final badge = entry.value;
      final isEarned = state.hasBadge(entry.key);
      final progress = state.progress.getProgress(entry.key);

      // Hide secret badges that aren't earned
      if (badge.isSecret && !isEarned) {
        return null;
      }

      return (badge, isEarned, progress);
    }).whereType<(Badge, bool, int)>().toList();
  }
}

// Provider factory for profile-specific badge service
final badgeServiceProvider =
    StateNotifierProvider.family<BadgeNotifier, BadgeState, String>(
  (ref, profileId) => BadgeNotifier(profileId: profileId),
);
