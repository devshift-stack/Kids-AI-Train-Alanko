# Test Prompts für Kids-AI-Train-Alanko

Generiert vom Lianko-Agent für konsistente Unit Tests über alle Repos.

---

## 1. Models

### 1.1 ChildProfile

**Datei:** `lib/models/child_profile.dart`
**Speichern in:** `test/models/child_profile_test.dart`
**Beschreibung:** Kinderprofil mit Namen, Alter, Sprache und Lernfortschritt

#### Klassen zu testen:
1. `ChildProfile`
   - `fromJson()` - Parsed JSON zu ChildProfile
   - `toJson()` - Konvertiert zu JSON
   - `copyWith()` - Erstellt Kopie mit Änderungen
   - `props` - Equatable Vergleich

#### Zu testende Szenarien:
- [ ] fromJson parsed alle Felder korrekt
- [ ] fromJson mit fehlenden optionalen Feldern gibt Defaults
- [ ] toJson/fromJson Roundtrip funktioniert
- [ ] copyWith ändert nur angegebene Felder
- [ ] Zwei ChildProfiles mit gleichen Daten sind equal

#### Edge Cases:
- Leerer Name
- Alter = 0
- Leere topicProgress Map
- Null lastActiveAt

#### Beispiel-Test:
```dart
test('fromJson parsed alle Felder korrekt', () {
  final json = {
    'id': 'test-id',
    'name': 'Max',
    'age': 6,
    'preferredLanguage': 'de',
    'createdAt': '2024-01-01T00:00:00.000Z',
    'topicProgress': {'math': 50},
  };
  final profile = ChildProfile.fromJson(json);
  expect(profile.id, equals('test-id'));
  expect(profile.name, equals('Max'));
  expect(profile.age, equals(6));
});
```

#### Abhängigkeiten: Keine

---

### 1.2 GameItem & GameResult

**Datei:** `lib/models/games/game_item.dart`
**Speichern in:** `test/models/games/game_item_test.dart`
**Beschreibung:** Spiel-Items für Lernspiele und Ergebnisse

#### Klassen zu testen:
1. `GameResult`
   - `accuracy` - Berechnet Genauigkeit in Prozent
   - `isPerfect` - Prüft ob alle Antworten korrekt

2. `NumbersData`
   - `getNumbers()` - Generiert Zahlen-Items bis max

3. `ColorsData`
   - `getColors()` - Gibt Farben für Sprache zurück

#### Zu testende Szenarien:
- [ ] accuracy berechnet korrekt (z.B. 8/10 = 80%)
- [ ] accuracy gibt 0 bei 0 Fragen zurück
- [ ] isPerfect ist true wenn alle korrekt
- [ ] getNumbers(10) gibt 11 Items zurück (0-10)
- [ ] getColors('bs') gibt bosnische Farben
- [ ] getColors mit unbekannter Sprache gibt Default

#### Edge Cases:
- totalQuestions = 0
- correctAnswers > totalQuestions
- getNumbers(0)
- getColors mit ungültiger Sprache

#### Beispiel-Test:
```dart
test('accuracy berechnet korrekt', () {
  final result = GameResult(
    totalQuestions: 10,
    correctAnswers: 8,
    timeTaken: Duration(seconds: 60),
    completedAt: DateTime.now(),
  );
  expect(result.accuracy, equals(80.0));
});
```

#### Abhängigkeiten: Keine

---

### 1.3 LearningContent

**Datei:** `lib/models/learning_content.dart`
**Speichern in:** `test/models/learning_content_test.dart`
**Beschreibung:** Lerninhalte mit Typ, Schwierigkeit und XP

#### Klassen zu testen:
1. `LearningContent`
   - `fromJson()` - Parsed JSON
   - `toJson()` - Konvertiert zu JSON
   - `isAvailableFor()` - Prüft Verfügbarkeit für Altersgruppe

2. `QuizQuestion`
   - `fromJson()` / `toJson()`
   - `isCorrect()` - Prüft ob Antwort korrekt

#### Zu testende Szenarien:
- [ ] fromJson parsed ContentType korrekt
- [ ] isAvailableFor gibt true für passende Altersgruppe
- [ ] isAvailableFor gibt false für nicht-passende Altersgruppe
- [ ] QuizQuestion.isCorrect prüft korrekt

#### Edge Cases:
- ContentType als String vs Enum
- Leere prerequisites Liste
- estimatedDuration = 0

