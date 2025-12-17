import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen Tracking
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // User Actions
  static Future<void> logUserAction(String action, {Map<String, Object>? params}) async {
    await _analytics.logEvent(name: action, parameters: params);
  }

  // Session Tracking
  static Future<void> logSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
  }

  static Future<void> logSessionEnd(int durationSeconds) async {
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {'duration_seconds': durationSeconds},
    );
  }

  // Game/Feature Tracking
  static Future<void> logGameStart(String gameName) async {
    await _analytics.logEvent(
      name: 'game_start',
      parameters: {'game_name': gameName},
    );
  }

  static Future<void> logGameEnd(String gameName, int score, int playTimeSeconds) async {
    await _analytics.logEvent(
      name: 'game_end',
      parameters: {
        'game_name': gameName,
        'score': score,
        'play_time_seconds': playTimeSeconds,
      },
    );
  }

  // Funnel Tracking (wo brechen Nutzer ab)
  static Future<void> logFunnelStep(String funnelName, int step, {bool completed = false}) async {
    await _analytics.logEvent(
      name: 'funnel_step',
      parameters: {
        'funnel_name': funnelName,
        'step': step,
        'completed': completed,
      },
    );
  }

  // Button/Feature Usage
  static Future<void> logButtonClick(String buttonName, String screenName) async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        'screen_name': screenName,
      },
    );
  }

  // User Properties
  static Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
