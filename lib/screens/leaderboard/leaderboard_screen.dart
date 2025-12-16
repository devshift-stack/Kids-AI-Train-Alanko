import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_profile_service.dart';
import '../../services/adaptive_learning_service.dart';
import '../../services/alan_voice_service.dart';

// Leaderboard entry model
class LeaderboardEntry {
  final String id;
  final String displayName;
  final int totalScore;
  final int gamesPlayed;
  final int averageAccuracy;
  final String ageGroup;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.totalScore,
    required this.gamesPlayed,
    required this.averageAccuracy,
    required this.ageGroup,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedFilter = 'all'; // all, age_group, weekly
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Schauen wir mal wer am besten ist!',
        mood: AlanMood.excited,
      );
    });
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    // Simulate loading - in production this would fetch from backend
    await Future.delayed(const Duration(milliseconds: 500));

    final profile = ref.read(activeProfileProvider);
    final adaptive = ref.read(adaptiveLearningServiceProvider);

    // Generate demo data + current user
    final demoEntries = _generateDemoEntries(profile, adaptive);

    setState(() {
      _entries = demoEntries;
      _isLoading = false;
    });
  }

  List<LeaderboardEntry> _generateDemoEntries(
    UserProfile? profile,
    AdaptiveLearningService adaptive,
  ) {
    // Demo entries for showcase
    final demoNames = [
      'SuperStar', 'LernHeld', 'SchlauFuchs', 'Wunderkind', 'BuchstabenKing',
      'ZahlenPrinz', 'FarbMeister', 'FormGenie', 'TierFreund', 'GeschichtenFan',
    ];

    final entries = <LeaderboardEntry>[];

    // Add current user if they can be on leaderboard
    if (profile != null && profile.canBeOnLeaderboard) {
      int totalScore = 0;
      int totalExercises = 0;
      int totalAccuracy = 0;
      int gameCount = 0;

      for (final gameType in GameType.values) {
        final summary = adaptive.getPerformanceSummary(gameType);
        final exercises = summary['totalExercises'] as int;
        final accuracy = summary['recentAccuracy'] as int;

        if (exercises > 0) {
          totalExercises += exercises;
          totalAccuracy += accuracy;
          gameCount++;
        }
        totalScore += (exercises * accuracy / 10).round();
      }

      final avgAccuracy = gameCount > 0 ? (totalAccuracy / gameCount).round() : 0;
      final displayName = profile.leaderboardDisplayName?.isNotEmpty == true
          ? profile.leaderboardDisplayName!
          : profile.name;

      entries.add(LeaderboardEntry(
        id: profile.id,
        displayName: displayName,
        totalScore: totalScore,
        gamesPlayed: totalExercises,
        averageAccuracy: avgAccuracy,
        ageGroup: _getAgeGroup(profile.age),
        isCurrentUser: true,
      ));
    }

    // Add demo entries
    for (int i = 0; i < demoNames.length; i++) {
      entries.add(LeaderboardEntry(
        id: 'demo_$i',
        displayName: demoNames[i],
        totalScore: 500 - (i * 40) + (i % 3 * 15),
        gamesPlayed: 50 - (i * 3),
        averageAccuracy: 95 - (i * 5),
        ageGroup: i % 3 == 0 ? '3-5' : (i % 3 == 1 ? '6-8' : '9-12'),
      ));
    }

    // Sort by score
    entries.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return entries;
  }

  String _getAgeGroup(int age) {
    if (age <= 5) return '3-5';
    if (age <= 8) return '6-8';
    return '9-12';
  }

  List<LeaderboardEntry> _getFilteredEntries() {
    final profile = ref.read(activeProfileProvider);

    switch (_selectedFilter) {
      case 'age_group':
        if (profile == null) return _entries;
        final userAgeGroup = _getAgeGroup(profile.age);
        return _entries.where((e) => e.ageGroup == userAgeGroup).toList();
      default:
        return _entries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);

    // Check if user can see leaderboard
    if (profile == null || !profile.canSeeLeaderboard) {
      return _buildLockedScreen(context);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilterBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildLeaderboardList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
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
                        child: const Icon(Icons.arrow_back, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Rangliste',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Locked content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock,
                            size: 80,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Rangliste gesperrt',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Deine Eltern müssen die Rangliste\nim Eltern-Dashboard freischalten.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.family_restroom, color: Colors.amber.shade700),
                              const SizedBox(width: 12),
                              Text(
                                'Frag deine Eltern!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
              child: const Icon(Icons.arrow_back, color: Colors.amber),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '🏆',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 8),
          Text(
            'Rangliste',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadLeaderboard,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.refresh, color: Colors.amber),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Alle', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Meine Altersgruppe', 'age_group'),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    final filteredEntries = _getFilteredEntries();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return _buildLeaderboardCard(entry, index + 1)
            .animate()
            .fadeIn(delay: (50 * index).ms)
            .slideX(begin: 0.1);
      },
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int rank) {
    Color rankColor;
    String rankEmoji;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankEmoji = '🥇';
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankEmoji = '🥈';
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankEmoji = '🥉';
        break;
      default:
        rankColor = Colors.grey.shade400;
        rankEmoji = '$rank';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: entry.isCurrentUser
            ? Border.all(color: Colors.amber, width: 2)
            : null,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor.withAlpha(50) : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Center(
              child: Text(
                rankEmoji,
                style: TextStyle(
                  fontSize: rank <= 3 ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: rank > 3 ? Colors.grey.shade700 : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: entry.isCurrentUser
                            ? Colors.amber.shade800
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'DU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatBadge('🎮', '${entry.gamesPlayed}'),
                    const SizedBox(width: 8),
                    _buildStatBadge('🎯', '${entry.averageAccuracy}%'),
                    const SizedBox(width: 8),
                    _buildStatBadge('👶', entry.ageGroup),
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalScore}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              Text(
                'Punkte',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
