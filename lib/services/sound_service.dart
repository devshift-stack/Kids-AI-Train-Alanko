import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Sound effects service for the app
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  /// Toggle sound on/off
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Play success sound (correct answer)
  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    await _playSystemSound(SystemSoundType.click);
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Play error sound (wrong answer)
  Future<void> playError() async {
    if (!_soundEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Play reward sound (completed task)
  Future<void> playReward() async {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  /// Play button tap sound
  Future<void> playTap() async {
    if (!_soundEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Play navigation sound
  Future<void> playNavigation() async {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Play level up sound
  Future<void> playLevelUp() async {
    if (!_soundEnabled) return;
    for (int i = 0; i < 3; i++) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _playSystemSound(SystemSoundType type) async {
    try {
      await SystemSound.play(type);
    } catch (e) {
      debugPrint('Sound Error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}

// Provider
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => service.dispose());
  return service;
});
