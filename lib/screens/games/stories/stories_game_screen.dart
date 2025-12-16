import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/alan_voice_service.dart';
import '../../../services/ai_game_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/adaptive_learning_service.dart';

class StoriesGameScreen extends ConsumerStatefulWidget {
  const StoriesGameScreen({super.key});

  @override
  ConsumerState<StoriesGameScreen> createState() => _StoriesGameScreenState();
}

class _StoriesGameScreenState extends ConsumerState<StoriesGameScreen> {
  bool _isLoading = false;
  String _currentStory = '';
  String _selectedTheme = '';

  final List<Map<String, dynamic>> _themes = [
    {'id': 'princess', 'name': 'Princeza', 'emoji': '👸', 'color': Colors.pink},
    {'id': 'dragon', 'name': 'Zmaj', 'emoji': '🐉', 'color': Colors.red},
    {'id': 'space', 'name': 'Svemir', 'emoji': '🚀', 'color': Colors.indigo},
    {'id': 'animals', 'name': 'Životinje', 'emoji': '🦁', 'color': Colors.orange},
    {'id': 'magic', 'name': 'Čarolija', 'emoji': '✨', 'color': Colors.purple},
    {'id': 'adventure', 'name': 'Avantura', 'emoji': '🗺️', 'color': Colors.green},
    {'id': 'friends', 'name': 'Prijatelji', 'emoji': '👫', 'color': Colors.blue},
    {'id': 'robot', 'name': 'Robot', 'emoji': '🤖', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Hajde da ti ispričam priču! Izaberi temu.',
        mood: AlanMood.excited,
      );
    });
  }

  Future<void> _generateStory(String theme) async {
    setState(() {
      _isLoading = true;
      _selectedTheme = theme;
      _currentStory = '';
    });

    final profile = ref.read(activeProfileProvider);
    final age = profile?.age ?? 6;

    ref.read(alanVoiceServiceProvider).speak(
      'Čekaj malo, smišljam priču...',
      mood: AlanMood.curious,
    );

    try {
      final aiGame = ref.read(aiGameServiceProvider);
      _currentStory = await aiGame.generateStory(age, theme);
    } catch (e) {
      _currentStory = _getDefaultStory(theme);
    }

    // Record story as "learned" for adaptive tracking
    ref.read(adaptiveLearningServiceProvider).recordResult(
      gameType: GameType.stories,
      correct: true,
      responseTimeMs: 5000,
    );

    setState(() => _isLoading = false);

    // Read the story
    ref.read(alanVoiceServiceProvider).speak(
      _currentStory,
      mood: AlanMood.calm,
    );
  }

  String _getDefaultStory(String theme) {
    return '''
Bio jednom jedan mali $theme koji je živio u čarobnoj zemlji.
Jednog dana je krenuo u veliku avanturu.
Upoznao je mnogo novih prijatelja na putu.
Na kraju su svi zajedno proslavili i bili sretni.
I živjeli su sretno do kraja života. Kraj!
''';
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
              Expanded(
                child: _currentStory.isEmpty
                    ? _buildThemeSelection()
                    : _buildStoryDisplay(),
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
            'Priče - Geschichten',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          if (_currentStory.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _currentStory = '';
                _selectedTheme = '';
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Teme',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Izaberi temu za priču:',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: _themes.map((theme) => _buildThemeCard(theme)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme) {
    final isSelected = _selectedTheme == theme['name'];

    return GestureDetector(
      onTap: _isLoading ? null : () => _generateStory(theme['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? (theme['color'] as Color).withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme['color'] as Color : Colors.transparent,
            width: 3,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              theme['emoji'],
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              theme['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * _themes.indexOf(theme)).ms).scale();
  }

  Widget _buildStoryDisplay() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Alanko smišlja priču...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Theme indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _themes.firstWhere((t) => t['name'] == _selectedTheme, orElse: () => {'emoji': '📖'})['emoji'],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Priča o: $_selectedTheme',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // Story content
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text(
              _currentStory,
              style: const TextStyle(
                fontSize: 18,
                height: 1.8,
                color: AppTheme.textPrimary,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 30),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Read again
              GestureDetector(
                onTap: () {
                  ref.read(alanVoiceServiceProvider).speak(
                    _currentStory,
                    mood: AlanMood.calm,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_up, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Pročitaj opet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // New story
              GestureDetector(
                onTap: () => _generateStory(_selectedTheme),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.alanGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Nova priča',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
