import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';
import '../../services/age_adaptive_service.dart';
import '../../services/alan_voice_service.dart';
import '../../widgets/alan/alan_character.dart';
import '../../widgets/common/category_card.dart';
import '../games/letters/letters_game_screen.dart';
import '../games/numbers/numbers_game_screen.dart';
import '../games/colors/colors_game_screen.dart';
import '../chat/alanko_chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _welcomeBack();
  }

  void _welcomeBack() {
    final alanService = ref.read(alanVoiceServiceProvider);
    final ageService = ref.read(ageAdaptiveServiceProvider);
    final childName = ageService.getChildName() ?? 'prijatelju';

    final greeting = alanService.getGreeting(childName);
    alanService.speak(greeting, mood: AlanMood.happy);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(ageAdaptiveSettingsProvider);

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
              _buildHeader(settings),
              _buildAlanSection(),
              Expanded(
                child: _buildCategoriesGrid(settings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AgeAdaptiveSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'hello'.tr(),
                style: TextStyle(
                  fontSize: settings.fontSize * 0.8,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                ref.read(ageAdaptiveServiceProvider).getChildName() ?? 'Prijatelju',
                style: TextStyle(
                  fontSize: settings.fontSize * 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.settings,
                onTap: () => _openSettings(),
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.person,
                onTap: () => _openProfile(),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildAlanSection() {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _openChat,
              child: const AlanCharacter(size: 140),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _openChat,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alanko sagt:',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tippe mich an um zu chatten!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.alanGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Chat mit Alanko',
                            style: TextStyle(
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
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlankoChatScreen()),
    );
  }

  Widget _buildCategoriesGrid(AgeAdaptiveSettings settings) {
    final categories = _getCategoriesForAge(settings.ageGroup);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'categories'.tr(),
            style: TextStyle(
              fontSize: settings.fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: settings.ageGroup == AgeGroup.preschool ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryCard(
                  title: category['title']!,
                  icon: category['icon'] as IconData,
                  color: category['color'] as Color,
                  onTap: () => _openCategory(category['route'] as String),
                )
                    .animate(delay: (index * 100).ms)
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8));
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCategoriesForAge(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.preschool:
        return [
          {
            'title': 'letters'.tr(),
            'icon': Icons.abc,
            'color': const Color(0xFF6C63FF),
            'route': '/letters',
          },
          {
            'title': 'numbers'.tr(),
            'icon': Icons.looks_one,
            'color': const Color(0xFFFF9800),
            'route': '/numbers',
          },
          {
            'title': 'colors'.tr(),
            'icon': Icons.palette,
            'color': const Color(0xFF9C27B0),
            'route': '/colors',
          },
          {
            'title': 'shapes'.tr(),
            'icon': Icons.category,
            'color': const Color(0xFF4ECDC4),
            'route': '/shapes',
          },
          {
            'title': 'animals'.tr(),
            'icon': Icons.pets,
            'color': const Color(0xFF95E1D3),
            'route': '/animals',
          },
          {
            'title': 'stories'.tr(),
            'icon': Icons.auto_stories,
            'color': const Color(0xFFA8E6CF),
            'route': '/stories',
          },
        ];
      case AgeGroup.earlySchool:
        return [
          {
            'title': 'letters'.tr(),
            'icon': Icons.abc,
            'color': const Color(0xFF6C63FF),
            'route': '/letters',
          },
          {
            'title': 'numbers'.tr(),
            'icon': Icons.calculate,
            'color': const Color(0xFFFF9800),
            'route': '/numbers',
          },
          {
            'title': 'colors'.tr(),
            'icon': Icons.palette,
            'color': const Color(0xFF9C27B0),
            'route': '/colors',
          },
          {
            'title': 'reading'.tr(),
            'icon': Icons.menu_book,
            'color': const Color(0xFFFF6584),
            'route': '/reading',
          },
          {
            'title': 'science'.tr(),
            'icon': Icons.science,
            'color': const Color(0xFF00D9FF),
            'route': '/science',
          },
          {
            'title': 'stories'.tr(),
            'icon': Icons.auto_stories,
            'color': const Color(0xFFFFB74D),
            'route': '/stories',
          },
        ];
      case AgeGroup.lateSchool:
        return [
          {
            'title': 'math_advanced'.tr(),
            'icon': Icons.functions,
            'color': const Color(0xFF6C63FF),
            'route': '/math-advanced',
          },
          {
            'title': 'history'.tr(),
            'icon': Icons.history_edu,
            'color': const Color(0xFF8D6E63),
            'route': '/history',
          },
          {
            'title': 'science'.tr(),
            'icon': Icons.biotech,
            'color': const Color(0xFF00BCD4),
            'route': '/science',
          },
          {
            'title': 'coding'.tr(),
            'icon': Icons.code,
            'color': const Color(0xFF607D8B),
            'route': '/coding',
          },
          {
            'title': 'languages'.tr(),
            'icon': Icons.translate,
            'color': const Color(0xFFE91E63),
            'route': '/languages',
          },
          {
            'title': 'challenges'.tr(),
            'icon': Icons.emoji_events,
            'color': const Color(0xFFFF9800),
            'route': '/challenges',
          },
        ];
    }
  }

  void _openSettings() {
    // Navigate to settings
  }

  void _openProfile() {
    // Navigate to profile
  }

  void _openCategory(String route) {
    Widget? screen;

    switch (route) {
      case '/letters':
        screen = const LettersGameScreen();
        break;
      case '/numbers':
        screen = const NumbersGameScreen();
        break;
      case '/colors':
        screen = const ColorsGameScreen();
        break;
      default:
        // Coming soon message
        ref.read(alanVoiceServiceProvider).speak(
          'Uskoro dolazi!',
          mood: AlanMood.encouraging,
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }
}
