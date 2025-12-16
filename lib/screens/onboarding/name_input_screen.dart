import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/alan_voice_service.dart';
import '../../services/user_profile_service.dart';
import 'gender_selection_screen.dart';

// Use onboardingStateProvider for temporary storage during onboarding

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({super.key});

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  final _nameController = TextEditingController();
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _greet);
  }

  void _greet() {
    final alanko = ref.read(alanVoiceServiceProvider);
    alanko.speak(
      'Ja sam Alanko! Kako se ti zoveš?',
      mood: AlanMood.curious,
    );
  }

  void _continue() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }

    // Save name to temporary onboarding state
    ref.read(onboardingStateProvider.notifier).state =
        ref.read(onboardingStateProvider).copyWith(name: name);

    // Say the name
    final alanko = ref.read(alanVoiceServiceProvider);
    alanko.speak('Drago mi je $name!', mood: AlanMood.happy);

    // Navigate to gender selection
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const GenderSelectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                  'Kako se zoveš?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ).animate().fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 32),

                // Name input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                    border: _showError
                        ? Border.all(color: Colors.red, width: 2)
                        : null,
                  ),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Upiši svoje ime',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                    onChanged: (_) {
                      if (_showError) setState(() => _showError = false);
                    },
                    onSubmitted: (_) => _continue(),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),

                if (_showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Molim te upiši svoje ime',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),

                const Spacer(),

                // Continue button
                GestureDetector(
                  onTap: _continue,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.alanGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Nastavi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlanAvatar() {
    return Container(
      width: 120,
      height: 120,
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
                const SizedBox(width: 16),
                _buildEye(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 30,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildEye() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF2D3142),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
