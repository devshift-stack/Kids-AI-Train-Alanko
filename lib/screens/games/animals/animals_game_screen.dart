import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/ai_game_service.dart';
import '../../../services/user_profile_service.dart';

class AnimalsGameScreen extends ConsumerStatefulWidget {
  const AnimalsGameScreen({super.key});

  @override
  ConsumerState<AnimalsGameScreen> createState() => _AnimalsGameScreenState();
}

class _AnimalsGameScreenState extends ConsumerState<AnimalsGameScreen> {
  int _score = 0;
  int _totalQuestions = 0;
  bool _isLoading = true;
  bool _showAnswer = false;

  Map<String, dynamic> _currentQuestion = {};

  final List<Map<String, dynamic>> _animals = [
    {'id': 'cat', 'name': 'Mačka', 'emoji': '🐱', 'sound': 'Mjau!', 'color': Colors.orange},
    {'id': 'dog', 'name': 'Pas', 'emoji': '🐕', 'sound': 'Vau vau!', 'color': Colors.brown},
    {'id': 'cow', 'name': 'Krava', 'emoji': '🐄', 'sound': 'Muuu!', 'color': Colors.black},
    {'id': 'pig', 'name': 'Svinja', 'emoji': '🐷', 'sound': 'Rok rok!', 'color': Colors.pink},
    {'id': 'chicken', 'name': 'Kokoš', 'emoji': '🐔', 'sound': 'Kokodak!', 'color': Colors.red},
    {'id': 'duck', 'name': 'Patka', 'emoji': '🦆', 'sound': 'Kva kva!', 'color': Colors.yellow},
    {'id': 'horse', 'name': 'Konj', 'emoji': '🐴', 'sound': 'Ihaha!', 'color': Colors.brown},
    {'id': 'sheep', 'name': 'Ovca', 'emoji': '🐑', 'sound': 'Beee!', 'color': Colors.grey},
    {'id': 'lion', 'name': 'Lav', 'emoji': '🦁', 'sound': 'Rrrr!', 'color': Colors.amber},
    {'id': 'elephant', 'name': 'Slon', 'emoji': '🐘', 'sound': 'Truuu!', 'color': Colors.blueGrey},
    {'id': 'monkey', 'name': 'Majmun', 'emoji': '🐵', 'sound': 'Uuu uuu!', 'color': Colors.brown},
    {'id': 'bird', 'name': 'Ptica', 'emoji': '🐦', 'sound': 'Ćiv ćiv!', 'color': Colors.blue},
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

  Future<void> _nextQuestion() async {
    setState(() {
      _isLoading = true;
      _showAnswer = false;
    });

    final profile = ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;

    // Try AI-generated question
    try {
      final aiGame = ref.read(aiGameServiceProvider);
      _currentQuestion = await aiGame.generateAnimalQuestion(age);
    } catch (e) {
      _currentQuestion = _getStaticQuestion();
    }

    setState(() => _isLoading = false);

    // Speak the question
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(alanVoiceServiceProvider).speak(
        _currentQuestion['question'] ?? 'Koja je ovo životinja?',
        mood: AlanMood.curious,
      );
    });
  }

  Map<String, dynamic> _getStaticQuestion() {
    final animal = _animals[Random().nextInt(_animals.length)];
    final questions = [
      'Kako pravi ${animal['name']}?',
      'Koja životinja pravi "${animal['sound']}"?',
      'Gdje živi ${animal['name']}?',
    ];
    return {
      'animal': animal['name'],
      'emoji': animal['emoji'],
      'question': questions[Random().nextInt(questions.length)],
      'answer': animal['sound'],
    };
  }

  void _showAnswerAndContinue() {
    _totalQuestions++;
    _score++;

    ref.read(alanVoiceServiceProvider).speak(
      _currentQuestion['answer'] ?? 'Bravo!',
      mood: AlanMood.happy,
    );

    setState(() => _showAnswer = true);

    Future.delayed(const Duration(milliseconds: 2000), () {
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
            'Životinje - Tiere',
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
                child: Text(
                  _currentQuestion['answer'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
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
