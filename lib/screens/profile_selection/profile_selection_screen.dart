import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/alan_voice_service.dart';
import '../../services/user_profile_service.dart';
import '../home/home_screen.dart';
import '../language_selection/language_selection_screen.dart';

class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _greet);
  }

  void _greet() {
    final alanko = ref.read(alanVoiceServiceProvider);
    alanko.speak(
      'Hallo! Ko se danas igra sa mnom?',
      mood: AlanMood.excited,
    );
  }

  void _selectProfile(UserProfile profile) {
    final service = ref.read(multiProfileServiceProvider);
    service.setActiveProfile(profile.id);

    final alanko = ref.read(alanVoiceServiceProvider);
    alanko.speak(
      profile.getGreeting(service.languageCode),
      mood: AlanMood.happy,
    );

    // Navigate to home
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  void _addNewProfile() {
    // Go to language/onboarding flow
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LanguageSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(allProfilesProvider);

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Alan Avatar
                _buildAlanAvatar(),

                const SizedBox(height: 24),

                // Question
                Text(
                  'Ko se danas igra sa mnom?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 32),

                // Profile cards
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: profiles.length + 1, // +1 for "Add new"
                    itemBuilder: (context, index) {
                      if (index < profiles.length) {
                        return _buildProfileCard(profiles[index], index);
                      } else {
                        return _buildAddNewCard(index);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile, int index) {
    final isBoy = profile.gender == Gender.boy;

    return GestureDetector(
      onTap: () => _selectProfile(profile),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: isBoy ? Colors.blue.shade200 : Colors.pink.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isBoy
                      ? [Colors.blue.shade300, Colors.blue.shade500]
                      : [Colors.pink.shade300, Colors.pink.shade500],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            // Age
            Text(
              '${profile.age} godina',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            // Gender emoji
            const SizedBox(height: 8),
            Text(
              isBoy ? '👦' : '👧',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).scale();
  }

  Widget _buildAddNewCard(int index) {
    return GestureDetector(
      onTap: _addNewProfile,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 40,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Novo dijete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dodaj profil',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).scale();
  }

  Widget _buildAlanAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: AppTheme.alanGradient,
        shape: BoxShape.circle,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEye(),
                const SizedBox(width: 14),
                _buildEye(),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 25,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -5, duration: 2000.ms);
  }

  Widget _buildEye() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF2D3142),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
