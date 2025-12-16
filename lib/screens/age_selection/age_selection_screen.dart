import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/age_adaptive_service.dart';
import '../../services/alan_voice_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/alan/alan_character.dart';
import '../home/home_screen.dart';

class AgeSelectionScreen extends ConsumerStatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  ConsumerState<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends ConsumerState<AgeSelectionScreen> {
  int? _selectedAge;
  bool _showParentMode = false;

  @override
  void initState() {
    super.initState();
    _greetChild();
  }

  void _greetChild() {
    final alanService = ref.read(alanVoiceServiceProvider);
    final onboarding = ref.read(onboardingStateProvider);
    alanService.speak(
      '${onboarding.name}, koliko imaš godina?',
      mood: AlanMood.curious,
    );
  }

  void _onAgeSelected(int age) async {
    setState(() => _selectedAge = age);

    // Get onboarding data
    final onboarding = ref.read(onboardingStateProvider);

    // Save complete profile to persistent storage
    final profileService = ref.read(multiProfileServiceProvider);
    await profileService.addProfile(
      name: onboarding.name ?? 'Kind',
      gender: onboarding.gender ?? Gender.boy,
      age: age,
    );

    // Set age for services
    final ageService = ref.read(ageAdaptiveServiceProvider);
    await ageService.setAge(age);

    final alanService = ref.read(alanVoiceServiceProvider);
    await alanService.setAge(age);

    // Age-appropriate response
    final ageText = switch (age) {
      <= 5 => 'Super! Du bist noch klein, aber schon ganz groß!',
      <= 8 => 'Toll! Das ist ein schönes Alter zum Lernen!',
      _ => 'Prima! Du bist schon ein großes Kind!',
    };

    await alanService.speak(ageText, mood: AlanMood.happy);

    // Clear onboarding state
    ref.read(onboardingStateProvider.notifier).state = const OnboardingState();

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FD),
              Color(0xFFF8F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Parent mode toggle
              Align(
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: Icon(
                    _showParentMode ? Icons.child_care : Icons.settings,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _showParentMode = !_showParentMode);
                  },
                ),
              ),

              // Alan character
              const Expanded(
                flex: 2,
                child: AlanCharacter(),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Koliko imaš godina?',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
              ),

              const SizedBox(height: 32),

              // Age selection grid
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildAgeGrid(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 10, // Ages 3-12
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final age = index + 3;
        final isSelected = _selectedAge == age;
        final color = AppTheme.getAgeGroupColor(age);

        return _AgeButton(
          age: age,
          isSelected: isSelected,
          color: color,
          onTap: () => _onAgeSelected(age),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1));
      },
    );
  }
}

class _AgeButton extends StatelessWidget {
  final int age;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AgeButton({
    required this.age,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Center(
          child: Text(
            '$age',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

class Align extends StatelessWidget {
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const Align({
    super.key,
    required this.alignment,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    if (padding != null) {
      result = Padding(padding: padding!, child: result);
    }
    return Container(
      alignment: alignment,
      child: result,
    );
  }
}
