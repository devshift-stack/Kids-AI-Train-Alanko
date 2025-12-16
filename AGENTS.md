# AGENTS.md - Kids AI Train Projekt

**Letzte Aktualisierung:** 2025-12-16

---

## WICHTIG: LIES DIES KOMPLETT BEVOR DU ARBEITEST

---

## 1. Projekt-Übersicht

Kids AI Train ist ein Multi-Repo Projekt für Kinder-Lern-Apps mit KI-Sprachassistent.

### Repos auf GitHub (Organisation: devshift-stack)

| Repo | Beschreibung | GitHub URL |
|------|--------------|------------|
| **Kids-AI-Shared** | Gemeinsamer Code (Widgets, Services, Models) | https://github.com/devshift-stack/Kids-AI-Shared |
| **Kids-AI-Train-Alanko** | Alanko App (Kinder 3-12) | https://github.com/devshift-stack/Kids-AI-Train-Alanko |
| **Kids-AI-Train-Lianko** | Lianko App (Kinder 3-12) | https://github.com/devshift-stack/Kids-AI-Train-Lianko |
| **Kids-AI-Train-Parent** | Eltern-Dashboard | https://github.com/devshift-stack/Kids-AI-Train-Parent |

### Lokale Pfade

```
~/devshift-stack/
├── Kids-AI-Shared/         ← Gemeinsamer Code
├── Kids-AI-Train-Alanko/   ← Alanko App
├── Kids-AI-Train-Lianko/   ← Lianko App
└── Kids-AI-Train-Parent/   ← Eltern-Dashboard
```

---

## 2. GOLDENE REGEL: NUR MIT PULL REQUESTS ARBEITEN

**NIEMALS direkt auf `main` pushen!**

Immer:
1. Neuen Branch erstellen
2. Änderungen committen
3. Pull Request erstellen
4. Review abwarten
5. Erst nach Approval wird gemerged

---

## 3. Workflow für jeden Task

### Schritt 1: Repo klonen (falls nicht vorhanden)

```bash
# Für Shared
cd ~/devshift-stack
gh repo clone devshift-stack/Kids-AI-Shared

# Für Alanko
gh repo clone devshift-stack/Kids-AI-Train-Alanko

# Für Lianko
gh repo clone devshift-stack/Kids-AI-Train-Lianko

# Für Parent
gh repo clone devshift-stack/Kids-AI-Train-Parent
```

### Schritt 2: Aktuellen Stand holen

```bash
cd ~/devshift-stack/[REPO-NAME]
git checkout main
git pull origin main
```

### Schritt 3: Neuen Branch erstellen

**Branch-Naming-Convention:**
- `feature/beschreibung` - Neue Features
- `fix/beschreibung` - Bug Fixes
- `refactor/beschreibung` - Code Refactoring
- `docs/beschreibung` - Dokumentation

```bash
git checkout -b feature/mein-neues-feature
```

### Schritt 4: Änderungen machen und committen

```bash
# Änderungen machen...

git add -A
git commit -m "feat: Beschreibung der Änderung"
```

**Commit-Message-Format:**
- `feat:` - Neues Feature
- `fix:` - Bug Fix
- `refactor:` - Code Refactoring
- `docs:` - Dokumentation
- `style:` - Formatting, keine Code-Änderung
- `test:` - Tests hinzufügen

### Schritt 5: Branch pushen

```bash
git push -u origin feature/mein-neues-feature
```

### Schritt 6: Pull Request erstellen

```bash
gh pr create --title "feat: Mein neues Feature" --body "## Summary
- Was wurde gemacht

## Test plan
- [ ] Getestet auf iOS
- [ ] Getestet auf Android"
```

---

## 4. Welches Repo für welche Änderung?

### Kids-AI-Shared (Gemeinsamer Code)

**Hier ändern wenn:**
- Widgets die in ALLEN Apps genutzt werden
- Services die in ALLEN Apps genutzt werden
- Models die in ALLEN Apps genutzt werden
- Utility-Funktionen für ALLE Apps

**Struktur:**
```
Kids-AI-Shared/
├── lib/
│   ├── kids_ai_shared.dart    ← Haupt-Export
│   └── src/
│       ├── widgets/           ← Gemeinsame Widgets
│       ├── services/          ← Gemeinsame Services
│       ├── models/            ← Gemeinsame Models
│       └── utils/             ← Utility-Funktionen
└── pubspec.yaml
```

**Nach Push in Shared:**
Alle Apps müssen `flutter pub get` ausführen um die Änderungen zu holen!

---

### Kids-AI-Train-Alanko (Alanko App)

**Hier ändern wenn:**
- Features NUR für Alanko
- Alanko-spezifische UI
- Alanko-spezifische Logik
- Alanko Assets (Bilder, Sounds, Übersetzungen)

**Struktur:**
```
Kids-AI-Train-Alanko/
├── lib/
│   ├── main.dart
│   ├── screens/               ← Alanko Screens
│   ├── widgets/               ← Alanko-spezifische Widgets
│   └── services/              ← Alanko-spezifische Services
├── assets/
│   └── locales/               ← Übersetzungen
└── pubspec.yaml
```

---

### Kids-AI-Train-Lianko (Lianko App)

