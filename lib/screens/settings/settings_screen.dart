import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';
import '../../services/alan_voice_service.dart';
import '../../services/user_profile_service.dart';
import '../language_selection/language_selection_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _voiceVolume = 1.0;
  double _soundEffectsVolume = 1.0;
  bool _musicEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    Future.microtask(() {
      ref.read(alanVoiceServiceProvider).speak(
        'Einstellungen',
        mood: AlanMood.calm,
      );
    });
  }

  Future<void> _loadSettings() async {
    // Load settings from SharedPreferences
    // For now using defaults
    setState(() {
      _voiceVolume = 0.8;
      _soundEffectsVolume = 1.0;
      _musicEnabled = false;
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildSoundSection(),
                const SizedBox(height: 16),
                _buildLanguageSection(context),
                const SizedBox(height: 16),
                _buildLeaderboardSection(context),
                const SizedBox(height: 16),
                _buildAboutSection(),
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
            'Einstellungen',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSoundSection() {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.volume_up, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ton',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Alanko Voice Volume
            _buildVolumeSlider(
              label: 'Alanko Stimme',
              emoji: '🗣️',
              value: _voiceVolume,
              onChanged: (value) {
                setState(() => _voiceVolume = value);
                if (value > 0) {
                  ref.read(alanVoiceServiceProvider).speak(
                    'So klingt meine Stimme',
                    mood: AlanMood.happy,
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Sound Effects Volume
            _buildVolumeSlider(
              label: 'Soundeffekte',
              emoji: '🔔',
              value: _soundEffectsVolume,
              onChanged: (value) {
                setState(() => _soundEffectsVolume = value);
              },
            ),

            const SizedBox(height: 16),

            // Music Toggle
            Row(
              children: [
                const Text('🎵', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Hintergrundmusik',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: _musicEnabled,
                  onChanged: (value) {
                    setState(() => _musicEnabled = value);
                  },
                  activeTrackColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildVolumeSlider({
    required String label,
    required String emoji,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Slider(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.primaryColor,
                inactiveColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value > 0 ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final currentLocale = context.locale;
    final languageNames = {
      'bs': '🇧🇦 Bosanski',
      'de': '🇩🇪 Deutsch',
      'en': '🇬🇧 English',
      'hr': '🇭🇷 Hrvatski',
      'sr': '🇷🇸 Srpski',
      'tr': '🇹🇷 Türkçe',
    };
    final currentLanguage = languageNames[currentLocale.languageCode] ?? 'Unknown';

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sprache',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openLanguageSelection(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Text(
                      currentLanguage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildLeaderboardSection(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final canSeeLeaderboard = profile?.canSeeLeaderboard ?? false;

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.leaderboard, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rangliste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (canSeeLeaderboard)
              GestureDetector(
                onTap: () => _openLeaderboard(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.alanGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Rangliste anzeigen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Die Rangliste muss von deinen Eltern freigeschaltet werden.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildAboutSection() {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Über Alanko',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '1.0.0'),
            const SizedBox(height: 8),
            _buildInfoRow('Entwickelt von', 'DevShift'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPrivacyPolicy(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Datenschutz',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImprint(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Impressum',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _openLanguageSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
    );
  }

  void _openLeaderboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Datenschutz'),
        content: const SingleChildScrollView(
          child: Text(
            'Alanko AI respektiert die Privatsphäre von Kindern.\n\n'
            '• Wir sammeln nur die notwendigsten Daten\n'
            '• Profile werden lokal auf dem Gerät gespeichert\n'
            '• Ranglisten-Teilnahme ist optional und erfordert Elternzustimmung\n'
            '• Keine Werbung in der App\n'
            '• Kindersichere KI-Inhalte\n\n'
            'Für weitere Informationen kontaktieren Sie uns unter:\n'
            'privacy@devshift.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showImprint(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Impressum'),
        content: const SingleChildScrollView(
          child: Text(
            'Alanko AI\n'
            'Eine Lern-App für Kinder\n\n'
            'Entwickelt von DevShift\n\n'
            'Kontakt:\n'
            'info@devshift.com\n\n'
            '© 2024 DevShift. Alle Rechte vorbehalten.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
