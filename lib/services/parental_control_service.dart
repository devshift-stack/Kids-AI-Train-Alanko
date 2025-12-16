import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'age_adaptive_service.dart' show sharedPreferencesProvider;

/// Parental control settings for YouTube reward system
class ParentalControlSettings {
  final bool youtubeRewardEnabled;
  final int videoMinutesAllowed; // Minutes of video before tasks required
  final int tasksRequired; // Number of tasks to complete
  final List<String> approvedVideoIds; // Curated safe video IDs
  final bool parentPinRequired;
  final String? parentPin;

  const ParentalControlSettings({
    this.youtubeRewardEnabled = false,
    this.videoMinutesAllowed = 10,
    this.tasksRequired = 3,
    this.approvedVideoIds = const [],
    this.parentPinRequired = true,
    this.parentPin,
  });

  ParentalControlSettings copyWith({
    bool? youtubeRewardEnabled,
    int? videoMinutesAllowed,
    int? tasksRequired,
    List<String>? approvedVideoIds,
    bool? parentPinRequired,
    String? parentPin,
  }) {
    return ParentalControlSettings(
      youtubeRewardEnabled: youtubeRewardEnabled ?? this.youtubeRewardEnabled,
      videoMinutesAllowed: videoMinutesAllowed ?? this.videoMinutesAllowed,
      tasksRequired: tasksRequired ?? this.tasksRequired,
      approvedVideoIds: approvedVideoIds ?? this.approvedVideoIds,
      parentPinRequired: parentPinRequired ?? this.parentPinRequired,
      parentPin: parentPin ?? this.parentPin,
    );
  }

  Map<String, dynamic> toJson() => {
    'youtubeRewardEnabled': youtubeRewardEnabled,
    'videoMinutesAllowed': videoMinutesAllowed,
    'tasksRequired': tasksRequired,
    'approvedVideoIds': approvedVideoIds,
    'parentPinRequired': parentPinRequired,
    'parentPin': parentPin,
  };

  factory ParentalControlSettings.fromJson(Map<String, dynamic> json) {
    return ParentalControlSettings(
      youtubeRewardEnabled: json['youtubeRewardEnabled'] ?? false,
      videoMinutesAllowed: json['videoMinutesAllowed'] ?? 10,
      tasksRequired: json['tasksRequired'] ?? 3,
      approvedVideoIds: List<String>.from(json['approvedVideoIds'] ?? []),
      parentPinRequired: json['parentPinRequired'] ?? true,
      parentPin: json['parentPin'],
    );
  }

  // Default curated safe videos for kids
  static const List<String> defaultSafeVideos = [
    'dQw4w9WgXcQ', // Example - replace with actual kid-safe videos
    // Add more curated video IDs here
  ];
}

/// Video watch session tracking
class VideoWatchSession {
  final DateTime startTime;
  final int secondsWatched;
  final bool tasksPending;
  final int tasksCompleted;

  const VideoWatchSession({
    required this.startTime,
    this.secondsWatched = 0,
    this.tasksPending = false,
    this.tasksCompleted = 0,
  });

  VideoWatchSession copyWith({
    DateTime? startTime,
    int? secondsWatched,
    bool? tasksPending,
    int? tasksCompleted,
  }) {
    return VideoWatchSession(
      startTime: startTime ?? this.startTime,
      secondsWatched: secondsWatched ?? this.secondsWatched,
      tasksPending: tasksPending ?? this.tasksPending,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    );
  }
}

