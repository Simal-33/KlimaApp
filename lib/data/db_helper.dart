import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Zentraler Zugriffspunkt auf die lokale SQLite-Datenbank.
/// Singleton, damit die App nur eine offene Verbindung verwendet.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;
  static Future<Database>? _dbFuture;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _dbFuture ??= _initDatabase();
    _db = await _dbFuture;
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'klima_app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Legt alle Tabellen an (siehe database/schema.sql für die
  /// vollständige, kommentierte Referenz).
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE benutzer (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        email         TEXT NOT NULL UNIQUE,
        passwort_hash TEXT NOT NULL,
        rolle         TEXT NOT NULL,
        aktiv         INTEGER NOT NULL DEFAULT 1,
        erstellt_am   TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE kunden (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT NOT NULL,
        adresse      TEXT,
        plz          TEXT,
        ort          TEXT,
        telefon      TEXT,
        email        TEXT,
        notizen      TEXT,
        breitengrad  REAL,
        laengengrad  REAL,
        erstellt_am  TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE lieferanten (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        adresse TEXT,
        telefon TEXT,
        email   TEXT,
        notizen TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE geraete (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        artikel        TEXT NOT NULL,
        hersteller     TEXT,
        modell         TEXT,
        einkaufspreis  REAL NOT NULL DEFAULT 0,
        verkaufspreis  REAL NOT NULL DEFAULT 0,
        lagerbestand   INTEGER NOT NULL DEFAULT 0,
        mindestbestand INTEGER NOT NULL DEFAULT 0,
        lieferant_id   INTEGER REFERENCES lieferanten(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE material (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        artikel        TEXT NOT NULL,
        einheit        TEXT NOT NULL DEFAULT 'Stück',
        preis          REAL NOT NULL DEFAULT 0,
        lagerbestand   REAL NOT NULL DEFAULT 0,
        mindestbestand REAL NOT NULL DEFAULT 0,
        lieferant_id   INTEGER REFERENCES lieferanten(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE monteure (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        telefon     TEXT,
        email       TEXT,
        stundensatz REAL NOT NULL DEFAULT 65,
        aktiv       INTEGER NOT NULL DEFAULT 1
      )
    ''');

    batch.execute('''
      CREATE TABLE angebote (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        nummer         TEXT NOT NULL UNIQUE,
        kunde_id       INTEGER NOT NULL REFERENCES kunden(id),
        datum          TEXT NOT NULL DEFAULT (datetime('now')),
        mwst_prozent   REAL NOT NULL DEFAULT 19,
        rabatt_prozent REAL NOT NULL DEFAULT 0,
        fahrtkosten    REAL NOT NULL DEFAULT 0,
        status         TEXT NOT NULL DEFAULT 'offen',
        gesamtpreis    REAL NOT NULL DEFAULT 0,
        pdf_pfad       TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE angebot_positionen (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        angebot_id  INTEGER NOT NULL REFERENCES angebote(id) ON DELETE CASCADE,
        typ         TEXT NOT NULL,
        bezug_id    INTEGER,
        bezeichnung TEXT NOT NULL,
        menge       REAL NOT NULL DEFAULT 1,
        einzelpreis REAL NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE auftraege (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        angebot_id INTEGER REFERENCES angebote(id),
        kunde_id   INTEGER NOT NULL REFERENCES kunden(id),
        status     TEXT NOT NULL DEFAULT 'geplant',
        termin     TEXT,
        monteur_id INTEGER REFERENCES monteure(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE rechnungen (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        nummer       TEXT NOT NULL UNIQUE,
        kunde_id     INTEGER NOT NULL REFERENCES kunden(id),
        auftrag_id   INTEGER REFERENCES auftraege(id),
        datum        TEXT NOT NULL DEFAULT (datetime('now')),
        faellig_am   TEXT,
        mwst_prozent REAL NOT NULL DEFAULT 19,
        gesamtpreis  REAL NOT NULL DEFAULT 0,
        bezahlt      INTEGER NOT NULL DEFAULT 0,
        bezahlt_am   TEXT,
        pdf_pfad     TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE rechnung_positionen (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        rechnung_id INTEGER NOT NULL REFERENCES rechnungen(id) ON DELETE CASCADE,
        bezeichnung TEXT NOT NULL,
        menge       REAL NOT NULL DEFAULT 1,
        einzelpreis REAL NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE arbeitszeiten (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        auftrag_id  INTEGER NOT NULL REFERENCES auftraege(id),
        monteur_id  INTEGER NOT NULL REFERENCES monteure(id),
        taetigkeit  TEXT NOT NULL DEFAULT 'Monteur',
        beginn      TEXT NOT NULL,
        ende        TEXT,
        stundensatz REAL NOT NULL DEFAULT 65
      )
    ''');

    batch.execute('''
      CREATE TABLE fahrten (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        auftrag_id    INTEGER REFERENCES auftraege(id),
        entfernung_km REAL NOT NULL DEFAULT 0,
        preis         REAL NOT NULL DEFAULT 0,
        datum         TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE wartungen (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        kunde_id             INTEGER NOT NULL REFERENCES kunden(id),
        geraet_id            INTEGER REFERENCES geraete(id),
        intervall_monate     INTEGER NOT NULL DEFAULT 12,
        letzte_wartung       TEXT,
        naechste_wartung     TEXT,
        filterwechsel        INTEGER NOT NULL DEFAULT 0,
        dichtigkeitspruefung INTEGER NOT NULL DEFAULT 0,
        protokoll            TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE fotos (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        auftrag_id     INTEGER REFERENCES auftraege(id),
        pfad           TEXT NOT NULL,
        typ            TEXT,
        aufgenommen_am TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE einstellungen (
        id                     INTEGER PRIMARY KEY CHECK (id = 1),
        stundenlohn_monteur    REAL NOT NULL DEFAULT 65,
        stundenlohn_helfer     REAL NOT NULL DEFAULT 45,
        stundenlohn_elektriker REAL NOT NULL DEFAULT 85,
        kilometerpreis         REAL NOT NULL DEFAULT 1.0,
        mwst_prozent           REAL NOT NULL DEFAULT 19,
        firmenname             TEXT,
        firmenlogo_pfad        TEXT,
        iban                   TEXT,
        bic                    TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE lagerbewegungen (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        typ       TEXT NOT NULL,
        bezug_typ TEXT NOT NULL,
        bezug_id  INTEGER NOT NULL,
        menge     REAL NOT NULL,
        datum     TEXT NOT NULL DEFAULT (datetime('now')),
        notiz     TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE termine (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        titel    TEXT NOT NULL,
        typ      TEXT NOT NULL DEFAULT 'montage',
        datum    TEXT NOT NULL,
        kunde_id INTEGER REFERENCES kunden(id),
        notiz    TEXT,
        erledigt INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute(
        "INSERT INTO einstellungen (id, firmenname) VALUES (1, 'Mein Klimatechnik-Betrieb')");

    await batch.commit(noResult: true);
  }
}
