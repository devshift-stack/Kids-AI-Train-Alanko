import 'package:flutter_test/flutter_test.dart';
import 'package:alanko_ai/services/user_profile_service.dart';

void main() {
  group('UserProfile', () {
    test('creates profile with required fields', () {
      final profile = UserProfile(
        id: '123',
        name: 'Test',
        gender: Gender.boy,
        age: 6,
        createdAt: DateTime.now(),
      );

      expect(profile.id, '123');
      expect(profile.name, 'Test');
      expect(profile.gender, Gender.boy);
      expect(profile.age, 6);
      expect(profile.isComplete, true);
    });

    test('isComplete returns false for empty name', () {
      final profile = UserProfile(
        id: '123',
        name: '',
        gender: Gender.girl,
        age: 5,
        createdAt: DateTime.now(),
      );

      expect(profile.isComplete, false);
    });

    test('isComplete returns false for zero age', () {
      final profile = UserProfile(
        id: '123',
        name: 'Test',
        gender: Gender.boy,
        age: 0,
        createdAt: DateTime.now(),
      );

      expect(profile.isComplete, false);
    });

    test('toJson and fromJson work correctly', () {
      final original = UserProfile(
        id: '456',
        name: 'Anna',
        gender: Gender.girl,
        age: 8,
        languageCode: 'de',
        createdAt: DateTime(2025, 1, 1),
        canSeeLeaderboard: true,
        canBeOnLeaderboard: false,
        leaderboardDisplayName: 'AnnaGirl',
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.gender, original.gender);
      expect(restored.age, original.age);
      expect(restored.languageCode, original.languageCode);
      expect(restored.canSeeLeaderboard, original.canSeeLeaderboard);
      expect(restored.canBeOnLeaderboard, original.canBeOnLeaderboard);
      expect(restored.leaderboardDisplayName, original.leaderboardDisplayName);
    });

    test('copyWith creates new instance with updated values', () {
      final original = UserProfile(
        id: '789',
        name: 'Max',
        gender: Gender.boy,
        age: 5,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'Maximilian', age: 6);

      expect(updated.id, original.id);
      expect(updated.name, 'Maximilian');
      expect(updated.age, 6);
      expect(updated.gender, original.gender);
    });

    test('getGreeting returns correct greeting for each language', () {
      final profile = UserProfile(
        id: '1',
        name: 'Test',
        gender: Gender.boy,
        age: 6,
        createdAt: DateTime.now(),
      );

      expect(profile.getGreeting('de'), 'Hallo Test!');
      expect(profile.getGreeting('en'), 'Hello Test!');
      expect(profile.getGreeting('tr'), 'Merhaba Test!');
      expect(profile.getGreeting('bs'), 'Zdravo Test!');
    });

    test('getPreferredThemes returns boy themes for boys', () {
      final profile = UserProfile(
        id: '1',
        name: 'Max',
        gender: Gender.boy,
        age: 6,
        createdAt: DateTime.now(),
      );

      final themes = profile.getPreferredThemes();
      expect(themes, contains('cars'));
      expect(themes, contains('dinosaurs'));
      expect(themes, contains('robots'));
    });

    test('getPreferredThemes returns girl themes for girls', () {
      final profile = UserProfile(
        id: '1',
        name: 'Anna',
        gender: Gender.girl,
        age: 6,
        createdAt: DateTime.now(),
      );

      final themes = profile.getPreferredThemes();
      expect(themes, contains('princesses'));
      expect(themes, contains('unicorns'));
      expect(themes, contains('fairies'));
    });

    test('leaderboard fields default to false', () {
      final profile = UserProfile(
        id: '1',
        name: 'Test',
        gender: Gender.boy,
        age: 6,
        createdAt: DateTime.now(),
      );

      expect(profile.canSeeLeaderboard, false);
      expect(profile.canBeOnLeaderboard, false);
      expect(profile.leaderboardDisplayName, null);
    });
  });

  group('OnboardingState', () {
    test('copyWith updates only specified fields', () {
      const state = OnboardingState(name: 'Test', gender: Gender.boy, age: 5);
      final updated = state.copyWith(age: 7);

      expect(updated.name, 'Test');
      expect(updated.gender, Gender.boy);
      expect(updated.age, 7);
    });
  });
}
