import 'package:equatable/equatable.dart';

class ChildProfile extends Equatable {
  final String id;
  final String name;
  final int age;
  final String preferredLanguage;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final Map<String, int> topicProgress;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.preferredLanguage,
    this.avatarUrl,
    required this.createdAt,
    this.lastActiveAt,
    this.topicProgress = const {},
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'bs',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      topicProgress: Map<String, int>.from(json['topicProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'preferredLanguage': preferredLanguage,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'topicProgress': topicProgress,
    };
  }

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? preferredLanguage,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, int>? topicProgress,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      topicProgress: topicProgress ?? this.topicProgress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        preferredLanguage,
        avatarUrl,
        createdAt,
        lastActiveAt,
        topicProgress,
      ];
}
