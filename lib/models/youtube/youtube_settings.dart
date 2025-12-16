import 'package:equatable/equatable.dart';

/// YouTube Reward Settings (synced from Parent Dashboard via Firebase)
class YouTubeSettings extends Equatable {
  /// Feature ein/aus
  final bool isEnabled;

  /// Minuten YouTube nach denen Aufgaben gemacht werden müssen
  final int watchMinutesAllowed;

  /// Anzahl Aufgaben die erledigt werden müssen
  final int tasksRequired;

  /// Erlaubte Video-IDs (kuratierte kindersichere Videos)
  final List<String> allowedVideoIds;

  /// Maximale tägliche YouTube-Zeit in Minuten (0 = unbegrenzt)
  final int dailyLimitMinutes;

  const YouTubeSettings({
    this.isEnabled = false,
    this.watchMinutesAllowed = 10,
    this.tasksRequired = 3,
    this.allowedVideoIds = const [],
    this.dailyLimitMinutes = 60,
  });

  factory YouTubeSettings.fromMap(Map<String, dynamic> map) {
    return YouTubeSettings(
      isEnabled: map['isEnabled'] ?? false,
      watchMinutesAllowed: map['watchMinutesAllowed'] ?? 10,
      tasksRequired: map['tasksRequired'] ?? 3,
      allowedVideoIds: List<String>.from(map['allowedVideoIds'] ?? []),
      dailyLimitMinutes: map['dailyLimitMinutes'] ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'watchMinutesAllowed': watchMinutesAllowed,
      'tasksRequired': tasksRequired,
      'allowedVideoIds': allowedVideoIds,
      'dailyLimitMinutes': dailyLimitMinutes,
    };
  }

  YouTubeSettings copyWith({
    bool? isEnabled,
    int? watchMinutesAllowed,
    int? tasksRequired,
    List<String>? allowedVideoIds,
    int? dailyLimitMinutes,
  }) {
    return YouTubeSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      watchMinutesAllowed: watchMinutesAllowed ?? this.watchMinutesAllowed,
      tasksRequired: tasksRequired ?? this.tasksRequired,
      allowedVideoIds: allowedVideoIds ?? this.allowedVideoIds,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        watchMinutesAllowed,
        tasksRequired,
        allowedVideoIds,
        dailyLimitMinutes,
      ];
}
