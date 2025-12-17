import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'age_adaptive_service.dart' show sharedPreferencesProvider;

/// Service to manage app rating prompts
class AppRatingService {
  final InAppReview _inAppReview = InAppReview.instance;
  final SharedPreferences _prefs;

  static const String _keySessionCount = 'app_rating_session_count';
  static const String _keyHasRated = 'app_rating_has_rated';
  static const String _keyLastPrompt = 'app_rating_last_prompt';
  static const String _keyLessonsCompleted = 'app_rating_lessons_completed';

  // Configuration
  static const int minSessionsBeforePrompt = 5;
  static const int minLessonsBeforePrompt = 10;
  static const int daysBetweenPrompts = 14;

  AppRatingService(this._prefs);

  /// Record a new app session
  Future<void> recordSession() async {
    final currentCount = _prefs.getInt(_keySessionCount) ?? 0;
    await _prefs.setInt(_keySessionCount, currentCount + 1);
    debugPrint('AppRating: Session count: ${currentCount + 1}');
  }

  /// Record a lesson completion
  Future<void> recordLessonCompleted() async {
    final currentCount = _prefs.getInt(_keyLessonsCompleted) ?? 0;
    await _prefs.setInt(_keyLessonsCompleted, currentCount + 1);
  }

  /// Check if we should prompt for rating
  Future<bool> shouldPromptForRating() async {
    // Already rated?
    if (_prefs.getBool(_keyHasRated) ?? false) {
      return false;
    }

    // Check minimum sessions
    final sessionCount = _prefs.getInt(_keySessionCount) ?? 0;
    if (sessionCount < minSessionsBeforePrompt) {
      return false;
    }

    // Check minimum lessons
    final lessonsCount = _prefs.getInt(_keyLessonsCompleted) ?? 0;
    if (lessonsCount < minLessonsBeforePrompt) {
      return false;
    }

    // Check if enough days passed since last prompt
    final lastPromptStr = _prefs.getString(_keyLastPrompt);
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.parse(lastPromptStr);
      final daysSincePrompt = DateTime.now().difference(lastPrompt).inDays;
      if (daysSincePrompt < daysBetweenPrompts) {
        return false;
      }
    }

    // Check if review is available on this platform
    final isAvailable = await _inAppReview.isAvailable();
    return isAvailable;
  }

  /// Request in-app review
  Future<bool> requestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        await _inAppReview.requestReview();
        await _prefs.setString(_keyLastPrompt, DateTime.now().toIso8601String());
        debugPrint('AppRating: Review requested');
        return true;
      } else {
        debugPrint('AppRating: In-app review not available');
        return false;
      }
    } catch (e) {
      debugPrint('AppRating Error: $e');
      return false;
    }
  }

  /// Open store listing (fallback)
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'YOUR_APP_STORE_ID', // Replace with actual App Store ID
      );
    } catch (e) {
      debugPrint('AppRating Store Error: $e');
    }
  }

  /// Mark as rated (user said "Don't ask again")
  Future<void> markAsRated() async {
    await _prefs.setBool(_keyHasRated, true);
    debugPrint('AppRating: Marked as rated');
  }

  /// Mark as "remind later"
  Future<void> remindLater() async {
    await _prefs.setString(_keyLastPrompt, DateTime.now().toIso8601String());
    debugPrint('AppRating: Will remind later');
  }
}

// Provider
final appRatingServiceProvider = Provider<AppRatingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppRatingService(prefs);
});
