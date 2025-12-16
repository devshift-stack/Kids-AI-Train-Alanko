# MODUL-AGENT REGELN (PFLICHT!)

**Letzte Aktualisierung:** 2025-12-16

---

## DU BIST EIN MODUL-AGENT

Du arbeitest an EINEM spezifischen Modul:
- **Lianko Agent** → Kids-AI-Train-Lianko
- **Alanko Agent** → Kids-AI-Train-Alanko
- **Parent Agent** → Kids-AI-Train-Parent

---

## 🚫 VERBOTEN

| Aktion | Warum |
|--------|-------|
| Push in Kids-AI-Shared | Nur Shared Agent darf das |
| Push in andere Module | Überschreibt Arbeit anderer Agents |
| Dateien in `kids_ai_shared` ändern | Nicht dein Repo |
| Direkt auf `main` pushen | Nur mit PR |

---

## ✅ ERLAUBT

| Aktion | Wie |
|--------|-----|
| Code in DEINEM Modul ändern | Normal arbeiten |
| Shared-Package IMPORTIEREN | `import 'package:kids_ai_shared/...'` |
| PR in DEINEM Repo erstellen | Nach User-Bestätigung |

---

## 🔄 WORKFLOW: Du brauchst etwas Gemeinsames

Wenn du etwas brauchst, das in **Shared** gehört (neuer Widget, neue Farbe, etc.):

### Schritt 1: NICHT selbst in Shared pushen!

### Schritt 2: Anfrage formulieren

Erstelle eine **SHARED_ANFRAGE.md** in deinem Repo:

```markdown
# SHARED ANFRAGE

**Von:** [Dein Modul-Name]
**Datum:** [Datum]

## Was wird benötigt?

[Beschreibung was du brauchst]

## Warum?

[Begründung]

## Vorgeschlagener Code

```dart
// Dein Vorschlag wie es aussehen könnte
```

## Betrifft andere Module?

- [ ] Alanko
- [ ] Lianko
- [ ] Parent
```

### Schritt 3: User informieren

Sage dem User:
```
Ich brauche etwas Gemeinsames für Shared.
Bitte gib diese Anfrage an den Shared Agent weiter:
[Link zu SHARED_ANFRAGE.md]
```

### Schritt 4: Warten

Der Shared Agent wird:
1. Anfrage prüfen
2. Sicherstellen dass nichts überschrieben wird
3. In Shared implementieren
4. User um Push-Erlaubnis fragen

### Schritt 5: Nach Shared-Update

Wenn Shared Agent fertig ist:
```bash
cd [dein-modul]
flutter pub get
```

Dann kannst du den neuen Code nutzen.

---

## 📋 VOR JEDEM PUSH

**PFLICHT-FRAGEN an User:**

1. "Soll ich pushen?"
2. "In welches Repo?" (Zur Bestätigung)

**Beispiel:**
```
Änderungen fertig.

Soll ich pushen?
→ Repo: Kids-AI-Train-Lianko
→ Branch: feature/neue-funktion
```

**Ohne User-Bestätigung = KEIN PUSH!**

---

## 📁 REPO-ZUORDNUNG

| Agent | Repo | GitHub URL |
|-------|------|------------|
| Shared Agent | Kids-AI-Shared | github.com/devshift-stack/Kids-AI-Shared |
| Alanko Agent | Kids-AI-Train-Alanko | github.com/devshift-stack/Kids-AI-Train-Alanko |
| Lianko Agent | Kids-AI-Train-Lianko | github.com/devshift-stack/Kids-AI-Train-Lianko |
| Parent Agent | Kids-AI-Train-Parent | github.com/devshift-stack/Kids-AI-Train-Parent |

---

## ⚠️ WENN DU UNSICHER BIST

**FRAGE den User!**

Lieber einmal zu viel fragen als:
- Falsches Repo überschreiben
- Arbeit anderer Agents zerstören
- Konflikte verursachen

---

## 🔍 PRÜFUNG VOR COMMIT

Vor jedem Commit prüfen:

```bash
git status
```

Checke:
- [ ] Nur Dateien in MEINEM Modul?
- [ ] Keine Shared-Dateien dabei?
- [ ] Kein anderes Modul betroffen?

Wenn unsicher → **STOPP und User fragen!**

---

**Regel merken: DEIN MODUL = DEIN REPO. Sonst nichts anfassen!**
