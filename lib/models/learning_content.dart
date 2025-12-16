import 'package:equatable/equatable.dart';
import '../services/age_adaptive_service.dart';

enum ContentType { lesson, quiz, game, story, activity }

class LearningContent extends Equatable {
  final String id;
  final String topic;
  final ContentType type;
  final String title;
  final String description;
  final List<AgeGroup> targetAgeGroups;
  final int difficultyLevel;
  final Duration estimatedDuration;
  final String? thumbnailUrl;
  final String? animationAsset;
  final Map<String, dynamic> content;
  final List<String> prerequisites;
  final int xpReward;

  const LearningContent({
    required this.id,
    required this.topic,
    required this.type,
    required this.title,
    required this.description,
    required this.targetAgeGroups,
    required this.difficultyLevel,
    required this.estimatedDuration,
    this.thumbnailUrl,
    this.animationAsset,
    required this.content,
    this.prerequisites = const [],
    this.xpReward = 10,
  });

  factory LearningContent.fromJson(Map<String, dynamic> json) {
    return LearningContent(
      id: json['id'] as String,
      topic: json['topic'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContentType.lesson,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      targetAgeGroups: (json['targetAgeGroups'] as List<dynamic>)
          .map((e) => AgeGroup.values.firstWhere((g) => g.name == e))
          .toList(),
      difficultyLevel: json['difficultyLevel'] as int,
      estimatedDuration: Duration(minutes: json['estimatedMinutes'] as int),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      animationAsset: json['animationAsset'] as String?,
      content: json['content'] as Map<String, dynamic>,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      xpReward: json['xpReward'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'type': type.name,
      'title': title,
      'description': description,
      'targetAgeGroups': targetAgeGroups.map((e) => e.name).toList(),
      'difficultyLevel': difficultyLevel,
      'estimatedMinutes': estimatedDuration.inMinutes,
      'thumbnailUrl': thumbnailUrl,
      'animationAsset': animationAsset,
      'content': content,
      'prerequisites': prerequisites,
      'xpReward': xpReward,
    };
  }

  bool isAvailableFor(AgeGroup ageGroup) {
    return targetAgeGroups.contains(ageGroup);
  }

  @override
  List<Object?> get props => [
        id,
        topic,
        type,
        title,
        description,
        targetAgeGroups,
        difficultyLevel,
        estimatedDuration,
        thumbnailUrl,
        animationAsset,
        content,
        prerequisites,
        xpReward,
      ];
}

class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String? imageUrl;
  final String? audioUrl;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.imageUrl,
    this.audioUrl,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        correctIndex,
        explanation,
        imageUrl,
        audioUrl,
      ];
}
