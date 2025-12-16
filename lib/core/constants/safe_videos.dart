/// Curated list of child-safe YouTube videos
/// These videos are pre-approved for children ages 3-12
class SafeVideos {
  SafeVideos._();

  /// German children's songs and learning videos
  static const List<Map<String, String>> german = [
    {'id': 'hj0rYB3Xbvw', 'title': 'Das Lied der Farben', 'category': 'learning'},
    {'id': 'jEQHPbwBqxs', 'title': 'Zahlen lernen 1-10', 'category': 'learning'},
    {'id': '4WpwWiv-zQI', 'title': 'ABC Lied Deutsch', 'category': 'learning'},
    {'id': 'CWwvGbKxJao', 'title': 'Kinderlieder Mix', 'category': 'music'},
    {'id': '0wSllz_hmzs', 'title': 'Die Räder vom Bus', 'category': 'music'},
    {'id': 'tbbKjDjMDok', 'title': 'Kopf Schulter Knie und Fuß', 'category': 'music'},
  ];

  /// Bosnian/Croatian/Serbian children's content
  static const List<Map<String, String>> bosnian = [
    {'id': 'gKgG9xQQ7hc', 'title': 'Učimo boje', 'category': 'learning'},
    {'id': 'NQ_yx9jLlCc', 'title': 'Brojevi 1-10', 'category': 'learning'},
    {'id': 'q1YXc3pLvGs', 'title': 'Dječije pjesme', 'category': 'music'},
  ];

  /// English children's learning videos
  static const List<Map<String, String>> english = [
    {'id': 'hq3yfQnllfQ', 'title': 'Phonics Song', 'category': 'learning'},
    {'id': '75p-N9YKqNo', 'title': 'Counting 1-20', 'category': 'learning'},
    {'id': '_UR-l3QI2nE', 'title': 'Colors Song', 'category': 'learning'},
    {'id': 'e0dJWfQHF8Y', 'title': 'Baby Shark', 'category': 'music'},
    {'id': 'CD5lQLkcKMQ', 'title': 'Wheels on the Bus', 'category': 'music'},
    {'id': 'kE7jBzKJdvY', 'title': 'Head Shoulders Knees', 'category': 'music'},
  ];

  /// Turkish children's content
  static const List<Map<String, String>> turkish = [
    {'id': 'NZIMg1BN6bM', 'title': 'Renkleri Öğreniyorum', 'category': 'learning'},
    {'id': 'TSwqnR327fk', 'title': 'Sayılar 1-10', 'category': 'learning'},
    {'id': 'pW4BaLunqpo', 'title': 'Çocuk Şarkıları', 'category': 'music'},
  ];

  /// Get videos by language code
  static List<Map<String, String>> getByLanguage(String languageCode) {
    switch (languageCode) {
      case 'de':
        return german;
      case 'bs':
      case 'hr':
      case 'sr':
        return bosnian;
      case 'tr':
        return turkish;
      case 'en':
      default:
        return english;
    }
  }

  /// Get all videos for all languages (mixed)
  static List<Map<String, String>> get all {
    return [...german, ...bosnian, ...english, ...turkish];
  }

  /// Get videos by category
  static List<Map<String, String>> getByCategory(String category, String languageCode) {
    return getByLanguage(languageCode)
        .where((v) => v['category'] == category)
        .toList();
  }

  /// Categories available
  static const List<String> categories = ['learning', 'music'];
}
