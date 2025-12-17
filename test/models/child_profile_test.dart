import 'package:flutter_test/flutter_test.dart';
import 'package:alanko_ai/models/child_profile.dart';

void main() {
  group('ChildProfile', () {
    final validJson = {
      'id': 'test-id',
      'name': 'Max',
      'age': 6,
      'preferredLanguage': 'de',
      'avatarUrl': 'https://example.com/avatar.png',
      'createdAt': '2024-01-01T00:00:00.000Z',
      'lastActiveAt': '2024-01-15T10:30:00.000Z',
      'topicProgress': {'math': 50, 'colors': 100},
    };

    group('fromJson', () {
      test('parsed alle Felder korrekt', () {
        final profile = ChildProfile.fromJson(validJson);

        expect(profile.id, equals('test-id'));
        expect(profile.name, equals('Max'));
        expect(profile.age, equals(6));
        expect(profile.preferredLanguage, equals('de'));
        expect(profile.avatarUrl, equals('https://example.com/avatar.png'));
        expect(profile.topicProgress['math'], equals(50));
      });

      test('gibt Default fuer preferredLanguage wenn fehlend', () {
        final json = Map<String, dynamic>.from(validJson)
          ..remove('preferredLanguage');
        final profile = ChildProfile.fromJson(json);

        expect(profile.preferredLanguage, equals('bs'));
      });

      test('handled null lastActiveAt', () {
        final json = Map<String, dynamic>.from(validJson)
          ..remove('lastActiveAt');
        final profile = ChildProfile.fromJson(json);

        expect(profile.lastActiveAt, isNull);
      });

      test('gibt leere topicProgress Map wenn fehlend', () {
        final json = Map<String, dynamic>.from(validJson)
          ..remove('topicProgress');
        final profile = ChildProfile.fromJson(json);

        expect(profile.topicProgress, isEmpty);
      });
    });

    group('toJson', () {
      test('konvertiert alle Felder korrekt', () {
        final profile = ChildProfile.fromJson(validJson);
        final json = profile.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['name'], equals('Max'));
        expect(json['age'], equals(6));
        expect(json['preferredLanguage'], equals('de'));
        expect(json['topicProgress'], isA<Map>());
      });

      test('handled null avatarUrl', () {
        final json = Map<String, dynamic>.from(validJson)..['avatarUrl'] = null;
        final profile = ChildProfile.fromJson(json);
        final result = profile.toJson();

        expect(result['avatarUrl'], isNull);
      });
    });

    group('toJson/fromJson Roundtrip', () {
      test('erhält alle Daten bei Roundtrip', () {
        final original = ChildProfile.fromJson(validJson);
        final json = original.toJson();
        final restored = ChildProfile.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.age, equals(original.age));
        expect(restored.preferredLanguage, equals(original.preferredLanguage));
        expect(restored.avatarUrl, equals(original.avatarUrl));
      });
    });

    group('copyWith', () {
      test('aendert nur angegebene Felder', () {
        final profile = ChildProfile.fromJson(validJson);
        final updated = profile.copyWith(name: 'Anna', age: 8);

        expect(updated.name, equals('Anna'));
        expect(updated.age, equals(8));
        expect(updated.id, equals(profile.id)); // Unveraendert
        expect(updated.preferredLanguage, equals(profile.preferredLanguage));
      });

      test('behaelt alle Felder wenn keine Aenderung', () {
        final profile = ChildProfile.fromJson(validJson);
        final copy = profile.copyWith();

        expect(copy.id, equals(profile.id));
        expect(copy.name, equals(profile.name));
        expect(copy.age, equals(profile.age));
      });
    });

    group('Equatable', () {
      test('zwei Profile mit gleichen Daten sind equal', () {
        final profile1 = ChildProfile.fromJson(validJson);
        final profile2 = ChildProfile.fromJson(validJson);

        expect(profile1, equals(profile2));
      });

      test('zwei Profile mit unterschiedlichen Daten sind nicht equal', () {
        final profile1 = ChildProfile.fromJson(validJson);
        final json2 = Map<String, dynamic>.from(validJson)..['name'] = 'Anna';
        final profile2 = ChildProfile.fromJson(json2);

        expect(profile1, isNot(equals(profile2)));
      });
    });

    group('Edge Cases', () {
      test('handled leeren Namen', () {
        final json = Map<String, dynamic>.from(validJson)..['name'] = '';
        final profile = ChildProfile.fromJson(json);

        expect(profile.name, equals(''));
      });

      test('handled Alter = 0', () {
        final json = Map<String, dynamic>.from(validJson)..['age'] = 0;
        final profile = ChildProfile.fromJson(json);

        expect(profile.age, equals(0));
      });
    });
  });
}
