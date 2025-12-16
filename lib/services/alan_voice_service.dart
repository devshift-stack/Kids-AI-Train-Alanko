import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AlanMood { happy, curious, excited, calm, encouraging }

enum AlanSpeechState { idle, speaking, listening, thinking }

class AlanVoiceService {
  final FlutterTts _tts = FlutterTts();
  int _currentAge = 6;
  String _currentLanguage = 'bs-BA';
  AlanSpeechState _state = AlanSpeechState.idle;
  String? _selectedVoice;

  final _stateController = StreamController<AlanSpeechState>.broadcast();
  Stream<AlanSpeechState> get stateStream => _stateController.stream;
  AlanSpeechState get currentState => _state;

  // Preferred voices for Alanko - friendly, young-sounding voices
  static const _preferredVoices = {
    'en': ['Samantha', 'Karen', 'Moira', 'Tessa', 'Fiona'],
    'de': ['Anna', 'Helena', 'Petra', 'Yannick'],
    'hr': ['Lana'],
    'sr': ['Milena'],
    'tr': ['Yelda', 'Cem'],
    'bs': ['Lana', 'Milena'], // Fallback to Croatian/Serbian
  };

  AlanVoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Get available voices and select best one for Alan
    await _selectBestVoice();

    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(_getSpeechRateForAge());
    await _tts.setPitch(_getPitchForAge());
    await _tts.setVolume(1.0);

