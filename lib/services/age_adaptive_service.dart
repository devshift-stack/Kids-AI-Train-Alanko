import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AgeGroup { preschool, earlySchool, lateSchool }

class AgeAdaptiveSettings {
  final int age;
  final AgeGroup ageGroup;
  final double fontSize;
  final double iconSize;
  final double speechRate;
  final int contentComplexity; // 1-3
  final bool showTextLabels;
  final bool useSimpleLanguage;
  final Duration activityDuration;
  final int maxChoicesPerQuestion;

  const AgeAdaptiveSettings({
    required this.age,
    required this.ageGroup,
    required this.fontSize,
    required this.iconSize,
    required this.speechRate,
    required this.contentComplexity,
    required this.showTextLabels,
    required this.useSimpleLanguage,
    required this.activityDuration,
    required this.maxChoicesPerQuestion,
  });

  factory AgeAdaptiveSettings.forAge(int age) {
    if (age <= 5) {
      return AgeAdaptiveSettings(
        age: age,
        ageGroup: AgeGroup.preschool,
        fontSize: 24.0,
        iconSize: 64.0,
        speechRate: 0.4,
        contentComplexity: 1,
        showTextLabels: true,
        useSimpleLanguage: true,
        activityDuration: const Duration(minutes: 5),
        maxChoicesPerQuestion: 2,
      );
    } else if (age <= 8) {
      return AgeAdaptiveSettings(
        age: age,
        ageGroup: AgeGroup.earlySchool,
        fontSize: 20.0,
        iconSize: 48.0,
        speechRate: 0.5,
        contentComplexity: 2,
        showTextLabels: true,
        useSimpleLanguage: false,
        activityDuration: const Duration(minutes: 10),
        maxChoicesPerQuestion: 3,
      );
    } else {
      return AgeAdaptiveSettings(
        age: age,
        ageGroup: AgeGroup.lateSchool,
        fontSize: 16.0,
        iconSize: 40.0,
        speechRate: 0.55,
        contentComplexity: 3,
        showTextLabels: false,
        useSimpleLanguage: false,
        activityDuration: const Duration(minutes: 15),
        maxChoicesPerQuestion: 4,
      );
    }
  }

  AgeAdaptiveSettings copyWith({
    int? age,
    AgeGroup? ageGroup,
    double? fontSize,
    double? iconSize,
    double? speechRate,
    int? contentComplexity,
    bool? showTextLabels,
    bool? useSimpleLanguage,
    Duration? activityDuration,
    int? maxChoicesPerQuestion,
  }) {
    return AgeAdaptiveSettings(
      age: age ?? this.age,
      ageGroup: ageGroup ?? this.ageGroup,
      fontSize: fontSize ?? this.fontSize,
      iconSize: iconSize ?? this.iconSize,
      speechRate: speechRate ?? this.speechRate,
      contentComplexity: contentComplexity ?? this.contentComplexity,
      showTextLabels: showTextLabels ?? this.showTextLabels,
      useSimpleLanguage: useSimpleLanguage ?? this.useSimpleLanguage,
      activityDuration: activityDuration ?? this.activityDuration,
      maxChoicesPerQuestion: maxChoicesPerQuestion ?? this.maxChoicesPerQuestion,
    );
  }
}

class AgeAdaptiveService {
  static const String _ageKey = 'child_age';
  static const String _nameKey = 'child_name';

  final SharedPreferences _prefs;
  AgeAdaptiveSettings _currentSettings;

  AgeAdaptiveService(this._prefs)
      : _currentSettings = AgeAdaptiveSettings.forAge(
          _prefs.getInt(_ageKey) ?? 6
        );

  AgeAdaptiveSettings get settings => _currentSettings;
  int get currentAge => _currentSettings.age;
  AgeGroup get currentAgeGroup => _currentSettings.ageGroup;

  Future<void> setAge(int age) async {
    await _prefs.setInt(_ageKey, age);
    _currentSettings = AgeAdaptiveSettings.forAge(age);
  }

  Future<void> setChildName(String name) async {
    await _prefs.setString(_nameKey, name);
  }

  String? getChildName() => _prefs.getString(_nameKey);

  // Content adaptation methods
  String adaptText(String text, {Map<AgeGroup, String>? variants}) {
    if (variants != null && variants.containsKey(_currentSettings.ageGroup)) {
      return variants[_currentSettings.ageGroup]!;
    }

    if (_currentSettings.useSimpleLanguage) {
      return _simplifyText(text);
    }

    return text;
  }

  String _simplifyText(String text) {
    // Basic text simplification for younger children
    // In production, this could use AI for better simplification
    return text
        .replaceAll(RegExp(r'\b\w{10,}\b'), '') // Remove very long words
        .replaceAll('  ', ' ')
        .trim();
  }

  List<T> adaptChoices<T>(List<T> choices) {
    if (choices.length <= _currentSettings.maxChoicesPerQuestion) {
      return choices;
    }
    return choices.sublist(0, _currentSettings.maxChoicesPerQuestion);
  }

  // UI adaptation methods
  double getAdaptedFontSize(double baseSize) {
    final multiplier = switch (_currentSettings.ageGroup) {
      AgeGroup.preschool => 1.4,
      AgeGroup.earlySchool => 1.2,
      AgeGroup.lateSchool => 1.0,
    };
    return baseSize * multiplier;
  }

  double getAdaptedIconSize(double baseSize) {
    final multiplier = switch (_currentSettings.ageGroup) {
      AgeGroup.preschool => 1.5,
      AgeGroup.earlySchool => 1.25,
      AgeGroup.lateSchool => 1.0,
    };
    return baseSize * multiplier;
  }

  Duration getAdaptedAnimationDuration(Duration baseDuration) {
    // Slower animations for younger children
    final multiplier = switch (_currentSettings.ageGroup) {
      AgeGroup.preschool => 1.5,
      AgeGroup.earlySchool => 1.25,
      AgeGroup.lateSchool => 1.0,
    };
    return Duration(
      milliseconds: (baseDuration.inMilliseconds * multiplier).round(),
    );
  }

  // Learning content methods
  List<String> getTopicsForAgeGroup() {
    return switch (_currentSettings.ageGroup) {
      AgeGroup.preschool => [
        'colors',
        'shapes',
        'numbers_1_10',
        'animals',
        'body_parts',
        'family',
      ],
      AgeGroup.earlySchool => [
        'math_basic',
        'reading',
        'science_intro',
        'geography_intro',
        'time',
        'money',
      ],
      AgeGroup.lateSchool => [
        'math_advanced',
        'history',
        'science',
        'languages',
        'coding_intro',
        'critical_thinking',
      ],
    };
  }

  int getDifficultyLevel() {
    return switch (_currentSettings.ageGroup) {
      AgeGroup.preschool => 1,
      AgeGroup.earlySchool => 2,
      AgeGroup.lateSchool => 3,
    };
  }
}

// Riverpod providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final ageAdaptiveServiceProvider = Provider<AgeAdaptiveService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AgeAdaptiveService(prefs);
});

final ageAdaptiveSettingsProvider = Provider<AgeAdaptiveSettings>((ref) {
  final service = ref.watch(ageAdaptiveServiceProvider);
  return service.settings;
});

final currentAgeProvider = StateProvider<int>((ref) {
  final service = ref.watch(ageAdaptiveServiceProvider);
  return service.currentAge;
});

final currentAgeGroupProvider = Provider<AgeGroup>((ref) {
  final service = ref.watch(ageAdaptiveServiceProvider);
  return service.currentAgeGroup;
});
