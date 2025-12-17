import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

/// Home Screen Widget Service for displaying streak/progress
class HomeWidgetService {
  static const String appGroupId = 'group.com.alanko.ai.widget';
  static const String iOSWidgetName = 'AlankoWidget';
  static const String androidWidgetName = 'AlankoWidgetProvider';

  /// Initialize home widget
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      HomeWidget.widgetClicked.listen(_onWidgetClicked);
      debugPrint('HomeWidget: Initialized');
    } catch (e) {
      debugPrint('HomeWidget Init Error: $e');
    }
  }

  void _onWidgetClicked(Uri? uri) {
    if (uri == null) return;
    debugPrint('HomeWidget: Clicked with URI: $uri');
  }

  /// Update widget data
  Future<void> updateWidget({
    required String childName,
    required int currentStreak,
    required int lessonsToday,
    required int totalBadges,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('child_name', childName);
      await HomeWidget.saveWidgetData<int>('current_streak', currentStreak);
      await HomeWidget.saveWidgetData<int>('lessons_today', lessonsToday);
      await HomeWidget.saveWidgetData<int>('total_badges', totalBadges);
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );

      debugPrint('HomeWidget: Updated - Streak: $currentStreak, Lessons: $lessonsToday');
    } catch (e) {
      debugPrint('HomeWidget Update Error: $e');
    }
  }

  /// Update streak only
  Future<void> updateStreak(int streak) async {
    try {
      await HomeWidget.saveWidgetData<int>('current_streak', streak);
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidget Streak Error: $e');
    }
  }

  /// Update lessons count
  Future<void> updateLessonsToday(int count) async {
    try {
      await HomeWidget.saveWidgetData<int>('lessons_today', count);
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidget Lessons Error: $e');
    }
  }
}

// Provider
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});