#### Beispiel-Test:
```dart
test('isCorrect prüft Antwort korrekt', () {
  final question = QuizQuestion(
    id: 'q1',
    question: 'Was ist 2+2?',
    options: ['3', '4', '5'],
    correctIndex: 1,
  );
  expect(question.isCorrect(1), isTrue);
  expect(question.isCorrect(0), isFalse);
});
```

#### Abhängigkeiten: Keine

---

## 2. Services

### 2.1 AdaptiveLearningService

**Datei:** `lib/services/adaptive_learning_service.dart`
**Speichern in:** `test/services/adaptive_learning_service_test.dart`
**Beschreibung:** Passt Schwierigkeit basierend auf Performance an

#### Klassen zu testen:
1. `ExerciseResult`
   - `toJson()` / `fromJson()`

2. `GamePerformance`
   - `getRecentAccuracy()` - Berechnet Genauigkeit der letzten N Übungen
   - `getAverageResponseTime()` - Berechnet Durchschnittszeit

3. `AdaptiveLearningService`
   - `getDifficulty()` - Gibt aktuelle Schwierigkeit zurück
   - `getNextQuestionDelay()` - Berechnet Wartezeit
   - `getGameParameters()` - Gibt spielspezifische Parameter zurück

#### Zu testende Szenarien:
- [ ] getRecentAccuracy mit weniger Ergebnissen als count
- [ ] getRecentAccuracy berechnet korrekt
- [ ] getAverageResponseTime mit leerer Liste gibt Default
- [ ] Schwierigkeit erhöht sich bei >70% Genauigkeit
- [ ] Schwierigkeit sinkt bei <50% Genauigkeit
- [ ] getGameParameters gibt korrekte Parameter pro GameType

#### Edge Cases:
- Leere results Liste
- Mehr als 100 Ergebnisse (Truncation)
- Alle Antworten falsch
- Alle Antworten richtig

#### Beispiel-Test:
```dart
test('getRecentAccuracy berechnet korrekt', () {
  final performance = GamePerformance(gameType: GameType.letters);
  performance.results.addAll([
    ExerciseResult(timestamp: DateTime.now(), correct: true, responseTimeMs: 1000, difficultyLevel: 1.0),
    ExerciseResult(timestamp: DateTime.now(), correct: false, responseTimeMs: 2000, difficultyLevel: 1.0),
  ]);
  expect(performance.getRecentAccuracy(10), equals(0.5));
});
```

#### Abhängigkeiten:
- Mock für SharedPreferences
- Mock für Ref (Riverpod)

---

### 2.2 AgeAdaptiveService

**Datei:** `lib/services/age_adaptive_service.dart`
**Speichern in:** `test/services/age_adaptive_service_test.dart`
**Beschreibung:** Passt UI und Inhalte ans Alter an

#### Klassen zu testen:
1. `AgeAdaptiveSettings`
   - `forAge()` - Erstellt Settings basierend auf Alter

2. `AgeAdaptiveService`
   - `adaptText()` - Vereinfacht Text für jüngere Kinder
   - `adaptChoices()` - Begrenzt Auswahlmöglichkeiten
   - `getAdaptedFontSize()` - Berechnet angepasste Schriftgröße
   - `getTopicsForAgeGroup()` - Gibt altersgerechte Themen
   - `getDifficultyLevel()` - Gibt Schwierigkeitsstufe

#### Zu testende Szenarien:
- [ ] forAge(3) gibt preschool Settings
- [ ] forAge(7) gibt earlySchool Settings
- [ ] forAge(10) gibt lateSchool Settings
- [ ] adaptChoices begrenzt auf maxChoicesPerQuestion
- [ ] getAdaptedFontSize erhöht für preschool
- [ ] getTopicsForAgeGroup gibt passende Themen

#### Edge Cases:
- Alter = 0
- Alter > 12
- Leere choices Liste

#### Beispiel-Test:
```dart
test('forAge(3) gibt preschool Settings', () {
  final settings = AgeAdaptiveSettings.forAge(3);
  expect(settings.ageGroup, equals(AgeGroup.preschool));
  expect(settings.fontSize, equals(24.0));
  expect(settings.maxChoicesPerQuestion, equals(2));
});
```

#### Abhängigkeiten:
- Mock für SharedPreferences

---

### 2.3 BadgeService

**Datei:** `lib/services/badge_service.dart`
**Speichern in:** `test/services/badge_service_test.dart`
**Beschreibung:** Verwaltet Achievements und Badges

#### Klassen zu testen:
1. `Badge`
   - Statische all Map enthält alle Badges

2. `EarnedBadge`
   - `toJson()` / `fromJson()`

3. `BadgeProgress`
   - `getProgress()` - Gibt Fortschritt für Badge-Typ
   - `toJson()` / `fromJson()`

