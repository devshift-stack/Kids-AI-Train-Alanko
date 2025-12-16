import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/ai_game_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/adaptive_learning_service.dart';

class AnimalsGameScreen extends ConsumerStatefulWidget {
  const AnimalsGameScreen({super.key});

  @override
  ConsumerState<AnimalsGameScreen> createState() => _AnimalsGameScreenState();
}

class _AnimalsGameScreenState extends ConsumerState<AnimalsGameScreen> {
  int _score = 0;
  bool _isLoading = true;
  bool _showAnswer = false;
  DateTime? _questionStartTime;

  Map<String, dynamic> _currentQuestion = {};

  final List<Map<String, dynamic>> _basicAnimals = [
    {'id': 'cat', 'name': 'Mačka', 'emoji': '🐱', 'sound': 'Mjau!', 'color': Colors.orange, 'habitat': 'Kuća'},
    {'id': 'dog', 'name': 'Pas', 'emoji': '🐕', 'sound': 'Vau vau!', 'color': Colors.brown, 'habitat': 'Kuća'},
    {'id': 'cow', 'name': 'Krava', 'emoji': '🐄', 'sound': 'Muuu!', 'color': Colors.black, 'habitat': 'Farma'},
    {'id': 'pig', 'name': 'Svinja', 'emoji': '🐷', 'sound': 'Rok rok!', 'color': Colors.pink, 'habitat': 'Farma'},
    {'id': 'chicken', 'name': 'Kokoš', 'emoji': '🐔', 'sound': 'Kokodak!', 'color': Colors.red, 'habitat': 'Farma'},
    {'id': 'duck', 'name': 'Patka', 'emoji': '🦆', 'sound': 'Kva kva!', 'color': Colors.yellow, 'habitat': 'Jezero'},
    {'id': 'horse', 'name': 'Konj', 'emoji': '🐴', 'sound': 'Ihaha!', 'color': Colors.brown, 'habitat': 'Farma'},
    {'id': 'sheep', 'name': 'Ovca', 'emoji': '🐑', 'sound': 'Beee!', 'color': Colors.grey, 'habitat': 'Farma'},
  ];