/// Parental Control Service
class ParentalControlService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  ParentalControlSettings _settings = const ParentalControlSettings();
  VideoWatchSession? _currentSession;

  ParentalControlSettings get settings => _settings;
  VideoWatchSession? get currentSession => _currentSession;

  ParentalControlService(this._prefs) {
    _loadLocalSettings();
  }

  // Load settings from local storage
  void _loadLocalSettings() {
    final json = _prefs.getString('parental_control_settings');
    if (json != null) {
      try {
        _settings = ParentalControlSettings.fromJson(jsonDecode(json));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading parental settings: $e');
      }
    }
  }

  // Save settings locally
  Future<void> _saveLocalSettings() async {
    await _prefs.setString(
      'parental_control_settings',
      jsonEncode(_settings.toJson()),
    );
  }

  // Update settings
  Future<void> updateSettings(ParentalControlSettings newSettings) async {
    _settings = newSettings;
    await _saveLocalSettings();
    notifyListeners();
  }

  // Sync settings from Firebase (called by ParentDash)
  Future<void> syncFromFirebase(String parentId) async {
    try {
      final doc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('settings')
          .doc('parental_control')
          .get();

      if (doc.exists && doc.data() != null) {
        _settings = ParentalControlSettings.fromJson(doc.data()!);
        await _saveLocalSettings();
        notifyListeners();
        debugPrint('Parental settings synced from Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing parental settings: $e');
    }
  }

  // Save settings to Firebase (for ParentDash)
  Future<void> saveToFirebase(String parentId) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('settings')
          .doc('parental_control')
          .set(_settings.toJson());
      debugPrint('Parental settings saved to Firebase');
    } catch (e) {
      debugPrint('Error saving parental settings to Firebase: $e');
    }
  }

  // Start video watch session
  void startWatchSession() {
    _currentSession = VideoWatchSession(startTime: DateTime.now());
    notifyListeners();
  }

  // Update watch time
  void updateWatchTime(int seconds) {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(secondsWatched: seconds);

    // Check if tasks are required
    final allowedSeconds = _settings.videoMinutesAllowed * 60;
    if (seconds >= allowedSeconds && !_currentSession!.tasksPending) {
      _currentSession = _currentSession!.copyWith(tasksPending: true);
    }

    notifyListeners();
  }

  // Check if video should pause for tasks
  bool shouldPauseForTasks() {
    if (_currentSession == null) return false;
    if (!_settings.youtubeRewardEnabled) return false;

    final allowedSeconds = _settings.videoMinutesAllowed * 60;
    return _currentSession!.secondsWatched >= allowedSeconds &&
           _currentSession!.tasksCompleted < _settings.tasksRequired;
  }

  // Mark task as completed
  void completeTask() {
    if (_currentSession == null) return;

    final newCompleted = _currentSession!.tasksCompleted + 1;
    _currentSession = _currentSession!.copyWith(
      tasksCompleted: newCompleted,
      tasksPending: newCompleted < _settings.tasksRequired,
    );

    // Reset watch time if all tasks completed
    if (newCompleted >= _settings.tasksRequired) {
      _currentSession = _currentSession!.copyWith(secondsWatched: 0);
    }

    notifyListeners();
  }

  // Get remaining tasks
  int get remainingTasks {
    if (_currentSession == null) return _settings.tasksRequired;
    return _settings.tasksRequired - _currentSession!.tasksCompleted;
  }

  // Get remaining watch time in seconds
  int get remainingWatchTimeSeconds {
    if (_currentSession == null) return _settings.videoMinutesAllowed * 60;
    final allowedSeconds = _settings.videoMinutesAllowed * 60;
    return (allowedSeconds - _currentSession!.secondsWatched).clamp(0, allowedSeconds);
  }

  // End watch session
  void endWatchSession() {
    _currentSession = null;
    notifyListeners();
  }

  // Verify parent PIN
  bool verifyPin(String pin) {
    if (!_settings.parentPinRequired) return true;
    if (_settings.parentPin == null) return true;
    return _settings.parentPin == pin;
  }

  // Check if PIN is set up
  bool get isPinSetUp => _settings.parentPin != null && _settings.parentPin!.isNotEmpty;

  // Set up parent PIN
  Future<bool> setupPin(String newPin) async {
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      return false;
    }

    _settings = _settings.copyWith(
      parentPin: newPin,
      parentPinRequired: true,
    );
    await _saveLocalSettings();
    notifyListeners();
    return true;
  }

  // Change parent PIN (requires old PIN verification)
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) {
      return false;
    }

    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      return false;
    }

    _settings = _settings.copyWith(parentPin: newPin);
    await _saveLocalSettings();
    notifyListeners();
    return true;
  }

  // Remove PIN protection
  Future<bool> removePin(String currentPin) async {
    if (!verifyPin(currentPin)) {
      return false;
    }

    _settings = _settings.copyWith(
      parentPin: null,
      parentPinRequired: false,
    );
    await _saveLocalSettings();
    notifyListeners();
    return true;
  }

  // Toggle PIN requirement
  Future<void> setPinRequired(bool required, {String? pin}) async {
    _settings = _settings.copyWith(
      parentPinRequired: required,
      parentPin: pin ?? _settings.parentPin,
    );
    await _saveLocalSettings();
    notifyListeners();
  }
}

// Providers
final parentalControlServiceProvider = ChangeNotifierProvider<ParentalControlService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ParentalControlService(prefs);
});

// Import sharedPreferencesProvider from age_adaptive_service.dart
