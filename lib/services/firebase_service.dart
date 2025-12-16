import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Auth methods
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      debugPrint('Firebase: Signed in anonymously as ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Firebase: Signed out');
    } catch (e) {
      debugPrint('Firebase Sign Out Error: $e');
    }
  }

  // Firestore - Child Profile
  Future<void> saveChildProfile({
    required String name,
    required int age,
    required String preferredLanguage,
    String? gender,
  }) async {
    if (currentUser == null) {
      debugPrint('Firebase: No user signed in, cannot save profile');
      return;
    }

    try {
      await _firestore
          .collection('children')
          .doc(currentUser!.uid)
          .set({
        'name': name,
        'age': age,
        'preferredLanguage': preferredLanguage,
        'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Firebase: Profile saved for ${currentUser!.uid}');
    } catch (e) {
      debugPrint('Firebase Save Profile Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getChildProfile() async {
    if (currentUser == null) {
      debugPrint('Firebase: No user signed in, cannot get profile');
      return null;
    }

    try {
      final doc = await _firestore
          .collection('children')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        debugPrint('Firebase: Profile loaded for ${currentUser!.uid}');
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Firebase Get Profile Error: $e');
      return null;
    }
  }

  // Firestore - Learning Progress
  Future<void> saveLearningProgress({
    required String topic,
    required int score,
    required int totalQuestions,
    required Duration timeSpent,
  }) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('children')
          .doc(currentUser!.uid)
          .collection('progress')
          .add({
        'topic': topic,
        'score': score,
        'totalQuestions': totalQuestions,
        'timeSpentMs': timeSpent.inMilliseconds,
        'accuracy': totalQuestions > 0 ? score / totalQuestions : 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Firebase: Progress saved for topic $topic');
    } catch (e) {
      debugPrint('Firebase Save Progress Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLearningProgress({
    String? topic,
    int limit = 50,
  }) async {
    if (currentUser == null) return [];

    try {
      Query query = _firestore
          .collection('children')
          .doc(currentUser!.uid)
          .collection('progress')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (topic != null) {
        query = query.where('topic', isEqualTo: topic);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Firebase Get Progress Error: $e');
      return [];
    }
  }

  // Analytics
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.map((key, value) => MapEntry(key, value.toString())),
      );
    } catch (e) {
      debugPrint('Firebase Analytics Error: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Firebase Screen View Error: $e');
    }
  }

  Future<void> setUserProperties({required int age, required String language}) async {
    try {
      await _analytics.setUserProperty(name: 'age_group', value: _getAgeGroup(age));
      await _analytics.setUserProperty(name: 'language', value: language);
    } catch (e) {
      debugPrint('Firebase User Properties Error: $e');
    }
  }

  String _getAgeGroup(int age) {
    if (age <= 5) return 'preschool';
    if (age <= 8) return 'early_school';
    return 'late_school';
  }

  // Leaderboard
  Future<void> saveLeaderboardScore({
    required String gameType,
    required int score,
    required String displayName,
  }) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('leaderboard').add({
        'userId': currentUser!.uid,
        'gameType': gameType,
        'score': score,
        'displayName': displayName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firebase Leaderboard Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    required String gameType,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboard')
          .where('gameType', isEqualTo: gameType)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      debugPrint('Firebase Get Leaderboard Error: $e');
      return [];
    }
  }
}

// Riverpod providers
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