  final List<Map<String, dynamic>> _advancedAnimals = [
    {'id': 'lion', 'name': 'Lav', 'emoji': '🦁', 'sound': 'Rrrr!', 'color': Colors.amber, 'habitat': 'Afrika', 'diet': 'Meso'},
    {'id': 'elephant', 'name': 'Slon', 'emoji': '🐘', 'sound': 'Truuu!', 'color': Colors.blueGrey, 'habitat': 'Afrika', 'diet': 'Biljke'},
    {'id': 'monkey', 'name': 'Majmun', 'emoji': '🐵', 'sound': 'Uuu uuu!', 'color': Colors.brown, 'habitat': 'Džungla', 'diet': 'Voće'},
    {'id': 'bird', 'name': 'Ptica', 'emoji': '🐦', 'sound': 'Ćiv ćiv!', 'color': Colors.blue, 'habitat': 'Nebo'},
    {'id': 'penguin', 'name': 'Pingvin', 'emoji': '🐧', 'sound': 'Kvak!', 'color': Colors.black, 'habitat': 'Antarktik', 'diet': 'Riba'},
    {'id': 'bear', 'name': 'Medvjed', 'emoji': '🐻', 'sound': 'Grrrr!', 'color': Colors.brown, 'habitat': 'Šuma', 'diet': 'Sve'},
    {'id': 'giraffe', 'name': 'Žirafa', 'emoji': '🦒', 'sound': '...', 'color': Colors.orange, 'habitat': 'Afrika', 'diet': 'Lišće'},
    {'id': 'dolphin', 'name': 'Delfin', 'emoji': '🐬', 'sound': 'Klik klik!', 'color': Colors.blue, 'habitat': 'More', 'diet': 'Riba'},
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Hajde da učimo o životinjama! Slušaj pitanje.',
        mood: AlanMood.excited,
      );
    });
    _nextQuestion();
  }

  List<Map<String, dynamic>> _getAvailableAnimals() {
    final adaptive = ref.read(adaptiveLearningServiceProvider);
    final params = adaptive.getGameParameters(GameType.animals);

    if (params['includeExoticAnimals'] == true) {
      return [..._basicAnimals, ..._advancedAnimals];
    }
    return _basicAnimals;
  }

  Future<void> _nextQuestion() async {
    setState(() {
      _isLoading = true;
      _showAnswer = false;
    });

    final profile = ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;
    final adaptive = ref.read(adaptiveLearningServiceProvider);
    final params = adaptive.getGameParameters(GameType.animals);

    // Try AI-generated question
    try {
      final aiGame = ref.read(aiGameServiceProvider);
      _currentQuestion = await aiGame.generateAnimalQuestion(age);
    } catch (e) {
      _currentQuestion = _getStaticQuestion(params);
    }

    setState(() => _isLoading = false);

    // Start timer
    _questionStartTime = DateTime.now();

    // Speak the question
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(alanVoiceServiceProvider).speak(
        _currentQuestion['question'] ?? 'Koja je ovo životinja?',
        mood: AlanMood.curious,
      );
    });
  }

  Map<String, dynamic> _getStaticQuestion(Map<String, dynamic> params) {
    final animals = _getAvailableAnimals();
    final animal = animals[Random().nextInt(animals.length)];

    List<String> questions = [
      'Kako pravi ${animal['name']}?',
      'Koja životinja pravi "${animal['sound']}"?',
    ];

    // Add harder questions based on difficulty
    if (params['askHabitat'] == true) {
      questions.add('Gdje živi ${animal['name']}?');
    }
    if (params['askDiet'] == true && animal['diet'] != null) {
      questions.add('Šta jede ${animal['name']}?');
    }

    final selectedQuestion = questions[Random().nextInt(questions.length)];
    String answer = animal['sound'];

    if (selectedQuestion.contains('Gdje živi')) {
      answer = animal['habitat'] ?? 'U prirodi';
    } else if (selectedQuestion.contains('Šta jede')) {
      answer = animal['diet'] ?? 'Raznu hranu';
    }

    return {
      'animal': animal['name'],
      'emoji': animal['emoji'],
      'question': selectedQuestion,
      'answer': answer,
    };
  }

  void _showAnswerAndContinue() {
    // Calculate response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 5000;

    _score++;

    // Record for adaptive learning
    final adaptive = ref.read(adaptiveLearningServiceProvider);
    adaptive.recordResult(
      gameType: GameType.animals,
      correct: true, // In this game format, showing answer = learned
      responseTimeMs: responseTime,
    );

    ref.read(alanVoiceServiceProvider).speak(
      _currentQuestion['answer'] ?? 'Bravo!',
      mood: AlanMood.happy,
    );

    setState(() => _showAnswer = true);

    // Auto-advance with adaptive delay
    final delay = adaptive.getNextQuestionDelay(GameType.animals);
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
    final summary = adaptive.getPerformanceSummary(GameType.animals);

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
          Expanded(
            child: Text(
              'Životinje - Tiere',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Difficulty indicator
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            '$_score Životinja naučeno',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Animal emoji
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Center(
                child: Text(
                  _currentQuestion['emoji'] ?? '🐾',
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 30),

            // Animal name
            Text(
              _currentQuestion['animal'] ?? 'Životinja',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 20),

            // Question
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Text(
                _currentQuestion['question'] ?? 'Šta znaš o ovoj životinji?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppTheme.textPrimary,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 30),

            // Answer (if shown)
            if (_showAnswer)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      _currentQuestion['answer'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Nächste Frage kommt automatisch...',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),

            const SizedBox(height: 30),

            // Show answer button
            if (!_showAnswer)
              GestureDetector(
                onTap: _showAnswerAndContinue,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.alanGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Pokaži odgovor!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}
