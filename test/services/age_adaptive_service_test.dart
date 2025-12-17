import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alanko_ai/services/age_adaptive_service.dart';

void main() {
  group('AgeAdaptiveSettings', () {
    group('forAge', () {
      test('gibt preschool Settings fuer Alter 3', () {
        final settings = AgeAdaptiveSettings.forAge(3);

        expect(settings.ageGroup, equals(AgeGroup.preschool));
        expect(settings.age, equals(3));
      });

      test('gibt preschool Settings fuer Alter 5', () {
        final settings = AgeAdaptiveSettings.forAge(5);

        expect(settings.ageGroup, equals(AgeGroup.preschool));
        expect(settings.fontSize, equals(24.0));
        expect(settings.maxChoicesPerQuestion, equals(2));
        expect(settings.useSimpleLanguage, isTrue);
      });

      test('gibt earlySchool Settings fuer Alter 6', () {
        final settings = AgeAdaptiveSettings.forAge(6);

        expect(settings.ageGroup, equals(AgeGroup.earlySchool));
        expect(settings.fontSize, equals(20.0));
        expect(settings.maxChoicesPerQuestion, equals(3));
      });

      test('gibt earlySchool Settings fuer Alter 8', () {
        final settings = AgeAdaptiveSettings.forAge(8);

        expect(settings.ageGroup, equals(AgeGroup.earlySchool));
        expect(settings.useSimpleLanguage, isFalse);
      });

      test('gibt lateSchool Settings fuer Alter 9', () {
        final settings = AgeAdaptiveSettings.forAge(9);

        expect(settings.ageGroup, equals(AgeGroup.lateSchool));
        expect(settings.fontSize, equals(16.0));
        expect(settings.maxChoicesPerQuestion, equals(4));
        expect(settings.showTextLabels, isFalse);
      });

      test('gibt lateSchool Settings fuer Alter 12', () {
        final settings = AgeAdaptiveSettings.forAge(12);

        expect(settings.ageGroup, equals(AgeGroup.lateSchool));
      });
    });

    group('speechRate nach Alter', () {
      test('preschool hat langsamste Sprechrate', () {
        final preschool = AgeAdaptiveSettings.forAge(4);
        final earlySchool = AgeAdaptiveSettings.forAge(7);
        final lateSchool = AgeAdaptiveSettings.forAge(10);

        expect(preschool.speechRate, lessThan(earlySchool.speechRate));
        expect(earlySchool.speechRate, lessThan(lateSchool.speechRate));
      });
    });

    group('activityDuration nach Alter', () {
      test('preschool hat kuerzeste Aktivitaetsdauer', () {
        final preschool = AgeAdaptiveSettings.forAge(4);
        final earlySchool = AgeAdaptiveSettings.forAge(7);
        final lateSchool = AgeAdaptiveSettings.forAge(10);

        expect(preschool.activityDuration.inMinutes, equals(5));
        expect(earlySchool.activityDuration.inMinutes, equals(10));
        expect(lateSchool.activityDuration.inMinutes, equals(15));
      });
    });

    group('copyWith', () {
      test('aendert nur angegebene Felder', () {
        final original = AgeAdaptiveSettings.forAge(6);
        final updated = original.copyWith(fontSize: 30.0);

        expect(updated.fontSize, equals(30.0));
        expect(updated.age, equals(original.age));
        expect(updated.ageGroup, equals(original.ageGroup));
      });
    });
  });

  group('AgeAdaptiveService', () {
    late SharedPreferences prefs;
    late AgeAdaptiveService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'child_age': 6});
      prefs = await SharedPreferences.getInstance();
      service = AgeAdaptiveService(prefs);
    });

    group('settings', () {
      test('gibt aktuelle Settings zurueck', () {
        expect(service.settings, isA<AgeAdaptiveSettings>());
        expect(service.currentAge, equals(6));
      });

      test('currentAgeGroup ist korrekt', () {
        expect(service.currentAgeGroup, equals(AgeGroup.earlySchool));
      });
    });

    group('setAge', () {
      test('aktualisiert Alter und Settings', () async {
        await service.setAge(10);

        expect(service.currentAge, equals(10));
        expect(service.currentAgeGroup, equals(AgeGroup.lateSchool));
      });
    });

    group('adaptText', () {
      test('gibt Text unveraendert wenn useSimpleLanguage false', () async {
        await service.setAge(10); // lateSchool - useSimpleLanguage = false

        final text = 'Dies ist ein Beispieltext.';
        final adapted = service.adaptText(text);

        expect(adapted, equals(text));
      });

      test('nutzt variant wenn vorhanden', () async {
        final variants = {
          AgeGroup.preschool: 'Einfacher Text',
          AgeGroup.earlySchool: 'Mittlerer Text',
          AgeGroup.lateSchool: 'Komplexer Text',
        };

        await service.setAge(10);
        final adapted = service.adaptText('Default', variants: variants);

        expect(adapted, equals('Komplexer Text'));
      });
    });

    group('adaptChoices', () {
      test('begrenzt Auswahl auf maxChoicesPerQuestion', () async {
        await service.setAge(4); // preschool - max 2 choices
        final choices = ['A', 'B', 'C', 'D'];
        final adapted = service.adaptChoices(choices);

        expect(adapted.length, equals(2));
      });

      test('gibt alle zurueck wenn weniger als max', () async {
        await service.setAge(4); // preschool - max 2 choices
        final choices = ['A', 'B'];
        final adapted = service.adaptChoices(choices);

        expect(adapted.length, equals(2));
      });
    });

    group('getAdaptedFontSize', () {
      test('preschool hat groessten Multiplikator', () async {
        await service.setAge(4);
        final adapted = service.getAdaptedFontSize(14.0);

        expect(adapted, equals(14.0 * 1.4)); // 1.4x fuer preschool
      });

      test('lateSchool hat Multiplikator 1.0', () async {
        await service.setAge(10);
        final adapted = service.getAdaptedFontSize(14.0);

        expect(adapted, equals(14.0)); // 1.0x fuer lateSchool
      });
    });

    group('getAdaptedIconSize', () {
      test('preschool hat groessten Multiplikator', () async {
        await service.setAge(4);
        final adapted = service.getAdaptedIconSize(24.0);

        expect(adapted, equals(24.0 * 1.5)); // 1.5x fuer preschool
      });
    });

    group('getTopicsForAgeGroup', () {
      test('preschool hat Basis-Themen', () async {
        await service.setAge(4);
        final topics = service.getTopicsForAgeGroup();

        expect(topics.contains('colors'), isTrue);
        expect(topics.contains('shapes'), isTrue);
        expect(topics.contains('animals'), isTrue);
        expect(topics.contains('coding_intro'), isFalse);
      });

      test('lateSchool hat fortgeschrittene Themen', () async {
        await service.setAge(10);
        final topics = service.getTopicsForAgeGroup();

        expect(topics.contains('coding_intro'), isTrue);
        expect(topics.contains('critical_thinking'), isTrue);
      });
    });

    group('getDifficultyLevel', () {
      test('gibt 1 fuer preschool', () async {
        await service.setAge(4);
        expect(service.getDifficultyLevel(), equals(1));
      });

      test('gibt 2 fuer earlySchool', () async {
        await service.setAge(7);
        expect(service.getDifficultyLevel(), equals(2));
      });

      test('gibt 3 fuer lateSchool', () async {
        await service.setAge(10);
        expect(service.getDifficultyLevel(), equals(3));
      });
    });

    group('getAdaptedAnimationDuration', () {
      test('preschool hat laengere Animationen', () async {
        await service.setAge(4);
        final base = const Duration(milliseconds: 300);
        final adapted = service.getAdaptedAnimationDuration(base);

        expect(adapted.inMilliseconds, equals(450)); // 1.5x
      });

      test('lateSchool hat Standard-Animationen', () async {
        await service.setAge(10);
        final base = const Duration(milliseconds: 300);
        final adapted = service.getAdaptedAnimationDuration(base);

        expect(adapted.inMilliseconds, equals(300)); // 1.0x
      });
    });
  });
}
