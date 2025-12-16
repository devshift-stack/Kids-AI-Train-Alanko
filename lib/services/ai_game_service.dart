import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gemini_service.dart';
import 'user_profile_service.dart';

class AIGameService {
  final GeminiService _gemini;

  AIGameService(this._gemini);

  /// Generate a word that starts with the given letter
  Future<String> generateWordForLetter(String letter, int age) async {
    final prompt = '''
Gib mir EIN einfaches Wort das mit dem Buchstaben "$letter" beginnt.
Das Wort muss für ein $age-jähriges Kind geeignet sein.
Antworte NUR mit dem Wort, nichts anderes.
Beispiel für "A": Apfel
''';

    try {
      final response = await _gemini.ask(prompt);
      return response.trim().split(' ').first;
    } catch (e) {
      return _getDefaultWordForLetter(letter);
    }
  }

  String _getDefaultWordForLetter(String letter) {
    final defaults = {
      'A': 'Apfel', 'B': 'Ball', 'C': 'Computer', 'D': 'Dino',
      'E': 'Elefant', 'F': 'Fisch', 'G': 'Giraffe', 'H': 'Haus',
      'I': 'Igel', 'J': 'Jaguar', 'K': 'Katze', 'L': 'Löwe',
      'M': 'Maus', 'N': 'Nase', 'O': 'Orange', 'P': 'Papagei',
      'R': 'Rakete', 'S': 'Sonne', 'T': 'Tiger', 'U': 'Uhr',
      'V': 'Vogel', 'Z': 'Zebra',
    };
    return defaults[letter.toUpperCase()] ?? letter;
  }

  /// Generate a math problem for the given age
  Future<Map<String, dynamic>> generateMathProblem(int age) async {
    final difficulty = age <= 5 ? 'sehr einfach (1-5)' :
                       age <= 8 ? 'einfach (1-10)' : 'mittel (1-20)';

    final prompt = '''
Erstelle eine Rechenaufgabe für ein $age-jähriges Kind.
Schwierigkeit: $difficulty

Antworte im Format:
AUFGABE: [z.B. 2 + 3]
ANTWORT: [z.B. 5]
FALSCH1: [falsche Antwort]
FALSCH2: [falsche Antwort]
FALSCH3: [falsche Antwort]
''';

    try {
      final response = await _gemini.ask(prompt);
      return _parseMathResponse(response, age);
    } catch (e) {
      return _getDefaultMathProblem(age);
    }
  }

  Map<String, dynamic> _parseMathResponse(String response, int age) {
    try {
      final lines = response.split('\n');
      String task = '';
      int answer = 0;
      List<int> wrongAnswers = [];

      for (final line in lines) {
        if (line.contains('AUFGABE:')) {
          task = line.split(':').last.trim();
        } else if (line.contains('ANTWORT:')) {
          answer = int.tryParse(line.split(':').last.trim()) ?? 0;
        } else if (line.contains('FALSCH')) {
          final wrong = int.tryParse(line.split(':').last.trim());
          if (wrong != null) wrongAnswers.add(wrong);
        }
      }

      if (task.isEmpty || wrongAnswers.length < 3) {
        return _getDefaultMathProblem(age);
      }

      return {
        'task': task,
        'answer': answer,
        'wrongAnswers': wrongAnswers.take(3).toList(),
      };
    } catch (e) {
      return _getDefaultMathProblem(age);
    }
  }

  Map<String, dynamic> _getDefaultMathProblem(int age) {
    final max = age <= 5 ? 5 : age <= 8 ? 10 : 20;
    final a = (DateTime.now().millisecond % max) + 1;
    final b = (DateTime.now().second % (max - a)) + 1;
    final answer = a + b;

    return {
      'task': '$a + $b',
      'answer': answer,
      'wrongAnswers': [answer + 1, answer - 1, answer + 2],
    };
  }