4. `BadgeState`
   - `hasBadge()` - Prüft ob Badge verdient

5. `BadgeNotifier`
   - `recordLessonCompleted()` - Trackt Lektion
   - `recordDailyActivity()` - Trackt tägliche Aktivität

#### Zu testende Szenarien:
- [ ] Badge.all enthält alle BadgeTypes
- [ ] EarnedBadge Roundtrip funktioniert
- [ ] hasBadge gibt true wenn verdient
- [ ] recordLessonCompleted erhöht Progress
- [ ] perfectScore Badge bei 100% Genauigkeit
- [ ] Streak Badges bei aufeinanderfolgenden Tagen

#### Edge Cases:
- Badge bereits verdient
- Secret Badge nicht sichtbar bis verdient
- Progress = 0

#### Beispiel-Test:
```dart
test('hasBadge gibt true wenn Badge verdient', () {
  final state = BadgeState(
    earnedBadges: [EarnedBadge(type: BadgeType.firstLesson, earnedAt: DateTime.now())],
  );
  expect(state.hasBadge(BadgeType.firstLesson), isTrue);
  expect(state.hasBadge(BadgeType.tenLessons), isFalse);
});
```

#### Abhängigkeiten:
- Mock für SharedPreferences

---

### 2.4 YouTubeRewardService

**Datei:** `lib/services/youtube_reward_service.dart`
**Speichern in:** `test/services/youtube_reward_service_test.dart`
**Beschreibung:** Verwaltet YouTube-Belohnungssystem

#### Klassen zu testen:
1. `YouTubeRewardService`
   - `canWatch` - Prüft ob Kind schauen darf
   - `completeTask()` - Task abgeschlossen
   - `remainingMinutes` - Verbleibende Zeit
   - `minutesUntilPause` - Zeit bis zur Pause
   - `shouldShowYouTube` - Feature aktiviert?

#### Zu testende Szenarien:
- [ ] canWatch ist false wenn Tageslimit erreicht
- [ ] canWatch ist false wenn Tasks nötig
- [ ] completeTask setzt Session zurück nach genug Tasks
- [ ] remainingMinutes berechnet korrekt
- [ ] shouldShowYouTube respektiert isEnabled

#### Edge Cases:
- dailyLimitMinutes = 0 (unbegrenzt)
- Neuer Tag resettet watchedMinutesToday
- tasksRequired = 0

#### Beispiel-Test:
```dart
test('remainingMinutes berechnet korrekt', () {
  // Setup: 30 min Limit, 10 min geschaut
  // Expect: 20 min verbleibend
});
```

#### Abhängigkeiten:
- Mock für FirebaseFirestore
- Mock für SharedPreferences

---

### 2.5 GeminiService

**Datei:** `lib/services/gemini_service.dart`
**Speichern in:** `test/services/gemini_service_test.dart`
**Beschreibung:** AI-Chat mit Gemini API

#### Klassen zu testen:
1. `GeminiService`
   - `ask()` - Stellt Frage an Gemini
   - `generateStory()` - Generiert Geschichte
   - `generateQuiz()` - Generiert Quiz
   - `setProfile()` - Setzt Profil
   - `resetChat()` - Reset Chat Session

#### Zu testende Szenarien:
- [ ] ask gibt Fallback bei fehlendem API Key
- [ ] ask gibt Fallback bei Quota-Error
- [ ] setProfile initialisiert Model neu
- [ ] resetChat setzt _chat auf null

#### Edge Cases:
- API Key nicht gesetzt
- Netzwerkfehler
- Quota erschöpft

#### Abhängigkeiten:
- Mock für GenerativeModel (google_generative_ai)

---

## 3. Providers

### 3.1 SharedPreferencesProvider

**Datei:** `lib/services/age_adaptive_service.dart`
**Speichern in:** `test/providers/shared_preferences_provider_test.dart`
**Beschreibung:** Provider für SharedPreferences

#### Zu testende Szenarien:
- [ ] Provider wirft UnimplementedError wenn nicht override
- [ ] Provider funktioniert mit Override

---

## Zusammenfassung

| Modul | Priorität | Komplexität |
|-------|-----------|-------------|
| ChildProfile | Hoch | Niedrig |
| GameItem/GameResult | Hoch | Niedrig |
| AdaptiveLearningService | Hoch | Mittel |
| AgeAdaptiveService | Hoch | Niedrig |
| BadgeService | Mittel | Mittel |
| YouTubeRewardService | Mittel | Mittel |
| GeminiService | Niedrig | Hoch (ext. API) |
