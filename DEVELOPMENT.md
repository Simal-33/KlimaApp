# Entwicklung

Kurze Checkliste, um die App lokal zu pruefen und fuer GitHub vorzubereiten.

## Setup

```bash
flutter pub get
```

## Qualitaet pruefen

```bash
dart format .
flutter analyze
flutter test
```

## Web lokal starten

```bash
flutter run -d chrome
```

Alternativ kann der vorhandene lokale Web-Server genutzt werden:

```bash
dart run serve_web.dart
```

## Build erstellen

```bash
flutter build web --release
```

## GitHub

```bash
git status
git add .
git commit -m "Prepare app"
git push
```

Hinweis: Build-Artefakte wie `build/`, Flutter-Caches und lokale IDE-Dateien
werden ueber `.gitignore` ausgeschlossen.
