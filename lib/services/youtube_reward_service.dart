import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/youtube/youtube_settings.dart';

/// Service zur Verwaltung des YouTube Belohnungssystems
class YouTubeRewardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  YouTubeSettings _settings = const YouTubeSettings();
  YouTubeSettings get settings => _settings;
  
  // Tracking
  int _watchedMinutesToday = 0;
  int _tasksCompletedForSession = 0;
  bool _canWatch = true;
  Timer? _watchTimer;
  int _currentSessionMinutes = 0;
  
  int get watchedMinutesToday => _watchedMinutesToday;
  int get tasksCompletedForSession => _tasksCompletedForSession;
  bool get canWatch => _canWatch && _settings.isEnabled;
  int get tasksNeeded => _settings.tasksRequired - _tasksCompletedForSession;
  int get currentSessionMinutes => _currentSessionMinutes;
  
  // Sichere kindgerechte Videos (YouTube IDs)
  final List<Map<String, String>> _defaultSafeVideos = [
    {'id': 'dQw4w9WgXcQ', 'title': 'Kinderlieder Mix'},
    {'id': 'kNN7oME0Z5U', 'title': 'Baby Shark'},
    {'id': 'oe_HDfdmnaI', 'title': 'Wheels on the Bus'},
    {'id': 'DyDfgMOUjCI', 'title': 'ABC Song'},
    {'id': '0j6dWMR5uSg', 'title': 'Number Song'},
  ];
  
  List<Map<String, String>> get safeVideos => _defaultSafeVideos;
  
  String? _childId;
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;
  
  /// Initialisiert den Service für ein Kind
  Future<void> initialize(String childId) async {
    _childId = childId;
    await _loadLocalState();
    _listenToSettings();
  }
  
  /// Lädt lokalen Status aus SharedPreferences
  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('youtube_date_$_childId');
    
    if (savedDate == today) {
      _watchedMinutesToday = prefs.getInt('youtube_watched_$_childId') ?? 0;
    } else {
      // Neuer Tag - Reset
      _watchedMinutesToday = 0;
      await prefs.setString('youtube_date_$_childId', today);
      await prefs.setInt('youtube_watched_$_childId', 0);
    }
    
    _updateCanWatch();
    notifyListeners();
  }
  
  /// Speichert lokalen Status
  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('youtube_date_$_childId', today);
    await prefs.setInt('youtube_watched_$_childId', _watchedMinutesToday);
  }
  
  /// Lauscht auf Settings-Änderungen von Parent Dashboard
  void _listenToSettings() {
    if (_childId == null) return;
    
    _settingsSubscription?.cancel();
    _settingsSubscription = _firestore
        .collection('children')
        .doc(_childId)
        .collection('settings')
        .doc('youtube')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _settings = YouTubeSettings.fromMap(snapshot.data()!);
        _updateCanWatch();
        notifyListeners();
      }
    });
  }
  
  /// Prüft ob Kind noch schauen darf
  void _updateCanWatch() {
    // Prüfe tägliches Limit
    if (_settings.dailyLimitMinutes > 0 && 
        _watchedMinutesToday >= _settings.dailyLimitMinutes) {
      _canWatch = false;
      return;
    }
    
    // Prüfe ob Aufgaben nötig sind
    if (_currentSessionMinutes >= _settings.watchMinutesAllowed &&
        _tasksCompletedForSession < _settings.tasksRequired) {
      _canWatch = false;
      return;
    }
    
    _canWatch = true;
  }
  
  /// Startet das Anschauen (Timer läuft)
  void startWatching() {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _watchedMinutesToday++;
      _currentSessionMinutes++;
      _saveLocalState();
      _updateCanWatch();
      notifyListeners();
      
      if (!_canWatch) {
        pauseWatching();
      }
    });
  }
  
  /// Pausiert das Anschauen
  void pauseWatching() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }
  
  /// Kind hat eine Aufgabe erledigt
  void completeTask() {
    _tasksCompletedForSession++;
    
    if (_tasksCompletedForSession >= _settings.tasksRequired) {
      // Alle Aufgaben erledigt - Session reset
      _currentSessionMinutes = 0;
      _tasksCompletedForSession = 0;
      _updateCanWatch();
    }
    
    notifyListeners();
  }
  
  /// Prüft ob YouTube Feature angezeigt werden soll
  bool get shouldShowYouTube => _settings.isEnabled;
  
  /// Gibt verbleibende Zeit zurück
  int get remainingMinutes {
    if (_settings.dailyLimitMinutes == 0) return -1; // Unbegrenzt
    return _settings.dailyLimitMinutes - _watchedMinutesToday;
  }
  
  /// Gibt Session-Zeit bis zur nächsten Pause zurück
  int get minutesUntilPause {
    return _settings.watchMinutesAllowed - _currentSessionMinutes;
  }
  
  @override
  void dispose() {
    _watchTimer?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final youtubeRewardServiceProvider = ChangeNotifierProvider<YouTubeRewardService>((ref) {
  return YouTubeRewardService();
});

// Settings Provider (für UI)
final youtubeSettingsProvider = Provider<YouTubeSettings>((ref) {
  return ref.watch(youtubeRewardServiceProvider).settings;
});

// Can Watch Provider
final canWatchYouTubeProvider = Provider<bool>((ref) {
  return ref.watch(youtubeRewardServiceProvider).canWatch;
});
