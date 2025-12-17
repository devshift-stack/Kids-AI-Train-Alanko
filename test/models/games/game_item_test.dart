import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alanko_ai/models/games/game_item.dart';

void main() {
  group('GameResult', () {
    group('accuracy', () {
      test('berechnet Genauigkeit korrekt', () {
        final result = GameResult(
          totalQuestions: 10,
          correctAnswers: 8,
          timeTaken: const Duration(seconds: 60),
          completedAt: DateTime.now(),
        );

        expect(result.accuracy, equals(80.0));
      });

      test('gibt 100 bei allen richtigen Antworten', () {
        final result = GameResult(
          totalQuestions: 5,
          correctAnswers: 5,
          timeTaken: const Duration(seconds: 30),
          completedAt: DateTime.now(),
        );

        expect(result.accuracy, equals(100.0));
      });

      test('gibt 0 bei keinen richtigen Antworten', () {
        final result = GameResult(
          totalQuestions: 10,
          correctAnswers: 0,
          timeTaken: const Duration(seconds: 60),
          completedAt: DateTime.now(),
        );

        expect(result.accuracy, equals(0.0));
      });

      test('gibt 0 bei 0 Fragen (Division by Zero)', () {
        final result = GameResult(
          totalQuestions: 0,
          correctAnswers: 0,
          timeTaken: const Duration(seconds: 0),
          completedAt: DateTime.now(),
        );

        expect(result.accuracy, equals(0.0));
      });
    });

    group('isPerfect', () {
      test('ist true wenn alle Antworten korrekt', () {
        final result = GameResult(
          totalQuestions: 10,
          correctAnswers: 10,
          timeTaken: const Duration(seconds: 60),
          completedAt: DateTime.now(),
        );

        expect(result.isPerfect, isTrue);
      });

      test('ist false wenn nicht alle Antworten korrekt', () {
        final result = GameResult(
          totalQuestions: 10,
          correctAnswers: 9,
          timeTaken: const Duration(seconds: 60),
          completedAt: DateTime.now(),
        );

        expect(result.isPerfect, isFalse);
      });

      test('ist false bei 0 korrekten Antworten', () {
        final result = GameResult(
          totalQuestions: 10,
          correctAnswers: 0,
          timeTaken: const Duration(seconds: 60),
          completedAt: DateTime.now(),
        );

        expect(result.isPerfect, isFalse);
      });
    });
  });

  group('NumbersData', () {
    group('getNumbers', () {
      test('gibt korrekte Anzahl Items zurueck', () {
        final numbers = NumbersData.getNumbers(10);

        expect(numbers.length, equals(11)); // 0 bis 10 = 11 Items
      });

      test('erstes Item ist 0', () {
        final numbers = NumbersData.getNumbers(10);

        expect(numbers.first.value, equals('0'));
      });

      test('letztes Item ist max', () {
        final numbers = NumbersData.getNumbers(10);

        expect(numbers.last.value, equals('10'));
      });

      test('gibt ein Item bei getNumbers(0)', () {
        final numbers = NumbersData.getNumbers(0);

        expect(numbers.length, equals(1));
        expect(numbers.first.value, equals('0'));
      });

      test('alle Items haben Color', () {
        final numbers = NumbersData.getNumbers(10);

        for (final item in numbers) {
          expect(item.color, isA<Color>());
        }
      });
    });
  });

  group('ColorsData', () {
    group('getColors', () {
      test('gibt bosnische Farben fuer bs', () {
        final colors = ColorsData.getColors('bs');

        expect(colors, isNotEmpty);
        expect(colors.first.displayText, equals('Crvena'));
      });

      test('gibt englische Farben fuer en', () {
        final colors = ColorsData.getColors('en');

        expect(colors, isNotEmpty);
        expect(colors.first.displayText, equals('Red'));
      });

      test('gibt deutsche Farben fuer de', () {
        final colors = ColorsData.getColors('de');

        expect(colors, isNotEmpty);
        expect(colors.first.displayText, equals('Rot'));
      });

      test('gibt Default (bs) fuer unbekannte Sprache', () {
        final colors = ColorsData.getColors('fr');

        expect(colors, isNotEmpty);
        expect(colors.first.displayText, equals('Crvena'));
      });

      test('alle Farben haben gueltige Color-Objekte', () {
        final colors = ColorsData.getColors('bs');

        for (final item in colors) {
          expect(item.color, isA<Color>());
        }
      });

      test('colorsByLanguage enthaelt alle erwarteten Sprachen', () {
        expect(ColorsData.colorsByLanguage.containsKey('bs'), isTrue);
        expect(ColorsData.colorsByLanguage.containsKey('en'), isTrue);
        expect(ColorsData.colorsByLanguage.containsKey('de'), isTrue);
      });
    });
  });

  group('LettersData', () {
    test('bosnianAlphabet enthaelt alle Buchstaben', () {
      final letters = LettersData.bosnianAlphabet;

      expect(letters.length, equals(30)); // Bosnisches Alphabet
    });

    test('enthaelt spezielle bosnische Buchstaben', () {
      final letters = LettersData.bosnianAlphabet;
      final ids = letters.map((l) => l.id).toList();

      expect(ids.contains('č'), isTrue);
      expect(ids.contains('ć'), isTrue);
      expect(ids.contains('dž'), isTrue);
      expect(ids.contains('đ'), isTrue);
      expect(ids.contains('š'), isTrue);
      expect(ids.contains('ž'), isTrue);
    });

    test('alle Buchstaben haben Color', () {
      for (final letter in LettersData.bosnianAlphabet) {
        expect(letter.color, isA<Color>());
      }
    });
  });
}
