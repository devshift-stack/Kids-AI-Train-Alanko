import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/parental_control_service.dart';
import '../../services/alan_voice_service.dart';

class TaskGateScreen extends ConsumerStatefulWidget {
  final VoidCallback onTasksCompleted;

  const TaskGateScreen({super.key, required this.onTasksCompleted});

  @override
  ConsumerState<TaskGateScreen> createState() => _TaskGateScreenState();
}

class _TaskGateScreenState extends ConsumerState<TaskGateScreen> {
  late List<MiniTask> _tasks;
  int _currentTaskIndex = 0;
  int _completedTasks = 0;
  bool _showingFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _generateTasks();
    _announceTask();
  }

  void _generateTasks() {
    final parentalService = ref.read(parentalControlServiceProvider);
    final tasksRequired = parentalService.settings.tasksRequired;

    _tasks = List.generate(tasksRequired, (index) => _generateRandomTask());
  }

  MiniTask _generateRandomTask() {
    final random = Random();
    final taskTypes = [
      _generateMathTask,
      _generateColorTask,
      _generateCountingTask,
    ];

    return taskTypes[random.nextInt(taskTypes.length)]();
  }

  MiniTask _generateMathTask() {
    final random = Random();
    final a = random.nextInt(10) + 1;
    final b = random.nextInt(10) + 1;
    final correctAnswer = a + b;

    final answers = <int>[correctAnswer];
    while (answers.length < 4) {
      final wrong = random.nextInt(20) + 1;
      if (!answers.contains(wrong)) {
        answers.add(wrong);
      }
    }
    answers.shuffle();

    return MiniTask(
      question: '$a + $b = ?',
      type: TaskType.math,
      answers: answers.map((e) => e.toString()).toList(),
      correctIndex: answers.indexOf(correctAnswer),
      icon: Icons.calculate,
    );
  }

  MiniTask _generateColorTask() {
    final colors = [
      {'name': 'Rot', 'color': Colors.red},
      {'name': 'Blau', 'color': Colors.blue},
      {'name': 'Grün', 'color': Colors.green},
      {'name': 'Gelb', 'color': Colors.yellow},
      {'name': 'Orange', 'color': Colors.orange},
      {'name': 'Lila', 'color': Colors.purple},
    ];

    colors.shuffle();
    final correctColor = colors.first;
    final shuffledColors = colors.take(4).toList()..shuffle();

    return MiniTask(
      question: 'Welche Farbe ist ${correctColor['name']}?',
      type: TaskType.color,
      answers: shuffledColors.map((c) => c['name'] as String).toList(),
      correctIndex: shuffledColors.indexOf(correctColor),
      icon: Icons.palette,
      colors: shuffledColors.map((c) => c['color'] as Color).toList(),
    );
  }

  MiniTask _generateCountingTask() {
    final random = Random();
    final count = random.nextInt(8) + 2; // 2-9 items
    final correctAnswer = count;

    final answers = <int>[correctAnswer];
    while (answers.length < 4) {
      final wrong = random.nextInt(10) + 1;
      if (!answers.contains(wrong)) {
        answers.add(wrong);
      }
    }
    answers.shuffle();

    return MiniTask(
      question: 'Wie viele Sterne siehst du?',
      type: TaskType.counting,
      answers: answers.map((e) => e.toString()).toList(),
      correctIndex: answers.indexOf(correctAnswer),
      icon: Icons.star,
      itemCount: count,
    );
  }

  void _announceTask() {
    final alanService = ref.read(alanVoiceServiceProvider);
    final task = _tasks[_currentTaskIndex];

    String announcement;
    switch (task.type) {
      case TaskType.math:
        announcement = 'Löse diese Rechenaufgabe: ${task.question}';
        break;
      case TaskType.color:
        announcement = task.question;
        break;
      case TaskType.counting:
        announcement = 'Zähle die Sterne!';
        break;
    }

    alanService.speak(announcement, mood: AlanMood.curious);
  }

  void _onAnswerSelected(int index) {
    if (_showingFeedback) return;

    final task = _tasks[_currentTaskIndex];
    final correct = index == task.correctIndex;

    setState(() {
      _showingFeedback = true;
      _isCorrect = correct;
    });

    final alanService = ref.read(alanVoiceServiceProvider);

    if (correct) {
      alanService.speak('Super! Das ist richtig!', mood: AlanMood.happy);

      final parentalService = ref.read(parentalControlServiceProvider);
      parentalService.completeTask();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        setState(() {
          _completedTasks++;
          _showingFeedback = false;
        });

        if (_completedTasks >= _tasks.length) {
          // All tasks completed
          alanService.speak(
            'Toll gemacht! Du kannst jetzt weiter Videos schauen!',
            mood: AlanMood.excited,
          );

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            Navigator.of(context).pop();
            widget.onTasksCompleted();
          });
        } else {
          _currentTaskIndex++;
          _announceTask();
        }
      });
    } else {
      alanService.speak('Das war leider falsch. Versuch es nochmal!', mood: AlanMood.encouraging);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _showingFeedback = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _tasks[_currentTaskIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F4FD), Color(0xFFF8F9FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Aufgaben lösen',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Löse ${_tasks.length} Aufgaben um weiterzuschauen',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: List.generate(_tasks.length, (index) {
                    final isCompleted = index < _completedTasks;
                    final isCurrent = index == _currentTaskIndex;

                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.successColor
                              : isCurrent
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Aufgabe ${_currentTaskIndex + 1} von ${_tasks.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 32),

              // Task content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Task icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          task.icon,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ).animate().scale(duration: 400.ms),

                      const SizedBox(height: 24),

                      // Counting items (if counting task)
                      if (task.type == TaskType.counting && task.itemCount != null)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            task.itemCount!,
                            (index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 40,
                            ).animate(delay: (index * 100).ms).scale(),
                          ),
                        ),

                      if (task.type == TaskType.counting) const SizedBox(height: 24),

                      // Question
                      Text(
                        task.question,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 32),

                      // Answer buttons
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: task.answers.length,
                          itemBuilder: (context, index) {
                            final isCorrectAnswer = index == task.correctIndex;
                            final showCorrect = _showingFeedback && isCorrectAnswer;
                            final showWrong = _showingFeedback && !_isCorrect && !isCorrectAnswer;

                            return GestureDetector(
                              onTap: () => _onAnswerSelected(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: showCorrect
                                      ? AppTheme.successColor
                                      : showWrong
                                          ? Colors.red[100]
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: showCorrect
                                        ? AppTheme.successColor
                                        : task.colors != null
                                            ? task.colors![index]
                                            : AppTheme.primaryColor.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: task.colors != null
                                      ? Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: task.colors![index],
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : Text(
                                          task.answers[index],
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: showCorrect ? Colors.white : AppTheme.textPrimary,
                                          ),
                                        ),
                                ),
                              ),
                            ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.3);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Feedback overlay
              if (_showingFeedback)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? AppTheme.successColor : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isCorrect ? 'Richtig!' : 'Versuch es nochmal!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect ? AppTheme.successColor : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
        ),
      ),
    );
  }
}

enum TaskType { math, color, counting }

class MiniTask {
  final String question;
  final TaskType type;
  final List<String> answers;
  final int correctIndex;
  final IconData icon;
  final List<Color>? colors;
  final int? itemCount;

  const MiniTask({
    required this.question,
    required this.type,
    required this.answers,
    required this.correctIndex,
    required this.icon,
    this.colors,
    this.itemCount,
  });
}
