import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/alan_voice_service.dart';
import '../../services/user_profile_service.dart';
import '../onboarding/name_input_screen.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;
  final String greeting;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.greeting,
  });
}

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen>
    with TickerProviderStateMixin {

  final List<LanguageOption> languages = const [
    LanguageOption(
      code: 'bs',
      name: 'Bosanski',
      flag: '🇧🇦',
      greeting: 'Zdravo! Ja sam Alanko. Na kojem jeziku želiš da pričamo?',
    ),
    LanguageOption(
      code: 'en',
      name: 'English',
      flag: '🇬🇧',
      greeting: 'Hello! I am Alanko. Which language would you like to speak?',
    ),
    LanguageOption(
      code: 'de',
      name: 'Deutsch',
      flag: '🇩🇪',
      greeting: 'Hallo! Ich bin Alanko. In welcher Sprache möchtest du mit mir sprechen?',
    ),
    LanguageOption(
      code: 'hr',
      name: 'Hrvatski',
      flag: '🇭🇷',
      greeting: 'Bok! Ja sam Alanko. Na kojem jeziku želiš razgovarati?',
    ),
    LanguageOption(
      code: 'sr',
      name: 'Srpski',
      flag: '🇷🇸',
      greeting: 'Zdravo! Ja sam Alanko. Na kom jeziku želiš da pričamo?',
    ),
    LanguageOption(
      code: 'tr',
      name: 'Türkçe',
      flag: '🇹🇷',
      greeting: 'Merhaba! Ben Alanko. Hangi dilde konuşmak istersin?',
    ),
  ];

  late AnimationController _tickerController;
  late AnimationController _avatarController;
  int _currentGreetingIndex = 0;
  Timer? _greetingTimer;
  bool _isGreeting = true;

  @override
  void initState() {
    super.initState();

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Start greeting sequence
    Future.delayed(const Duration(milliseconds: 500), _startGreetingSequence);
  }

  void _startGreetingSequence() {
    _speakCurrentGreeting();

    _greetingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentGreetingIndex = (_currentGreetingIndex + 1) % languages.length;
      });
      _speakCurrentGreeting();
    });
  }

  void _speakCurrentGreeting() {
    if (!_isGreeting) return;
    final alan = ref.read(alanVoiceServiceProvider);
    alan.speak(languages[_currentGreetingIndex].greeting, mood: AlanMood.happy);
  }

  void _selectLanguage(LanguageOption language) {
    _isGreeting = false;
    _greetingTimer?.cancel();

    final alan = ref.read(alanVoiceServiceProvider);
    alan.stop();

    // Set locale and language
    context.setLocale(Locale(language.code));
    ref.read(multiProfileServiceProvider).setLanguage(language.code);
    alan.setLanguage(language.code);

    // Navigate to name input
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NameInputScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _tickerController.dispose();
    _avatarController.dispose();
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
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Alan Avatar
              _buildAlanAvatar(),

              const SizedBox(height: 20),

              // Current greeting text
              _buildGreetingText(),

              const SizedBox(height: 40),

              // Animated flag ticker
              _buildFlagTicker(),

              const Spacer(),

              // Language selection grid
              _buildLanguageGrid(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlanAvatar() {
    return AnimatedBuilder(
      animation: _avatarController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _avatarController.value * 10 - 5),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: AppTheme.alanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Eyes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(),
                      const SizedBox(width: 20),
                      _buildEye(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Mouth
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().scale(
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildEye() {
    return Container(
      width: 25,
      height: 25,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF2D3142),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(_currentGreetingIndex),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          languages[_currentGreetingIndex].greeting,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFlagTicker() {
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _tickerController,
        builder: (context, child) {
          return Stack(
            children: List.generate(languages.length, (index) {
              // Calculate position for each flag
              final screenWidth = MediaQuery.of(context).size.width;
              final totalWidth = screenWidth + 200;
              final spacing = totalWidth / 3; // 3 flags visible at a time

              double basePosition = (index * spacing) - (_tickerController.value * totalWidth);

              // Wrap around
              while (basePosition < -100) {
                basePosition += totalWidth;
              }
              while (basePosition > screenWidth + 100) {
                basePosition -= totalWidth;
              }

              return Positioned(
                left: basePosition,
                child: _buildTickerFlag(languages[index]),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTickerFlag(LanguageOption language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.flag,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 8),
          Text(
            language.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Izaberi jezik / Choose language',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: languages.map((lang) => _buildLanguageButton(lang)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(LanguageOption language) {
    return GestureDetector(
      onTap: () => _selectLanguage(language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              language.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * languages.indexOf(language)).ms).scale();
  }
}