**Hier ändern wenn:**
- Features NUR für Lianko
- Lianko-spezifische UI
- Lianko-spezifische Logik
- Lianko Assets (Bilder, Sounds, Übersetzungen)

**Struktur:**
```
Kids-AI-Train-Lianko/
├── lib/
│   ├── main.dart
│   ├── screens/               ← Lianko Screens
│   ├── widgets/               ← Lianko-spezifische Widgets
│   └── services/              ← Lianko-spezifische Services
├── assets/
│   └── locales/               ← Übersetzungen
└── pubspec.yaml
```

---

### Kids-AI-Train-Parent (Eltern-Dashboard)

**Hier ändern wenn:**
- Features für Eltern-Dashboard
- Statistiken und Reports
- Kinderprofil-Verwaltung
- Parent-spezifische UI

**Struktur:**
```
Kids-AI-Train-Parent/
├── lib/
│   ├── main.dart
│   ├── screens/               ← Dashboard Screens
│   ├── widgets/               ← Dashboard Widgets
│   └── services/              ← Dashboard Services
├── assets/
│   └── locales/               ← Übersetzungen
└── pubspec.yaml
```

---

## 5. Vollständiges Beispiel: Feature für Lianko

```bash
# 1. Ins Repo wechseln
cd ~/devshift-stack/Kids-AI-Train-Lianko

# 2. Main aktualisieren
git checkout main
git pull origin main

# 3. Neuen Branch erstellen
git checkout -b feature/neuer-lernspiel-screen

# 4. Änderungen machen
# ... Code schreiben ...

# 5. Committen
git add -A
git commit -m "feat: Add new learning game screen for numbers"

# 6. Branch pushen
git push -u origin feature/neuer-lernspiel-screen

# 7. Pull Request erstellen
gh pr create --title "feat: Add new learning game screen for numbers" --body "$(cat <<'EOF'
## Summary
- Added new numbers learning game screen
- Includes voice feedback
- Age-adaptive difficulty

## Test plan
- [ ] Tested on iOS Simulator
- [ ] Tested on Android Emulator
- [ ] Voice feedback works
EOF
)"
```

**Output:** PR URL wird angezeigt

---

## 6. Vollständiges Beispiel: Gemeinsames Widget in Shared

```bash
# 1. Ins Shared Repo wechseln
cd ~/devshift-stack/Kids-AI-Shared

# 2. Main aktualisieren
git checkout main
git pull origin main

# 3. Neuen Branch erstellen
git checkout -b feature/animated-button-widget

# 4. Widget erstellen
mkdir -p lib/src/widgets
cat > lib/src/widgets/animated_button.dart << 'EOF'
import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
EOF

# 5. Export hinzufügen
echo "export 'src/widgets/animated_button.dart';" >> lib/kids_ai_shared.dart

# 6. Committen
git add -A
git commit -m "feat: Add AnimatedButton widget"

# 7. Branch pushen
git push -u origin feature/animated-button-widget

# 8. Pull Request erstellen
gh pr create --title "feat: Add AnimatedButton widget" --body "$(cat <<'EOF'
## Summary
- Added reusable AnimatedButton widget
- Can be used in all Kids AI apps

## Usage
```dart
import 'package:kids_ai_shared/kids_ai_shared.dart';

AnimatedButton(
  text: 'Click me',
  onPressed: () {},
)
```

## Test plan
- [ ] Widget renders correctly
- [ ] OnPressed callback works
EOF
)"
```

**WICHTIG: Nach Merge in Shared müssen alle Apps aktualisiert werden:**

```bash
# In Alanko
cd ~/devshift-stack/Kids-AI-Train-Alanko
flutter pub get

# In Lianko
cd ~/devshift-stack/Kids-AI-Train-Lianko
flutter pub get

# In Parent
cd ~/devshift-stack/Kids-AI-Train-Parent
flutter pub get
```

---

## 7. Entscheidungshilfe: Wo gehört mein Code hin?

```
Frage: Wird dieser Code in mehr als einer App genutzt?
│
├─► JA → Kids-AI-Shared
│
└─► NEIN → Welche App?
    │
    ├─► Alanko App → Kids-AI-Train-Alanko
    ├─► Lianko App → Kids-AI-Train-Lianko
    └─► Eltern-Dashboard → Kids-AI-Train-Parent
```

---

## 8. Verbotene Aktionen

❌ **NIEMALS:**
- Direkt auf `main` pushen
- `git push --force` auf main
- Secrets/API-Keys committen
- .env Dateien committen
- node_modules oder build-Ordner committen

✅ **IMMER:**
- Neuen Branch erstellen
- Pull Request erstellen
- Aussagekräftige Commit-Messages
- Code vor Push testen

---

## 9. Shared Code importieren

In jeder App (Alanko, Lianko, Parent):

```dart
import 'package:kids_ai_shared/kids_ai_shared.dart';

// Dann nutzen:
AnimatedButton(text: 'Klick', onPressed: () {});
```

Die Dependency ist bereits in pubspec.yaml:

```yaml
dependencies:
  kids_ai_shared:
    git:
      url: https://github.com/devshift-stack/Kids-AI-Shared.git
```

---

## 10. Kontakt

Bei Fragen: Pull Request mit Frage erstellen oder Issue auf GitHub.

**Owner:** devshift-stack (dsactivi)
