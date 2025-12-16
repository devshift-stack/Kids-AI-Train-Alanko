import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/ai_game_service.dart';
import '../../../services/user_profile_service.dart';

class ShapesGameScreen extends ConsumerStatefulWidget {
  const ShapesGameScreen({super.key});

  @override
  ConsumerState<ShapesGameScreen> createState() => _ShapesGameScreenState();
}

class _ShapesGameScreenState extends ConsumerState<ShapesGameScreen> {
  int _score = 0;
  int _totalQuestions = 0;
  bool _isLoading = true;
  bool _showResult = false;
  bool _isCorrect = false;

  Map<String, dynamic> _currentQuestion = {};
  List<Map<String, dynamic>> _shapes = [];
  String _selectedShapeId = '';

  final List<Map<String, dynamic>> _allShapes = [
    {'id': 'circle', 'name': 'Krug', 'nameDe': 'Kreis', 'sides': 0, 'emoji': '⭕', 'color': Colors.red},
    {'id': 'square', 'name': 'Kvadrat', 'nameDe': 'Quadrat', 'sides': 4, 'emoji': '⬜', 'color': Colors.blue},
    {'id': 'triangle', 'name': 'Trokut', 'nameDe': 'Dreieck', 'sides': 3, 'emoji': '🔺', 'color': Colors.green},
    {'id': 'rectangle', 'name': 'Pravougaonik', 'nameDe': 'Rechteck', 'sides': 4, 'emoji': '▬', 'color': Colors.orange},
    {'id': 'star', 'name': 'Zvijezda', 'nameDe': 'Stern', 'sides': 5, 'emoji': '⭐', 'color': Colors.yellow},
    {'id': 'heart', 'name': 'Srce', 'nameDe': 'Herz', 'sides': 0, 'emoji': '❤️', 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Hajde da učimo oblike! Pronađi traženi oblik.',
        mood: AlanMood.excited,
      );
    });
    _nextQuestion();
  }

  Future<void> _nextQuestion() async {
    setState(() {
      _isLoading = true;
      _showResult = false;
      _selectedShapeId = '';
    });

    final profile = ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;

    // Try AI-generated question
    try {
      final aiGame = ref.read(aiGameServiceProvider);
      _currentQuestion = await aiGame.generateShapeQuestion(age);
    } catch (e) {
      // Fallback to static
      _currentQuestion = _getStaticQuestion();
    }

    // Generate options
    _shapes = List.from(_allShapes)..shuffle();
    _shapes = _shapes.take(4).toList();

    // Make sure correct answer is in options
    final correctShape = _allShapes.firstWhere(
      (s) => s['name'] == _currentQuestion['shape'] || s['nameDe'] == _currentQuestion['shapeDe'],
      orElse: () => _allShapes.first,
    );

    if (!_shapes.any((s) => s['id'] == correctShape['id'])) {
      _shapes[0] = correctShape;
      _shapes.shuffle();
    }

    setState(() => _isLoading = false);

    // Speak the question
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(alanVoiceServiceProvider).speak(
        _currentQuestion['question'] ?? 'Pronađi ${_currentQuestion['shape']}!',
        mood: AlanMood.curious,
      );
    });
  }

  Map<String, dynamic> _getStaticQuestion() {
    final shape = _allShapes[Random().nextInt(_allShapes.length)];
    return {
      'shape': shape['name'],
      'shapeDe': shape['nameDe'],
      'question': 'Pronađi ${shape['name']}!',
      'sides': shape['sides'],
    };
  }

  void _checkAnswer(Map<String, dynamic> selected) {
    if (_showResult) return;

    _totalQuestions++;
    final correctShape = _currentQuestion['shape'] ?? '';
    _isCorrect = selected['name'] == correctShape || selected['nameDe'] == _currentQuestion['shapeDe'];

    if (_isCorrect) {
      _score++;
      ref.read(alanVoiceServiceProvider).react('correct');
    } else {
      ref.read(alanVoiceServiceProvider).react('wrong');
    }

    setState(() {
      _showResult = true;
      _selectedShapeId = selected['id'];
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
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
              _buildHeader(),
              _buildScoreBar(),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildGameContent(),
              ),
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
            'Oblici - Formen',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _nextQuestion,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.alanGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScoreItem(Icons.star, '$_score', 'Bodovi', Colors.amber),
          const SizedBox(width: 20),
          _buildScoreItem(
            Icons.percent,
            _totalQuestions > 0 ? '${((_score / _totalQuestions) * 100).toInt()}%' : '0%',
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
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    return Column(
      children: [
        // Question
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text(
              _currentQuestion['question'] ?? 'Pronađi oblik!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ).animate().fadeIn().slideY(begin: -0.2),

        const SizedBox(height: 20),

        // Shape options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: _shapes.map((shape) => _buildShapeCard(shape)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShapeCard(Map<String, dynamic> shape) {
    final isSelected = _selectedShapeId == shape['id'];
    final isCorrectAnswer = shape['name'] == _currentQuestion['shape'] ||
                           shape['nameDe'] == _currentQuestion['shapeDe'];

    Color bgColor = Colors.white;
    Color borderColor = Colors.transparent;

    if (_showResult) {
      if (isCorrectAnswer) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (isSelected && !_isCorrect) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    }

    return GestureDetector(
      onTap: () => _checkAnswer(shape),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shape['emoji'] ?? '⬜',
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 10),
            Text(
              shape['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: shape['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * _shapes.indexOf(shape)).ms).scale();
  }
}
