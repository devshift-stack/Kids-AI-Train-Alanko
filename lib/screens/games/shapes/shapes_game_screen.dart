import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/ai_game_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/adaptive_learning_service.dart';

class ShapesGameScreen extends ConsumerStatefulWidget {
  const ShapesGameScreen({super.key});

  @override
  ConsumerState<ShapesGameScreen> createState() => _ShapesGameScreenState();
}

class _ShapesGameScreenState extends ConsumerState<ShapesGameScreen> {
  int _score = 0;
  bool _isLoading = true;
  bool _showResult = false;
  bool _isCorrect = false;
  DateTime? _questionStartTime;

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

  // Advanced shapes for higher difficulty
  final List<Map<String, dynamic>> _advancedShapes = [
    {'id': 'pentagon', 'name': 'Petougao', 'nameDe': 'Fünfeck', 'sides': 5, 'emoji': '⬠', 'color': Colors.purple},
    {'id': 'hexagon', 'name': 'Šestougao', 'nameDe': 'Sechseck', 'sides': 6, 'emoji': '⬡', 'color': Colors.teal},
    {'id': 'diamond', 'name': 'Dijamant', 'nameDe': 'Raute', 'sides': 4, 'emoji': '💎', 'color': Colors.cyan},
    {'id': 'oval', 'name': 'Oval', 'nameDe': 'Oval', 'sides': 0, 'emoji': '🥚', 'color': Colors.lime},
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

  List<Map<String, dynamic>> _getAvailableShapes() {
    final adaptive = ref.read(adaptiveLearningServiceProvider);
    final params = adaptive.getGameParameters(GameType.shapes);

    if (params['includeAdvancedShapes'] == true) {
      return [..._allShapes, ..._advancedShapes];
    }
    return _allShapes;
  }

  Future<void> _nextQuestion() async {
    setState(() {
      _isLoading = true;
      _showResult = false;
      _selectedShapeId = '';
    });

    final profile = ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;
    final adaptive = ref.read(adaptiveLearningServiceProvider);
    final params = adaptive.getGameParameters(GameType.shapes);

    // Try AI-generated question
    try {
      final aiGame = ref.read(aiGameServiceProvider);
      _currentQuestion = await aiGame.generateShapeQuestion(age);
    } catch (e) {
      // Fallback to static
      _currentQuestion = _getStaticQuestion();
    }

    // Generate options based on difficulty
    final availableShapes = _getAvailableShapes();
    final optionCount = params['optionCount'] ?? 4;

    _shapes = List.from(availableShapes)..shuffle();
    _shapes = _shapes.take(optionCount).toList();

    // Make sure correct answer is in options
    final correctShape = availableShapes.firstWhere(
      (s) => s['name'] == _currentQuestion['shape'] || s['nameDe'] == _currentQuestion['shapeDe'],
      orElse: () => availableShapes.first,
    );

    if (!_shapes.any((s) => s['id'] == correctShape['id'])) {
      _shapes[0] = correctShape;
      _shapes.shuffle();
    }

    setState(() => _isLoading = false);

    // Start timer for response tracking
    _questionStartTime = DateTime.now();

    // Speak the question
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(alanVoiceServiceProvider).speak(
        _currentQuestion['question'] ?? 'Pronađi ${_currentQuestion['shape']}!',
        mood: AlanMood.curious,
      );
    });
  }

  Map<String, dynamic> _getStaticQuestion() {
    final availableShapes = _getAvailableShapes();
    final shape = availableShapes[Random().nextInt(availableShapes.length)];
    return {
      'shape': shape['name'],
      'shapeDe': shape['nameDe'],
      'question': 'Pronađi ${shape['name']}!',
      'sides': shape['sides'],
    };
  }

  void _checkAnswer(Map<String, dynamic> selected) {
    if (_showResult) return;

    // Calculate response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 5000;

    final correctShape = _currentQuestion['shape'] ?? '';
    _isCorrect = selected['name'] == correctShape || selected['nameDe'] == _currentQuestion['shapeDe'];

    // Record result for adaptive learning
    final adaptive = ref.read(adaptiveLearningServiceProvider);
    adaptive.recordResult(
      gameType: GameType.shapes,
      correct: _isCorrect,
      responseTimeMs: responseTime,
    );

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

    // Auto-advance with adaptive delay
    final delay = adaptive.getNextQuestionDelay(GameType.shapes);
    Future.delayed(Duration(milliseconds: delay), () {
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
    final adaptive = ref.watch(adaptiveLearningServiceProvider);
    final summary = adaptive.getPerformanceSummary(GameType.shapes);

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
          // Difficulty indicator instead of refresh button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getDifficultyColor(summary['currentDifficulty']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDifficultyIcon(summary['currentDifficulty']),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getDifficultyText(summary['currentDifficulty']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty < 0.8) return Colors.green;
    if (difficulty < 1.2) return Colors.blue;
    if (difficulty < 1.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getDifficultyIcon(double difficulty) {
    if (difficulty < 0.8) return Icons.child_care;
    if (difficulty < 1.2) return Icons.star;
    if (difficulty < 1.5) return Icons.star_half;
    return Icons.whatshot;
  }

  String _getDifficultyText(double difficulty) {
    if (difficulty < 0.8) return 'Lako';
    if (difficulty < 1.2) return 'Normal';
    if (difficulty < 1.5) return 'Teže';
    return 'Teško';
  }

  Widget _buildScoreBar() {
    final adaptive = ref.watch(adaptiveLearningServiceProvider);
    final summary = adaptive.getPerformanceSummary(GameType.shapes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScoreItem(Icons.star, '$_score', 'Bodovi', Colors.amber),
          const SizedBox(width: 20),
          _buildScoreItem(
            Icons.percent,
            '${summary['recentAccuracy']}%',
            'Tačnost',
            summary['recentAccuracy'] >= 70 ? Colors.green : Colors.orange,
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
