import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_profile_service.dart';
import '../../services/adaptive_learning_service.dart';
import '../../services/alan_voice_service.dart';
import '../profile_selection/profile_selection_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Hier siehst du deinen Fortschritt!',
        mood: AlanMood.happy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final adaptive = ref.watch(adaptiveLearningServiceProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildProfileCard(profile),
                const SizedBox(height: 20),
                _buildProgressSection(adaptive),
                const SizedBox(height: 20),
                _buildStatisticsSection(adaptive),
                const SizedBox(height: 20),
                _buildActionsSection(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'Moj Profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProfileCard(UserProfile profile) {
    final genderEmoji = profile.gender == Gender.boy ? '👦' : '👧';
    final daysPlaying = DateTime.now().difference(profile.createdAt).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.alanGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(genderEmoji, style: const TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.age} godina',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysPlaying == 0
                        ? 'Danas počeo/la!'
                        : 'Igra već $daysPlaying dana',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2);
  }

  Widget _buildProgressSection(AdaptiveLearningService adaptive) {
    final games = [
      {'type': GameType.letters, 'name': 'Slova', 'emoji': '🔤', 'color': const Color(0xFF6C63FF)},
      {'type': GameType.numbers, 'name': 'Brojevi', 'emoji': '🔢', 'color': const Color(0xFFFF9800)},
      {'type': GameType.colors, 'name': 'Boje', 'emoji': '🎨', 'color': const Color(0xFF9C27B0)},
      {'type': GameType.shapes, 'name': 'Oblici', 'emoji': '⬡', 'color': const Color(0xFF4ECDC4)},
      {'type': GameType.animals, 'name': 'Životinje', 'emoji': '🦁', 'color': const Color(0xFF95E1D3)},
      {'type': GameType.stories, 'name': 'Priče', 'emoji': '📖', 'color': const Color(0xFFA8E6CF)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Moj Napredak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...games.asMap().entries.map((entry) {
              final index = entry.key;
              final game = entry.value;
              final summary = adaptive.getPerformanceSummary(game['type'] as GameType);
              final accuracy = summary['recentAccuracy'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProgressBar(
                  game['name'] as String,
                  game['emoji'] as String,
                  accuracy,
                  game['color'] as Color,
                ),
              ).animate(delay: (150 + index * 50).ms).fadeIn().slideX(begin: -0.1);
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildProgressBar(String name, String emoji, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(AdaptiveLearningService adaptive) {
    // Calculate total stats
    int totalExercises = 0;
    int totalCorrect = 0;
    String favoriteGame = 'Još nema';
    int maxExercises = 0;

    final gameNames = {
      GameType.letters: 'Slova',
      GameType.numbers: 'Brojevi',
      GameType.colors: 'Boje',
      GameType.shapes: 'Oblici',
      GameType.animals: 'Životinje',
      GameType.stories: 'Priče',
    };

    for (final gameType in GameType.values) {
      final summary = adaptive.getPerformanceSummary(gameType);
      final exercises = summary['totalExercises'] as int;
      final accuracy = summary['recentAccuracy'] as int;

      totalExercises += exercises;
      totalCorrect += (exercises * accuracy / 100).round();

      if (exercises > maxExercises) {
        maxExercises = exercises;
        favoriteGame = gameNames[gameType] ?? 'Nepoznato';
      }
    }

    final overallAccuracy = totalExercises > 0
        ? (totalCorrect / totalExercises * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Statistike',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '📚',
                    '$totalExercises',
                    'Ukupno vježbi',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '✅',
                    '$totalCorrect',
                    'Tačnih',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '🎯',
                    '$overallAccuracy%',
                    'Ukupna tačnost',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '⭐',
                    favoriteGame,
                    'Omiljeno',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.edit,
            label: 'Profil bearbeiten',
            color: AppTheme.primaryColor,
            onTap: () => _showEditProfileDialog(context),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.swap_horiz,
            label: 'Profil wechseln',
            color: Colors.blue,
            onTap: () => _switchProfile(context),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.person_add,
            label: 'Neues Kind hinzufügen',
            color: Colors.green,
            onTap: () => _addNewProfile(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final profile = ref.read(activeProfileProvider);
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.name);
    int selectedAge = profile.age;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profil bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                children: [
                  const Text('Alter: '),
                  Expanded(
                    child: Slider(
                      value: selectedAge.toDouble(),
                      min: 3,
                      max: 12,
                      divisions: 9,
                      label: '$selectedAge Jahre',
                      onChanged: (value) {
                        setDialogState(() => selectedAge = value.round());
                      },
                    ),
                  ),
                  Text('$selectedAge'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final profileService = ref.read(multiProfileServiceProvider);
              await profileService.updateProfile(
                profile.id,
                name: nameController.text,
                age: selectedAge,
              );
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _switchProfile(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
    );
  }

  void _addNewProfile(BuildContext context) {
    // Navigate to onboarding for new profile
    ref.read(alanVoiceServiceProvider).speak(
      'Lass uns ein neues Profil erstellen!',
      mood: AlanMood.excited,
    );
    // For now, go to profile selection which has add button
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
    );
  }
}
