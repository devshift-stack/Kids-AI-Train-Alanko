import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';
import '../../services/age_adaptive_service.dart';
import '../../services/youtube_reward_service.dart';
import '../../services/parent_child_service.dart';
import '../../models/youtube/youtube_settings.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  final _pinController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  // YouTube Settings State (standardmäßig AUS)
  bool _youtubeEnabled = false;
  int _watchMinutes = 10;
  int _tasksRequired = 3;
  int _dailyLimit = 60;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final parentService = ref.read(parentChildServiceProvider);
    await parentService.initialize();
    await _loadYouTubeSettings();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadYouTubeSettings() async {
    final parentService = ref.read(parentChildServiceProvider);
    final settings = await parentService.loadYouTubeSettings();

    if (settings != null) {
      setState(() {
        _youtubeEnabled = settings['isEnabled'] ?? false;
        _watchMinutes = settings['watchMinutesAllowed'] ?? 10;
        _tasksRequired = settings['tasksRequired'] ?? 3;
        _dailyLimit = settings['dailyLimitMinutes'] ?? 60;
      });
    }
    // Wenn keine Settings vorhanden, bleibt YouTube AUS (default)
  }

  Future<void> _saveYouTubeSettings() async {
    final parentService = ref.read(parentChildServiceProvider);

    final settings = YouTubeSettings(
      isEnabled: _youtubeEnabled,
      watchMinutesAllowed: _watchMinutes,
      tasksRequired: _tasksRequired,
      dailyLimitMinutes: _dailyLimit,
    );

    try {
      await parentService.saveYouTubeSettings(settings.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('YouTube Einstellungen gespeichert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyPin() async {
    final parentService = ref.read(parentChildServiceProvider);

    // Wenn noch kein Parent Account existiert, erstellen
    if (parentService.parentId == null) {
      await parentService.createParentAccount(pin: _pinController.text);
      setState(() => _isAuthenticated = true);
      return;
    }

    // Sonst PIN verifizieren
    final isValid = await parentService.verifyPin(_pinController.text);
    if (isValid) {
      setState(() => _isAuthenticated = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falscher PIN')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAuthenticated) {
      return _buildPinScreen();
    }
    return _buildDashboard();
  }

  Widget _buildPinScreen() {
    final parentService = ref.watch(parentChildServiceProvider);
    final isFirstTime = parentService.parentId == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eltern-Zugang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                isFirstTime ? 'PIN erstellen' : 'PIN eingeben',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                isFirstTime
                    ? 'Erstelle einen 4-stelligen PIN für den Elternbereich'
                    : 'Dieser Bereich ist nur für Eltern',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '• • • •',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyPin,
                child: Text(isFirstTime ? 'PIN erstellen' : 'Entsperren'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final ageService = ref.watch(ageAdaptiveServiceProvider);
    final childName = ageService.getChildName() ?? 'Child';
    final childAge = ageService.currentAge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Info Card
            _buildInfoCard(
              title: 'Child Profile',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.getAgeGroupColor(childAge),
                    child: Text(
                      childName.isNotEmpty ? childName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '$childAge years old',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editChildProfile(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Learning Progress
            _buildInfoCard(
              title: 'Learning Progress',
              child: Column(
                children: [
                  _buildProgressItem('Colors', 0.8, AppTheme.preschoolColor),
                  _buildProgressItem('Numbers', 0.6, AppTheme.earlySchoolColor),
                  _buildProgressItem('Shapes', 0.4, AppTheme.lateSchoolColor),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Screen Time
            _buildInfoCard(
              title: 'Screen Time Today',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', '45 min', Icons.timer),
                  _buildStatItem('Learning', '30 min', Icons.school),
                  _buildStatItem('Games', '15 min', Icons.games),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // YouTube Reward Settings (NEU)
            _buildYouTubeSettingsCard(),

            const SizedBox(height: 16),

            // Settings Section
            _buildInfoCard(
              title: 'Settings',
              child: Column(
                children: [
                  _buildSettingItem(
                    'Daily Time Limit',
                    '60 minutes',
                    Icons.access_time,
                    onTap: () => _setTimeLimit(),
                  ),
                  _buildSettingItem(
                    'Content Filter',
                    'Age Appropriate',
                    Icons.filter_list,
                    onTap: () => _setContentFilter(),
                  ),
                  _buildSettingItem(
                    'Language',
                    context.locale.languageCode.toUpperCase(),
                    Icons.language,
                    onTap: () => _changeLanguage(),
                  ),
                  _buildSettingItem(
                    'Notifications',
                    'Enabled',
                    Icons.notifications,
                    onTap: () => _toggleNotifications(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: _youtubeEnabled ? Colors.red.shade300 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_circle, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YouTube Belohnungssystem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Videos nach erledigten Aufgaben',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _youtubeEnabled,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() => _youtubeEnabled = value);
                },
              ),
            ],
          ),

          if (_youtubeEnabled) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Watch Minutes Setting
            _buildSliderSetting(
              label: 'Minuten schauen vor Aufgabe',
              value: _watchMinutes.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              suffix: ' Min',
              onChanged: (value) {
                setState(() => _watchMinutes = value.round());
              },
            ),

            const SizedBox(height: 16),

            // Tasks Required Setting
            _buildSliderSetting(
              label: 'Aufgaben pro Pause',
              value: _tasksRequired.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              suffix: ' Aufgaben',
              onChanged: (value) {
                setState(() => _tasksRequired = value.round());
              },
            ),

            const SizedBox(height: 16),

            // Daily Limit Setting
            _buildSliderSetting(
              label: 'Tägliches Limit',
              value: _dailyLimit.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              suffix: ' Min',
              onChanged: (value) {
                setState(() => _dailyLimit = value.round());
              },
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveYouTubeSettings,
                icon: const Icon(Icons.save),
                label: const Text('Einstellungen speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${value.round()}$suffix',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Colors.red,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${(value * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  void _openSettings() {}
  void _editChildProfile() {}
  void _setTimeLimit() {}
  void _setContentFilter() {}
  void _changeLanguage() {}
  void _toggleNotifications() {}
}
