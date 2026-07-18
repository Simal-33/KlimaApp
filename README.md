# Klima-App

Flutter-App fuer Montage- und Verwaltungsprozesse in Klimaanlagenbetrieben.
Das Projekt enthaelt lokale SQLite-Datenhaltung, Stammdatenverwaltung,
Angebote, Rechnungen, Kalender, Lagerverwaltung und Excel/PDF-Funktionen.

## Funktionen

- Kundenverwaltung mit Suche, Standortdaten und Geraetezuordnung
- Geraete- und Materialverwaltung mit Mindestbestand
- Angebots- und Rechnungserstellung inklusive Positionen, Rabatt, MwSt. und PDF-Ausgabe
- Kalender fuer Termine, Wartungen, Erinnerungen und Urlaub
- Monteurverwaltung mit Kontakt- und Stundensatzdaten
- Lagerverwaltung mit Wareneingang, Warenausgang, Inventur und Bestellliste
- Excel Import/Export fuer zentrale Datenbereiche
- Einstellungen fuer Firmendaten, MwSt., IBAN/BIC, Stunden- und Kilometerpreise

## Status

Einige Module sind bewusst als naechste Ausbaustufen vorgesehen:

- Auftragsmodul mit Montage-Workflow
- Fotodokumentation, Unterschrift und Checklisten
- Barcode-/QR-Scanner
- Firmenlogo-Upload und individuelle PDF-Vorlagen
- Echte Authentifizierung statt Mock-Login
- Statistik-Dashboard

## Projektstruktur

```text
klima_app/
├── database/schema.sql
├── lib/
│   ├── data/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   └── widgets/
├── test/
├── web/
├── pubspec.yaml
└── README.md
```

## Voraussetzungen

- Flutter SDK
- Dart SDK, normalerweise im Flutter SDK enthalten
- Git

Installation Flutter:
https://docs.flutter.dev/get-started/install

## Lokal starten

```bash
flutter pub get
flutter run
```

## Tests und Analyse

```bash
flutter analyze
flutter test
```

## Auf GitHub hochladen

1. Repository auf GitHub erstellen.
2. Remote verbinden:

```bash
git remote add origin https://github.com/DEIN-NAME/DEIN-REPO.git
```

3. Dateien committen und hochladen:

```bash
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

## Hinweise

Build-Artefakte, lokale IDE-Dateien, Flutter-Cache und persoenliche Codex/Claude-Arbeitsordner werden per `.gitignore` ausgeschlossen. Die Datei `pubspec.lock` bleibt enthalten, damit Builds reproduzierbar sind.
