import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/games/game_item.dart';
import '../../../services/alan_voice_service.dart';

class ColorsGameScreen extends ConsumerStatefulWidget {
  const ColorsGameScreen({super.key});

  @override
  ConsumerState<ColorsGameScreen> createState() => _ColorsGameScreenState();
}

class _ColorsGameScreenState extends ConsumerState<ColorsGameScreen>
    with TickerProviderStateMixin {
  late List<GameItem> _colors;
  late List<GameItem> _options;
  late GameItem _currentColor;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  late AnimationController _bounceController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _initGame();
  }

  void _initGame() {
    final langCode = context.locale.languageCode;
    _colors = ColorsData.getColors(langCode);
    _nextQuestion();

    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        _getGreeting(langCode),
        mood: AlanMood.excited,
      );
    });
  }

  String _getGreeting(String lang) {
    switch (lang) {
      case 'en':
        return 'Let\'s learn colors! Find the color you hear.';
      case 'de':
        return 'Lass uns Farben lernen! Finde die Farbe die du hörst.';
      default:
        return 'Hajde da učimo boje! Pronađi boju koju čuješ.';
    }
  }

  void _nextQuestion() {
    final random = Random();
    _currentColor = _colors[random.nextInt(_colors.length)];

    final wrongOptions = _colors
        .where((c) => c.id != _currentColor.id)
        .toList()
      ..shuffle();

    _options = [_currentColor, ...wrongOptions.take(3)]..shuffle();
    _showResult = false;

    setState(() {});

    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(alanVoiceServiceProvider).speak(
        _currentColor.audioText,
        mood: AlanMood.curious,
      );
    });
  }

  void _checkAnswer(GameItem selected) {
    if (_showResult) return;

    _totalQuestions++;
    _isCorrect = selected.id == _currentColor.id;

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
    ref.read(alanVoiceServiceProvider).speak(
      _currentColor.audioText,
      mood: AlanMood.happy,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFE1F5FE),
              Color(0xFFFFF3E0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildScoreBar(),
              const SizedBox(height: 20),
              Expanded(flex: 2, child: _buildColorDisplay()),
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
              child: const Icon(Icons.arrow_back, color: Colors.purple),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Boje',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _repeatSound,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
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

  Widget _buildColorDisplay() {
    return Center(
      child: GestureDetector(
        onTap: _repeatSound,
        child: AnimatedBuilder(
          listenable: Listenable.merge([_bounceController, _pulseController]),
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_bounceController.value * 0.2) + (_pulseController.value * 0.05),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade300,
                      Colors.purple.shade600,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volume_up, color: Colors.white70, size: 30),
                      SizedBox(height: 8),
                      Icon(Icons.palette, color: Colors.white, size: 50),
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
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (_showResult) {
      if (option.id == _currentColor.id) {
        borderColor = Colors.green;
        borderWidth = 4;
      } else {
        borderColor = Colors.red.withOpacity(0.5);
        borderWidth = 2;
      }
    }

    // Handle white color visibility
    final displayColor = option.id == 'white'
        ? Colors.grey.shade200
        : option.color;

    return GestureDetector(
      onTap: () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: displayColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Color name at bottom
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option.displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: option.id == 'white' ? Colors.grey.shade700 : option.color,
                  ),
                ),
              ),
            ),
            // Checkmark for correct answer
            if (_showResult && option.id == _currentColor.id)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
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
