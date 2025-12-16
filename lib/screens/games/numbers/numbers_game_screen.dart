import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/games/game_item.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/age_adaptive_service.dart';

enum NumberGameMode { identify, count, add }

class NumbersGameScreen extends ConsumerStatefulWidget {
  const NumbersGameScreen({super.key});

  @override
  ConsumerState<NumbersGameScreen> createState() => _NumbersGameScreenState();
}

class _NumbersGameScreenState extends ConsumerState<NumbersGameScreen>
    with TickerProviderStateMixin {
  late List<GameItem> _numbers;
  late List<GameItem> _options;
  int _correctAnswer = 0;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  NumberGameMode _gameMode = NumberGameMode.identify;
  int _countObjects = 0;
  int _addNum1 = 0;
  int _addNum2 = 0;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initGame();
  }

  void _initGame() {
    final ageGroup = ref.read(currentAgeGroupProvider);

    // Adjust difficulty based on age
    final (maxNumber, mode) = switch (ageGroup) {
      AgeGroup.preschool => (10, NumberGameMode.identify),
      AgeGroup.earlySchool => (20, NumberGameMode.count),
      AgeGroup.lateSchool => (100, NumberGameMode.add),
    };
    _gameMode = mode;

    _numbers = NumbersData.getNumbers(maxNumber);
    _nextQuestion();

    // Alan greeting
    Future.microtask(() {
      String greeting;
      switch (_gameMode) {
        case NumberGameMode.identify:
          greeting = 'Hajde da učimo brojeve! Pronađi broj koji čuješ.';
          break;
        case NumberGameMode.count:
          greeting = 'Hajde da brojimo! Koliko predmeta vidiš?';
          break;
        case NumberGameMode.add:
          greeting = 'Hajde da računamo! Saberi brojeve.';
          break;
      }
      ref.read(alanVoiceServiceProvider).speak(greeting, mood: AlanMood.excited);
    });
  }

  void _nextQuestion() {
    final random = Random();

    switch (_gameMode) {
      case NumberGameMode.identify:
        _correctAnswer = random.nextInt(_numbers.length);
        break;
      case NumberGameMode.count:
        _countObjects = random.nextInt(10) + 1;
        _correctAnswer = _countObjects;
        break;
      case NumberGameMode.add:
        _addNum1 = random.nextInt(10) + 1;
        _addNum2 = random.nextInt(10) + 1;
        _correctAnswer = _addNum1 + _addNum2;
        break;
    }

    // Generate options
    final Set<int> optionSet = {_correctAnswer};
    while (optionSet.length < 4) {
      int wrong = _correctAnswer + random.nextInt(5) - 2;
      if (wrong >= 0 && wrong < _numbers.length && wrong != _correctAnswer) {
        optionSet.add(wrong);
      }
    }

    _options = optionSet
        .map((n) => _numbers.length > n ? _numbers[n] : _numbers[0])
        .toList()
      ..shuffle();
    _showResult = false;

    setState(() {});

    // Speak the question
    Future.delayed(const Duration(milliseconds: 300), () {
      switch (_gameMode) {
        case NumberGameMode.identify:
          ref.read(alanVoiceServiceProvider).speak(
            _correctAnswer.toString(),
            mood: AlanMood.curious,
          );
          break;
        case NumberGameMode.count:
          ref.read(alanVoiceServiceProvider).speak(
            'Koliko ima?',
            mood: AlanMood.curious,
          );
          break;
        case NumberGameMode.add:
          ref.read(alanVoiceServiceProvider).speak(
            '$_addNum1 plus $_addNum2',
            mood: AlanMood.curious,
          );
          break;
      }
    });
  }

  void _checkAnswer(GameItem selected) {
    if (_showResult) return;

    _totalQuestions++;
    _isCorrect = int.parse(selected.value) == _correctAnswer;

    if (_isCorrect) {
      _score++;
      _streak++;
      _bounceController.forward().then((_) => _bounceController.reverse());
      ref.read(alanVoiceServiceProvider).react('correct');
    } else {
      _streak = 0;
      ref.read(alanVoiceServiceProvider).react('wrong');
    }

    setState(() => _showResult = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  void _repeatSound() {
    switch (_gameMode) {
      case NumberGameMode.identify:
        ref.read(alanVoiceServiceProvider).speak(
          _correctAnswer.toString(),
          mood: AlanMood.happy,
        );
        break;
      case NumberGameMode.count:
        ref.read(alanVoiceServiceProvider).speak('Koliko ima?', mood: AlanMood.happy);
        break;
      case NumberGameMode.add:
        ref.read(alanVoiceServiceProvider).speak(
          '$_addNum1 plus $_addNum2',
          mood: AlanMood.happy,
        );
        break;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFF8E1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildScoreBar(),
              const SizedBox(height: 20),
              Expanded(flex: 2, child: _buildQuestionDisplay()),
              Expanded(flex: 3, child: _buildOptionsGrid()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.orange),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Brojevi - 123',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _repeatSound,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.volume_up, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem(Icons.star, '$_score', 'Bodovi', Colors.amber),
          _buildScoreItem(Icons.local_fire_department, '$_streak', 'Niz', Colors.orange),
          _buildScoreItem(
            Icons.percent,
            _totalQuestions > 0
                ? '${((_score / _totalQuestions) * 100).toInt()}%'
                : '0%',
            'Tačnost',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDisplay() {
    return Center(
      child: GestureDetector(
        onTap: _repeatSound,
        child: AnimatedBuilder(
          listenable: _bounceController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_bounceController.value * 0.2),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildQuestionContent(),
              ),
            );
          },
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildQuestionContent() {
    switch (_gameMode) {
      case NumberGameMode.identify:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: Colors.white70, size: 30),
            const SizedBox(height: 8),
            const Text(
              '?',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        );
      case NumberGameMode.count:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(
            _countObjects,
            (i) => const Icon(Icons.star, color: Colors.yellow, size: 30),
          ),
        );
      case NumberGameMode.add:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_addNum1',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              ' + ',
              style: TextStyle(fontSize: 32, color: Colors.white70),
            ),
            Text(
              '$_addNum2',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              ' = ?',
              style: TextStyle(fontSize: 32, color: Colors.white70),
            ),
          ],
        );
    }
  }

  Widget _buildOptionsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: _options.map((option) => _buildOptionCard(option)).toList(),
      ),
    );
  }

  Widget _buildOptionCard(GameItem option) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.transparent;

    if (_showResult) {
      if (int.parse(option.value) == _correctAnswer) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    }

    return GestureDetector(
      onTap: () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Text(
            option.displayText,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: option.color,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * _options.indexOf(option)).ms).scale();
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
