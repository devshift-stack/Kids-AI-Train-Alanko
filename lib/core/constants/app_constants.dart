class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'WonderBox';
  static const String appVersion = '1.0.0';

  // Age Groups
  static const int minAge = 3;
  static const int maxAge = 12;

  // API Keys (should be in .env in production)
  static const String elevenLabsApiKey = 'YOUR_ELEVENLABS_API_KEY';
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';

  // Alan Voice Settings
  static const String alanVoiceId = 'alan_custom_voice_id';
  static const double alanDefaultSpeechRate = 0.9;
  static const double alanDefaultPitch = 1.1;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Cache Settings
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100;

  // Supported Languages
  static const List<String> supportedLocales = [
    'bs', // Bosnian (default)
    'en', // English
    'hr', // Croatian
    'sr', // Serbian
    'de', // German
    'tr', // Turkish
  ];

  // Age Group Boundaries
  static const Map<String, List<int>> ageGroups = {
    'preschool': [3, 4, 5],
    'earlySchool': [6, 7, 8],
    'lateSchool': [9, 10, 11, 12],
  };
}