  /// Generate a color quiz question
  Future<Map<String, dynamic>> generateColorQuiz(int age) async {
    final prompt = '''
Erstelle eine Farben-Frage für ein $age-jähriges Kind.
Beispiel: "Welche Farbe hat eine Banane?"

Antworte im Format:
FRAGE: [Frage]
ANTWORT: [Farbe auf Bosnisch, z.B. Žuta]
FARBE_CODE: [yellow/red/blue/green/orange/purple/pink/brown]
''';

    try {
      final response = await _gemini.ask(prompt);
      return _parseColorResponse(response);
    } catch (e) {
      return _getDefaultColorQuiz();
    }
  }

  Map<String, dynamic> _parseColorResponse(String response) {
    try {
      final lines = response.split('\n');
      String question = '';
      String answer = '';
      String colorCode = '';

      for (final line in lines) {
        if (line.contains('FRAGE:')) {
          question = line.split(':').last.trim();
        } else if (line.contains('ANTWORT:')) {
          answer = line.split(':').last.trim();
        } else if (line.contains('FARBE_CODE:')) {
          colorCode = line.split(':').last.trim().toLowerCase();
        }
      }

      if (question.isEmpty) return _getDefaultColorQuiz();

      return {
        'question': question,
        'answer': answer,
        'colorCode': colorCode,
      };
    } catch (e) {
      return _getDefaultColorQuiz();
    }
  }

  Map<String, dynamic> _getDefaultColorQuiz() {
    final quizzes = [
      {'question': 'Welche Farbe hat eine Banane?', 'answer': 'Žuta', 'colorCode': 'yellow'},
      {'question': 'Welche Farbe hat der Himmel?', 'answer': 'Plava', 'colorCode': 'blue'},
      {'question': 'Welche Farbe hat Gras?', 'answer': 'Zelena', 'colorCode': 'green'},
      {'question': 'Welche Farbe hat eine Erdbeere?', 'answer': 'Crvena', 'colorCode': 'red'},
    ];
    return quizzes[DateTime.now().second % quizzes.length];
  }

  /// Generate animal facts
  Future<Map<String, dynamic>> generateAnimalQuestion(int age) async {
    final prompt = '''
Erstelle eine Tier-Frage für ein $age-jähriges Kind.

Antworte im Format:
TIER: [Tiername auf Bosnisch]
TIER_EN: [Tiername auf Englisch, klein]
FRAGE: [Einfache Frage über das Tier]
ANTWORT: [Kurze Antwort]
EMOJI: [Tier-Emoji]
''';

    try {
      final response = await _gemini.ask(prompt);
      return _parseAnimalResponse(response);
    } catch (e) {
      return _getDefaultAnimalQuestion();
    }
  }

  Map<String, dynamic> _parseAnimalResponse(String response) {
    try {
      final lines = response.split('\n');
      Map<String, dynamic> result = {};

      for (final line in lines) {
        if (line.contains('TIER:') && !line.contains('TIER_EN')) {
          result['animal'] = line.split(':').last.trim();
        } else if (line.contains('TIER_EN:')) {
          result['animalEn'] = line.split(':').last.trim();
        } else if (line.contains('FRAGE:')) {
          result['question'] = line.split(':').last.trim();
        } else if (line.contains('ANTWORT:')) {
          result['answer'] = line.split(':').last.trim();
        } else if (line.contains('EMOJI:')) {
          result['emoji'] = line.split(':').last.trim();
        }
      }

      if (result['animal'] == null) return _getDefaultAnimalQuestion();
      return result;
    } catch (e) {
      return _getDefaultAnimalQuestion();
    }
  }

  Map<String, dynamic> _getDefaultAnimalQuestion() {
    final animals = [
      {'animal': 'Mačka', 'animalEn': 'cat', 'question': 'Wie macht die Katze?', 'answer': 'Mjau!', 'emoji': '🐱'},
      {'animal': 'Pas', 'animalEn': 'dog', 'question': 'Wie macht der Hund?', 'answer': 'Wau wau!', 'emoji': '🐕'},
      {'animal': 'Krava', 'animalEn': 'cow', 'question': 'Wie macht die Kuh?', 'answer': 'Muh!', 'emoji': '🐄'},
      {'animal': 'Lav', 'animalEn': 'lion', 'question': 'Wo lebt der Löwe?', 'answer': 'In Afrika!', 'emoji': '🦁'},
    ];
    return animals[DateTime.now().second % animals.length];
  }