    // Android-specific settings for better quality
    if (Platform.isAndroid) {
      // Use Google TTS engine for better quality
      await _tts.setEngine('com.google.android.tts');
      // Slower, more natural speech
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.05);
    }

    // iOS-specific settings for better quality
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }

    _tts.setStartHandler(() {
      _updateState(AlanSpeechState.speaking);
    });

    _tts.setCompletionHandler(() {
      _updateState(AlanSpeechState.idle);
    });

    _tts.setErrorHandler((msg) {
      _updateState(AlanSpeechState.idle);
    });
  }

  Future<void> _selectBestVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || voices.isEmpty) return;

      final langCode = _currentLanguage.split('-').first;
      final preferred = _preferredVoices[langCode] ?? [];

      // Find a preferred voice that's available
      for (final voiceName in preferred) {
        for (final voice in voices) {
          final name = voice['name']?.toString() ?? '';
          if (name.toLowerCase().contains(voiceName.toLowerCase())) {
            _selectedVoice = name;
            await _tts.setVoice({'name': name, 'locale': _currentLanguage});
            return;
          }
        }
      }

      // Fallback: find any voice for this language
      for (final voice in voices) {
        final locale = voice['locale']?.toString() ?? '';
        if (locale.startsWith(langCode)) {
          _selectedVoice = voice['name']?.toString();
          if (_selectedVoice != null) {
            await _tts.setVoice({'name': _selectedVoice!, 'locale': locale});
            return;
          }
        }
      }
    } catch (e) {
      // Fallback to default voice
    }
  }

  void _updateState(AlanSpeechState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  double _getSpeechRateForAge() {
    // Slower speech for younger children
    if (_currentAge <= 5) return 0.4;
    if (_currentAge <= 8) return 0.5;
    return 0.55;
  }

  double _getPitchForAge() {
    // Higher, friendlier pitch for younger children
    if (_currentAge <= 5) return 1.2;
    if (_currentAge <= 8) return 1.1;
    return 1.0;
  }

  Future<void> setAge(int age) async {
    _currentAge = age;
    await _tts.setSpeechRate(_getSpeechRateForAge());
    await _tts.setPitch(_getPitchForAge());
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = _getLocaleFromCode(languageCode);
    await _tts.setLanguage(_currentLanguage);
    await _selectBestVoice(); // Re-select voice for new language
  }

  String _getLocaleFromCode(String code) {
    switch (code) {
      case 'bs':
        return 'bs-BA';
      case 'en':
        return 'en-US';
      case 'hr':
        return 'hr-HR';
      case 'sr':
        return 'sr-RS';
      case 'de':
        return 'de-DE';
      case 'tr':
        return 'tr-TR';
      default:
        return 'bs-BA';
    }
  }

  Future<void> speak(String text, {AlanMood mood = AlanMood.happy}) async {
    if (_state == AlanSpeechState.speaking) {
      await stop();
    }

    // Adjust voice based on mood
    await _applyMoodSettings(mood);

    _updateState(AlanSpeechState.speaking);
    await _tts.speak(text);
  }

  Future<void> _applyMoodSettings(AlanMood mood) async {
    double pitchModifier = 0;
    double rateModifier = 0;

    switch (mood) {
      case AlanMood.happy:
        pitchModifier = 0.1;
        rateModifier = 0.05;
        break;
      case AlanMood.curious:
        pitchModifier = 0.15;
        rateModifier = -0.05;
        break;
      case AlanMood.excited:
        pitchModifier = 0.2;
        rateModifier = 0.1;
        break;
      case AlanMood.calm:
        pitchModifier = -0.1;
        rateModifier = -0.1;
        break;
      case AlanMood.encouraging:
        pitchModifier = 0.05;
        rateModifier = -0.05;
        break;
    }

    await _tts.setPitch(_getPitchForAge() + pitchModifier);
    await _tts.setSpeechRate(_getSpeechRateForAge() + rateModifier);
  }

  Future<void> stop() async {
    await _tts.stop();
    _updateState(AlanSpeechState.idle);
  }

  Future<void> pause() async {
    await _tts.pause();
    _updateState(AlanSpeechState.idle);
  }

  // Greeting based on time of day and age
  String getGreeting(String childName) {
    final hour = DateTime.now().hour;
    String timeGreeting;

    if (hour < 12) {
      timeGreeting = _getAgeAppropriateText('goodMorning');
    } else if (hour < 18) {
      timeGreeting = _getAgeAppropriateText('goodAfternoon');
    } else {
      timeGreeting = _getAgeAppropriateText('goodEvening');
    }

    return '$timeGreeting, $childName! ${_getAgeAppropriateText('welcomeBack')}';
  }

  String _getAgeAppropriateText(String key) {
    // Text complexity based on age
    final texts = {
      'goodMorning': {
        'preschool': 'Dobro jutro',
        'earlySchool': 'Dobro jutro',
        'lateSchool': 'Dobro jutro',
      },
      'goodAfternoon': {
        'preschool': 'Ćao',
        'earlySchool': 'Dobar dan',
        'lateSchool': 'Dobar dan',
      },
      'goodEvening': {
        'preschool': 'Laku noć uskoro',
        'earlySchool': 'Dobra večer',
        'lateSchool': 'Dobra večer',
      },
      'welcomeBack': {
        'preschool': 'Hajde da se igramo!',
        'earlySchool': 'Spremni za učenje?',
        'lateSchool': 'Šta želiš danas naučiti?',
      },
    };

    String ageGroup;
    if (_currentAge <= 5) {
      ageGroup = 'preschool';
    } else if (_currentAge <= 8) {
      ageGroup = 'earlySchool';
    } else {
      ageGroup = 'lateSchool';
    }

    return texts[key]?[ageGroup] ?? texts[key]?['earlySchool'] ?? '';
  }

  // Fun phrases for Alan's personality
  static const _alanPhrases = {
    'bs': {
      'correct': ['Bravo!', 'Super!', 'Odlično!', 'Tako je!', 'Fantastično!'],
      'wrong': ['Hajde probaj opet!', 'Skoro!', 'Ne brini, pokušaj ponovo!'],
      'encourage': ['Ti to možeš!', 'Samo nastavi!', 'Vjerujem u tebe!'],
      'hello': ['Zdravo prijatelju!', 'Ćao!', 'Hej, drago mi je što si tu!'],
      'bye': ['Doviđenja!', 'Vidimo se!', 'Bilo je super, ćao!'],
      'thinking': ['Hmm, razmišljam...', 'Daj da vidim...', 'Zanimljivo...'],
    },
    'en': {
      'correct': ['Great job!', 'Awesome!', 'You got it!', 'Perfect!', 'Amazing!'],
      'wrong': ['Try again!', 'Almost!', 'Don\'t worry, try once more!'],
      'encourage': ['You can do it!', 'Keep going!', 'I believe in you!'],
      'hello': ['Hello friend!', 'Hi there!', 'Hey, I\'m glad you\'re here!'],
      'bye': ['Goodbye!', 'See you soon!', 'That was fun, bye!'],
      'thinking': ['Hmm, let me think...', 'Let me see...', 'Interesting...'],
    },
    'de': {
      'correct': ['Super!', 'Toll!', 'Ausgezeichnet!', 'Richtig!', 'Fantastisch!'],
      'wrong': ['Versuch es nochmal!', 'Fast!', 'Keine Sorge, probier es nochmal!'],
      'encourage': ['Du schaffst das!', 'Weiter so!', 'Ich glaube an dich!'],
      'hello': ['Hallo Freund!', 'Hi!', 'Hey, schön dass du da bist!'],
      'bye': ['Tschüss!', 'Bis bald!', 'Das hat Spaß gemacht, tschüss!'],
      'thinking': ['Hmm, lass mich nachdenken...', 'Mal sehen...', 'Interessant...'],
    },
    'hr': {
      'correct': ['Bravo!', 'Super!', 'Odlično!', 'Tako je!', 'Fantastično!'],
      'wrong': ['Pokušaj opet!', 'Skoro!', 'Ne brini, probaj ponovno!'],
      'encourage': ['Možeš ti to!', 'Samo nastavi!', 'Vjerujem u tebe!'],
      'hello': ['Bok prijatelju!', 'Ćao!', 'Hej, drago mi je što si tu!'],
      'bye': ['Doviđenja!', 'Vidimo se!', 'Bilo je super, bok!'],
      'thinking': ['Hmm, razmišljam...', 'Da vidim...', 'Zanimljivo...'],
    },
    'sr': {
      'correct': ['Браво!', 'Супер!', 'Одлично!', 'Тако је!', 'Фантастично!'],
      'wrong': ['Пробај поново!', 'Скоро!', 'Не брини, покушај опет!'],
      'encourage': ['Можеш ти то!', 'Само настави!', 'Верујем у тебе!'],
      'hello': ['Здраво пријатељу!', 'Ћао!', 'Хеј, драго ми је што си ту!'],
      'bye': ['Довиђења!', 'Видимо се!', 'Било је супер, ћао!'],
      'thinking': ['Хмм, размишљам...', 'Да видим...', 'Занимљиво...'],
    },
    'tr': {
      'correct': ['Aferin!', 'Süper!', 'Mükemmel!', 'Doğru!', 'Harika!'],
      'wrong': ['Tekrar dene!', 'Neredeyse!', 'Endişelenme, bir daha dene!'],
      'encourage': ['Yapabilirsin!', 'Devam et!', 'Sana inanıyorum!'],
      'hello': ['Merhaba arkadaşım!', 'Selam!', 'Hey, burada olduğuna sevindim!'],
      'bye': ['Hoşça kal!', 'Görüşürüz!', 'Çok eğlenceliydi, bay bay!'],
      'thinking': ['Hmm, düşüneyim...', 'Bakalım...', 'İlginç...'],
    },
  };

  /// Get a random phrase for the given type
  String getPhrase(String type) {
    final langCode = _currentLanguage.split('-').first;
    final phrases = _alanPhrases[langCode]?[type] ??
                   _alanPhrases['bs']?[type] ??
                   [''];
    if (phrases.isEmpty) return '';
    return phrases[(DateTime.now().millisecond % phrases.length)];
  }

  /// Speak a reaction phrase with appropriate mood
  Future<void> react(String type) async {
    final phrase = getPhrase(type);
    if (phrase.isEmpty) return;

    AlanMood mood;
    switch (type) {
      case 'correct':
        mood = AlanMood.excited;
        break;
      case 'wrong':
        mood = AlanMood.encouraging;
        break;
      case 'encourage':
        mood = AlanMood.encouraging;
        break;
      case 'hello':
        mood = AlanMood.happy;
        break;
      case 'bye':
        mood = AlanMood.calm;
        break;
      case 'thinking':
        mood = AlanMood.curious;
        break;
      default:
        mood = AlanMood.happy;
    }

    await speak(phrase, mood: mood);
  }

  void dispose() {
    _stateController.close();
    _tts.stop();
  }
}

// Riverpod providers
final alanVoiceServiceProvider = Provider<AlanVoiceService>((ref) {
  final service = AlanVoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final alanSpeechStateProvider = StreamProvider<AlanSpeechState>((ref) {
  final service = ref.watch(alanVoiceServiceProvider);
  return service.stateStream;
});
