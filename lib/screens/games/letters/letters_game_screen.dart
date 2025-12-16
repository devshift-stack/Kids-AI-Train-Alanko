import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/games/game_item.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/age_adaptive_service.dart';

class LettersGameScreen extends ConsumerStatefulWidget {
  const LettersGameScreen({super.key});

  @override
  ConsumerState<LettersGameScreen> createState() => _LettersGameScreenState();
}

class _LettersGameScreenState extends ConsumerState<LettersGameScreen>
    with TickerProviderStateMixin {
  late List<GameItem> _letters;
  late List<GameItem> _options;
  late GameItem _currentLetter;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  bool _showResult = false;
  bool _isCorrect = false;
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
    final letterCount = switch (ageGroup) {
      AgeGroup.preschool => 10,
      AgeGroup.earlySchool => 20,
      AgeGroup.lateSchool => LettersData.bosnianAlphabet.length,
    };

    _letters = LettersData.bosnianAlphabet.take(letterCount).toList();
    _nextQuestion();

    // Alan greeting
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Hajde da učimo slova! Pronađi slovo koje čuješ.',
        mood: AlanMood.excited,
      );
    });
  }

  void _nextQuestion() {
    final random = Random();
    _currentLetter = _letters[random.nextInt(_letters.length)];

    // Generate options (1 correct + 3 wrong)
    final wrongOptions = _letters
        .where((l) => l.id != _currentLetter.id)
        .toList()
      ..shuffle();

    _options = [_currentLetter, ...wrongOptions.take(3)]..shuffle();
    _showResult = false;

    setState(() {});

    // Speak the letter
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(alanVoiceServiceProvider).speak(
        _currentLetter.audioText,
        mood: AlanMood.curious,
      );
    });
  }

  void _checkAnswer(GameItem selected) {
    if (_showResult) return;

    _totalQuestions++;
    _isCorrect = selected.id == _currentLetter.id;

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

    // Next question after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  void _repeatSound() {
    ref.read(alanVoiceServiceProvider).speak(
      _currentLetter.audioText,
      mood: AlanMood.happy,
    );
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
            colors: [Color(0xFFE8F4FD), Color(0xFFF8F9FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Score display
              _buildScoreBar(),

              const SizedBox(height: 20),

              // Main letter display
              Expanded(
                flex: 2,
                child: _buildLetterDisplay(),
              ),

              // Options grid
              Expanded(
                flex: 3,
                child: _buildOptionsGrid(),
              ),

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
              child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Slova - ABC',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          // Repeat sound button
          GestureDetector(
            onTap: _repeatSound,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.alanGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
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
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterDisplay() {
    return Center(
      child: GestureDetector(
        onTap: _repeatSound,
        child: AnimatedBuilder(
          listenable: _bounceController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_bounceController.value * 0.2),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: AppTheme.alanGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.volume_up,
                        color: Colors.white70,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '?',
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
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
    final bool isSelected = _showResult && option.id == _currentLetter.id;
    final bool isWrong = _showResult && !_isCorrect && option.id != _currentLetter.id;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.transparent;

    if (_showResult) {
      if (option.id == _currentLetter.id) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (isWrong) {
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