  /// Generate a shape question
  Future<Map<String, dynamic>> generateShapeQuestion(int age) async {
    final prompt = '''
Erstelle eine Formen-Frage für ein $age-jähriges Kind.

Antworte im Format:
FORM: [Formname auf Bosnisch, z.B. Krug, Kvadrat, Trokut]
FORM_DE: [Formname auf Deutsch]
FRAGE: [Frage über die Form]
SEITEN: [Anzahl der Seiten, 0 für Kreis]
EMOJI: [Form-Emoji wenn vorhanden, sonst leer]
''';

    try {
      final response = await _gemini.ask(prompt);
      return _parseShapeResponse(response);
    } catch (e) {
      return _getDefaultShapeQuestion();
    }
  }

  Map<String, dynamic> _parseShapeResponse(String response) {
    try {
      final lines = response.split('\n');
      Map<String, dynamic> result = {};

      for (final line in lines) {
        if (line.contains('FORM:') && !line.contains('FORM_DE')) {
          result['shape'] = line.split(':').last.trim();
        } else if (line.contains('FORM_DE:')) {
          result['shapeDe'] = line.split(':').last.trim();
        } else if (line.contains('FRAGE:')) {
          result['question'] = line.split(':').last.trim();
        } else if (line.contains('SEITEN:')) {
          result['sides'] = int.tryParse(line.split(':').last.trim()) ?? 0;
        } else if (line.contains('EMOJI:')) {
          result['emoji'] = line.split(':').last.trim();
        }
      }

      if (result['shape'] == null) return _getDefaultShapeQuestion();
      return result;
    } catch (e) {
      return _getDefaultShapeQuestion();
    }
  }

  Map<String, dynamic> _getDefaultShapeQuestion() {
    final shapes = [
      {'shape': 'Krug', 'shapeDe': 'Kreis', 'question': 'Wie viele Ecken hat ein Kreis?', 'sides': 0, 'emoji': '⭕'},
      {'shape': 'Kvadrat', 'shapeDe': 'Quadrat', 'question': 'Wie viele Seiten hat ein Quadrat?', 'sides': 4, 'emoji': '⬜'},
      {'shape': 'Trokut', 'shapeDe': 'Dreieck', 'question': 'Wie viele Ecken hat ein Dreieck?', 'sides': 3, 'emoji': '🔺'},
      {'shape': 'Pravougaonik', 'shapeDe': 'Rechteck', 'question': 'Was hat 4 Seiten aber ist nicht quadratisch?', 'sides': 4, 'emoji': '▬'},
    ];
    return shapes[DateTime.now().second % shapes.length];
  }

  /// Generate a short story
  Future<String> generateStory(int age, String theme) async {
    final prompt = '''
Erzähle eine SEHR kurze Geschichte (maximal 5 Sätze) für ein $age-jähriges Kind.
Thema: $theme
Die Geschichte soll:
- Auf Bosnisch/Kroatisch sein
- Ein Happy End haben
- Einfache Wörter benutzen
- Lustig oder lehrreich sein
''';

    try {
      final response = await _gemini.ask(prompt);
      return response;
    } catch (e) {
      return _getDefaultStory(theme);
    }
  }

  String _getDefaultStory(String theme) {
    return '''
Bio jednom jedan mali $theme koji je živio u šumi.
Jednog dana je našao novog prijatelja.
Zajedno su se igrali cijeli dan.
Na kraju dana, vratili su se kući sretni.
Kraj!
''';
  }
}

// Provider
final aiGameServiceProvider = Provider<AIGameService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return AIGameService(gemini);
});
