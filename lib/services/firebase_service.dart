import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase temporarily disabled due to Xcode 26 compatibility issue
// Will be re-enabled when Firebase SDK is updated

class FirebaseService {
  // Stub implementation - Firebase disabled

  Future<void> signInAnonymously() async {
    // TODO: Implement when Firebase is enabled
  }

  Future<void> signOut() async {
    // TODO: Implement when Firebase is enabled
  }

  Future<void> saveChildProfile({
    required String name,
    required int age,
    required String preferredLanguage,
  }) async {
    // TODO: Implement when Firebase is enabled
  }

  Future<Map<String, dynamic>?> getChildProfile() async {
    // TODO: Implement when Firebase is enabled
    return null;
  }

  Future<void> saveLearningProgress({
    required String topic,
    required int score,
    required int totalQuestions,
    required Duration timeSpent,
  }) async {
    // TODO: Implement when Firebase is enabled
  }

  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    // TODO: Implement when Firebase is enabled
  }

  Future<void> logScreenView(String screenName) async {
    // TODO: Implement when Firebase is enabled
  }

  Future<void> setUserProperties({required int age, required String language}) async {
    // TODO: Implement when Firebase is enabled
  }
}

// Riverpod providers
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
