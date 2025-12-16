import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';
import '../../services/age_adaptive_service.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  final _pinController = TextEditingController();
  bool _isAuthenticated = false;
  final String _parentPin = '1234'; // In production, store securely

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    if (_pinController.text == _parentPin) {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildPinScreen();
    }
    return _buildDashboard();
  }

  Widget _buildPinScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Access'),
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
                'Enter Parent PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'This area is for parents only',
                style: Theme.of(context).textTheme.bodyMedium,
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
                child: const Text('Enter'),
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
