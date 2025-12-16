import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'age_adaptive_service.dart';

enum Gender { boy, girl }

class UserProfile {
  final String id;
  final String name;
  final Gender gender;
  final int age;
  final String languageCode;
  final DateTime createdAt;
  // Leaderboard consent - set by parents
  final bool canSeeLeaderboard;
  final bool canBeOnLeaderboard;
  final String? leaderboardDisplayName; // Optional nickname for privacy

  const UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    this.languageCode = 'bs',
    required this.createdAt,
    this.canSeeLeaderboard = false, // Default: disabled
    this.canBeOnLeaderboard = false, // Default: disabled
    this.leaderboardDisplayName,
  });

  bool get isComplete => name.isNotEmpty && age > 0;

  // Personalized greeting based on gender and language
  String getGreeting(String langCode) {
    final isBoy = gender == Gender.boy;

    switch (langCode) {
      case 'bs':
      case 'hr':
        return isBoy ? 'Zdravo $name!' : 'Zdravo $name!';
      case 'sr':
        return 'Здраво $name!';
      case 'en':
        return 'Hello $name!';
      case 'de':
        return 'Hallo $name!';
      case 'tr':
        return 'Merhaba $name!';
      default:
        return 'Zdravo $name!';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender == Gender.boy ? 'boy' : 'girl',
    'age': age,
    'languageCode': languageCode,
    'createdAt': createdAt.toIso8601String(),
    'canSeeLeaderboard': canSeeLeaderboard,
    'canBeOnLeaderboard': canBeOnLeaderboard,
    'leaderboardDisplayName': leaderboardDisplayName,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    gender: json['gender'] == 'boy' ? Gender.boy : Gender.girl,
    age: json['age'] as int,
    languageCode: json['languageCode'] as String? ?? 'bs',
    createdAt: DateTime.parse(json['createdAt'] as String),
    canSeeLeaderboard: json['canSeeLeaderboard'] as bool? ?? false,
    canBeOnLeaderboard: json['canBeOnLeaderboard'] as bool? ?? false,
    leaderboardDisplayName: json['leaderboardDisplayName'] as String?,
  );

  UserProfile copyWith({
    String? id,
    String? name,
    Gender? gender,
    int? age,
    String? languageCode,
    DateTime? createdAt,
    bool? canSeeLeaderboard,
    bool? canBeOnLeaderboard,
    String? leaderboardDisplayName,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      canSeeLeaderboard: canSeeLeaderboard ?? this.canSeeLeaderboard,
      canBeOnLeaderboard: canBeOnLeaderboard ?? this.canBeOnLeaderboard,
      leaderboardDisplayName: leaderboardDisplayName ?? this.leaderboardDisplayName,
    );
  }

  // Get content themes based on gender
  List<String> getPreferredThemes() {
    if (gender == Gender.boy) {
      return ['cars', 'dinosaurs', 'space', 'robots', 'superheroes', 'sports'];
    } else {
      return ['princesses', 'unicorns', 'animals', 'nature', 'art', 'fairies'];
    }
  }
}

class MultiProfileService {
  static const String _profilesKey = 'user_profiles';
  static const String _activeProfileKey = 'active_profile_id';
  static const String _languageKey = 'app_language';

  final SharedPreferences _prefs;
  List<UserProfile> _profiles = [];
  UserProfile? _activeProfile;
  String _languageCode = 'bs';

  MultiProfileService(this._prefs) {
    _loadProfiles();
  }

  List<UserProfile> get profiles => _profiles;
  UserProfile? get activeProfile => _activeProfile;
  String get languageCode => _languageCode;
  bool get hasProfiles => _profiles.isNotEmpty;

  void _loadProfiles() {
    // Load language
    _languageCode = _prefs.getString(_languageKey) ?? 'bs';

    // Load profiles
    final profilesJson = _prefs.getString(_profilesKey);
    if (profilesJson != null && profilesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(profilesJson);
        _profiles = decoded.map((p) => UserProfile.fromJson(p)).toList();
      } catch (e) {
        _profiles = [];
      }
    }

    // Load active profile
    final activeId = _prefs.getString(_activeProfileKey);
    if (activeId != null && _profiles.isNotEmpty) {
      _activeProfile = _profiles.firstWhere(
        (p) => p.id == activeId,
        orElse: () => _profiles.first,
      );
    }
  }

  Future<void> _saveProfiles() async {
    final json = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_profilesKey, json);
  }

  Future<UserProfile> addProfile({
    required String name,
    required Gender gender,
    required int age,
  }) async {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      gender: gender,
      age: age,
      languageCode: _languageCode,
      createdAt: DateTime.now(),
    );

    _profiles.add(profile);
    await _saveProfiles();
    await setActiveProfile(profile.id);

    return profile;
  }

  Future<void> updateProfile(
    String id, {
    String? name,
    Gender? gender,
    int? age,
    String? languageCode,
    bool? canSeeLeaderboard,
    bool? canBeOnLeaderboard,
    String? leaderboardDisplayName,
  }) async {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final current = _profiles[index];
      final updated = current.copyWith(
        name: name,
        gender: gender,
        age: age,
        languageCode: languageCode,
        canSeeLeaderboard: canSeeLeaderboard,
        canBeOnLeaderboard: canBeOnLeaderboard,
        leaderboardDisplayName: leaderboardDisplayName,
      );
      _profiles[index] = updated;
      await _saveProfiles();
      if (_activeProfile?.id == id) {
        _activeProfile = updated;
      }
    }
  }

  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _saveProfiles();

    if (_activeProfile?.id == id) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
      if (_activeProfile != null) {
        await _prefs.setString(_activeProfileKey, _activeProfile!.id);
      } else {
        await _prefs.remove(_activeProfileKey);
      }
    }
  }

  Future<void> setActiveProfile(String id) async {
    _activeProfile = _profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => _profiles.first,
    );
    await _prefs.setString(_activeProfileKey, id);
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    await _prefs.setString(_languageKey, code);
  }
}

// Riverpod providers
final multiProfileServiceProvider = Provider<MultiProfileService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MultiProfileService(prefs);
});

final activeProfileProvider = Provider<UserProfile?>((ref) {
  final service = ref.watch(multiProfileServiceProvider);
  return service.activeProfile;
});

final allProfilesProvider = Provider<List<UserProfile>>((ref) {
  final service = ref.watch(multiProfileServiceProvider);
  return service.profiles;
});

// Temporary profile state during onboarding
class OnboardingState {
  final String? name;
  final Gender? gender;
  final int? age;

  const OnboardingState({this.name, this.gender, this.age});

  OnboardingState copyWith({String? name, Gender? gender, int? age}) {
    return OnboardingState(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
    );
  }
}

final onboardingStateProvider = StateProvider<OnboardingState>((ref) {
  return const OnboardingState();
});
