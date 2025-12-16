import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'user_profile_service.dart';

class GeminiService {
  // Free tier API key - 15 requests/minute, 1500/day
  static const String _apiKey = 'AIzaSyD5jBRl-Ti0r_uSyx5JW24H3CySQ8RWrS8';

  GenerativeModel? _model;
  ChatSession? _chat;
  UserProfile? _currentProfile;

  GeminiService() {
    _initModel();
  }

  void _initModel() {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      print('⚠️ Gemini API Key nicht gesetzt! Hole einen kostenlosen Key von https://aistudio.google.com/apikey');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Free tier model
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 256,
      ),
      systemInstruction: Content.text(_getSystemPrompt()),
    );
  }

  String _getSystemPrompt() {
    final profile = _currentProfile;
    final age = profile?.age ?? 6;
    final name = profile?.name ?? 'Kind';
    final isBoy = profile?.gender == Gender.boy;
    final gender = isBoy ? 'Junge' : 'Mädchen';

    return '''
Du bist Alanko, ein freundlicher und lustiger KI-Assistent für Kinder.
Du sprichst mit $name, einem $age Jahre alten $gender.

WICHTIGE REGELN:
- Antworte IMMER auf Bosnisch/Kroatisch/Serbisch (Latinica)
- Benutze einfache, kurze Sätze die ein $age-jähriges Kind versteht
- Sei freundlich, geduldig und ermutigend
- Mache Lernen spielerisch und spaßig
- Antworte in maximal 2-3 kurzen Sätzen
- Benutze keine komplizierten Wörter
- Sei wie ein freundlicher großer Bruder/Schwester
- Wenn du etwas nicht weißt, sag es ehrlich
- Vermeide gruselige, gewalttätige oder unangemessene Inhalte
- Erkläre Dinge mit Beispielen die Kinder kennen (Tiere, Spielzeug, Essen)

THEMEN die $name mag:
${isBoy ? '- Autos, Dinosaurier, Weltraum, Roboter, Superhelden, Sport' : '- Prinzessinnen, Einhörner, Tiere, Natur, Kunst, Feen'}

Beispiel für gute Antworten:
- "Super Frage! Weißt du, Dinosaurier lebten vor ganz, ganz langer Zeit."
- "Das ist toll! Du bist sehr schlau."
- "Lass uns ein Spiel spielen! Rate mal..."
''';
  }

  void setProfile(UserProfile profile) {
    _currentProfile = profile;
    _initModel();
    _chat = null; // Reset chat for new profile
  }

  Future<String> ask(String question) async {
    if (_model == null) {
      return 'Alanko ist gerade müde. Frag mich später nochmal!';
    }

    try {
      _chat ??= _model!.startChat();

      final response = await _chat!.sendMessage(Content.text(question));
      return response.text ?? 'Hmm, das weiß ich nicht. Frag mich etwas anderes!';
    } catch (e) {
      print('Gemini Error: $e');
      if (e.toString().contains('quota')) {
        return 'Alanko braucht eine kleine Pause. Wir haben heute schon viel geredet!';
      }
      return 'Ups, da ist etwas schief gegangen. Versuch es nochmal!';
    }
  }

  Future<String> generateStory({
    required String theme,
    required int age,
  }) async {
    if (_model == null) {
      return 'Alanko kann gerade keine Geschichte erzählen.';
    }

    final prompt = '''
Erzähle eine kurze, lustige Geschichte für ein $age-jähriges Kind.
Thema: $theme
Die Geschichte soll:
- Maximal 100 Wörter haben
- Ein Happy End haben
- Einfache Wörter benutzen
- Spannend und lustig sein
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Es war einmal... Oh, ich habe den Faden verloren!';
    } catch (e) {
      print('Gemini Story Error: $e');
      return 'Alanko ist gerade müde. Die Geschichte erzähle ich dir morgen!';
    }
  }

  Future<String> generateQuiz({
    required String topic,
    required int age,
  }) async {
    if (_model == null) {
      return 'Quiz nicht verfügbar.';
    }

    final prompt = '''
Erstelle eine einfache Quiz-Frage für ein $age-jähriges Kind.
Thema: $topic
Format:
Frage: [einfache Frage]
A) [Antwort 1]
B) [Antwort 2]
C) [Antwort 3]
Richtig: [A/B/C]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Quiz konnte nicht erstellt werden.';
    } catch (e) {
      print('Gemini Quiz Error: $e');
      return 'Quiz nicht verfügbar.';
    }
  }

  void resetChat() {
    _chat = null;
  }
}

// Riverpod provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final service = GeminiService();

  // Listen to active profile changes
  final profile = ref.watch(activeProfileProvider);
  if (profile != null) {
    service.setProfile(profile);
  }

  return service;
});
