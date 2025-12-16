import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/alan_voice_service.dart';
import '../../services/user_profile_service.dart';
import '../age_selection/age_selection_screen.dart';

class GenderSelectionScreen extends ConsumerStatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  ConsumerState<GenderSelectionScreen> createState() =>
      _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends ConsumerState<GenderSelectionScreen> {
  Gender? _selectedGender;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _greet);
  }

  void _greet() {
    final alanko = ref.read(alanVoiceServiceProvider);
    final onboarding = ref.read(onboardingStateProvider);
    alanko.speak(
      '${onboarding.name}, jesi li dječak ili djevojčica?',
      mood: AlanMood.curious,
    );
  }

  void _selectGender(Gender gender) {
    setState(() => _selectedGender = gender);

    // Save gender to onboarding state
    ref.read(onboardingStateProvider.notifier).state =
        ref.read(onboardingStateProvider).copyWith(gender: gender);

    // React
    final alanko = ref.read(alanVoiceServiceProvider);
    final isBoy = gender == Gender.boy;
    alanko.speak(
      isBoy ? 'Super, ti si hrabri dječak!' : 'Super, ti si divna djevojčica!',
      mood: AlanMood.excited,
    );

    // Navigate to age selection
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AgeSelectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingStateProvider);

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
                const Spacer(),

                // Alan Avatar
                _buildAlanAvatar(),

                const SizedBox(height: 32),

                // Question
                Text(
                  '${onboarding.name ?? ''}, jesi li...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ).animate().fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 48),

                // Gender options
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderCard(
                        gender: Gender.boy,
                        emoji: '👦',
                        label: 'Dječak',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildGenderCard(
                        gender: Gender.girl,
                        emoji: '👧',
                        label: 'Djevojčica',
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required Gender gender,
    required String emoji,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => _selectGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 3,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (gender == Gender.boy ? 200 : 400).ms).scale();
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
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
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
