-- ============================================================
-- Klima-App – Datenbankschema (SQLite / sqflite)
-- Wird beim ersten Start der App automatisch angelegt
-- (siehe lib/data/db_helper.dart -> _onCreate)
-- ============================================================

-- ---------- Benutzer ----------
CREATE TABLE benutzer (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  passwort_hash TEXT NOT NULL,
  rolle         TEXT NOT NULL CHECK (rolle IN ('administrator','buero','monteur','chef')),
  aktiv         INTEGER NOT NULL DEFAULT 1,
  erstellt_am   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------- Kunden ----------
CREATE TABLE kunden (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  adresse      TEXT,
  plz          TEXT,
  ort          TEXT,
  telefon      TEXT,
  email        TEXT,
  notizen      TEXT,
  breitengrad  REAL,          -- Standort auf Karte
  laengengrad  REAL,
  erstellt_am  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------- Lieferanten ----------
CREATE TABLE lieferanten (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  adresse     TEXT,
  telefon     TEXT,
  email       TEXT,
  notizen     TEXT
);

-- ---------- Geräte ----------
CREATE TABLE geraete (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  artikel       TEXT NOT NULL,       -- z.B. "Splitgerät 2,5 kW"
  hersteller    TEXT,
  modell        TEXT,
  einkaufspreis REAL NOT NULL DEFAULT 0,
  verkaufspreis REAL NOT NULL DEFAULT 0,
  lagerbestand  INTEGER NOT NULL DEFAULT 0,
  mindestbestand INTEGER NOT NULL DEFAULT 0,
  lieferant_id  INTEGER REFERENCES lieferanten(id)
);

-- ---------- Material ----------
CREATE TABLE material (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  artikel        TEXT NOT NULL,      -- z.B. "Kupferrohr 1/4"
  einheit        TEXT NOT NULL DEFAULT 'Stück',  -- m, Stück, ...
  preis          REAL NOT NULL DEFAULT 0,
  lagerbestand   REAL NOT NULL DEFAULT 0,
  mindestbestand REAL NOT NULL DEFAULT 0,
  lieferant_id   INTEGER REFERENCES lieferanten(id)
);

-- ---------- Lagerbewegungen (Wareneingang/-ausgang, Inventur) ----------
CREATE TABLE lagerbewegungen (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  typ          TEXT NOT NULL CHECK (typ IN ('eingang','ausgang','inventur')),
  bezug_typ    TEXT NOT NULL CHECK (bezug_typ IN ('geraet','material')),
  bezug_id     INTEGER NOT NULL,
  menge        REAL NOT NULL,
  datum        TEXT NOT NULL DEFAULT (datetime('now')),
  notiz        TEXT
);

-- ---------- Monteure ----------
CREATE TABLE monteure (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  telefon     TEXT,
  email       TEXT,
  stundensatz REAL NOT NULL DEFAULT 65,
  aktiv       INTEGER NOT NULL DEFAULT 1
);

-- ---------- Angebote ----------
CREATE TABLE angebote (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  nummer        TEXT NOT NULL UNIQUE,
  kunde_id      INTEGER NOT NULL REFERENCES kunden(id),
  datum         TEXT NOT NULL DEFAULT (datetime('now')),
  mwst_prozent  REAL NOT NULL DEFAULT 19,
  rabatt_prozent REAL NOT NULL DEFAULT 0,
  fahrtkosten   REAL NOT NULL DEFAULT 0,
  status        TEXT NOT NULL DEFAULT 'offen' CHECK (status IN ('offen','angenommen','abgelehnt')),
  gesamtpreis   REAL NOT NULL DEFAULT 0,
  pdf_pfad      TEXT
);

-- Positionen eines Angebots (Geräte, Material oder Arbeitszeit)
CREATE TABLE angebot_positionen (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  angebot_id  INTEGER NOT NULL REFERENCES angebote(id) ON DELETE CASCADE,
  typ         TEXT NOT NULL CHECK (typ IN ('geraet','material','arbeitszeit','fahrtkosten','frei')),
  bezug_id    INTEGER,             -- id aus geraete/material/monteure, falls zutreffend
  bezeichnung TEXT NOT NULL,
  menge       REAL NOT NULL DEFAULT 1,
  einzelpreis REAL NOT NULL DEFAULT 0
);

-- ---------- Aufträge (aus angenommenem Angebot entstanden) ----------
CREATE TABLE auftraege (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  angebot_id   INTEGER REFERENCES angebote(id),
  kunde_id     INTEGER NOT NULL REFERENCES kunden(id),
  status       TEXT NOT NULL DEFAULT 'geplant' CHECK (status IN ('geplant','in_arbeit','abgeschlossen')),
  termin       TEXT,
  monteur_id   INTEGER REFERENCES monteure(id)
);

-- ---------- Rechnungen ----------
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
);

CREATE TABLE rechnung_positionen (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  rechnung_id   INTEGER NOT NULL REFERENCES rechnungen(id) ON DELETE CASCADE,
  bezeichnung   TEXT NOT NULL,
  menge         REAL NOT NULL DEFAULT 1,
  einzelpreis   REAL NOT NULL DEFAULT 0
);

-- ---------- Arbeitszeiten (je Monteur/Auftrag erfasst) ----------
CREATE TABLE arbeitszeiten (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  auftrag_id  INTEGER NOT NULL REFERENCES auftraege(id),
  monteur_id  INTEGER NOT NULL REFERENCES monteure(id),
  taetigkeit  TEXT NOT NULL DEFAULT 'Monteur', -- Monteur, Helfer, Elektriker
  beginn      TEXT NOT NULL,
  ende        TEXT,
  stundensatz REAL NOT NULL DEFAULT 65
);

-- ---------- Fahrten ----------
CREATE TABLE fahrten (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  auftrag_id   INTEGER REFERENCES auftraege(id),
  entfernung_km REAL NOT NULL DEFAULT 0,
  preis        REAL NOT NULL DEFAULT 0,
  datum        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------- Wartungen ----------
CREATE TABLE wartungen (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  kunde_id        INTEGER NOT NULL REFERENCES kunden(id),
  geraet_id       INTEGER REFERENCES geraete(id),
  intervall_monate INTEGER NOT NULL DEFAULT 12,
  letzte_wartung  TEXT,
  naechste_wartung TEXT,
  filterwechsel   INTEGER NOT NULL DEFAULT 0,
  dichtigkeitspruefung INTEGER NOT NULL DEFAULT 0,
  protokoll       TEXT
);

-- ---------- Fotos (Baustellendokumentation) ----------
CREATE TABLE fotos (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  auftrag_id  INTEGER REFERENCES auftraege(id),
  pfad        TEXT NOT NULL,
  typ         TEXT CHECK (typ IN ('vorher','nachher','sonstiges')),
  aufgenommen_am TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------- Termine (Kalender: Montagetermine, Wartungen, Erinnerungen, Urlaub) ----------
CREATE TABLE termine (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  titel    TEXT NOT NULL,
  typ      TEXT NOT NULL DEFAULT 'montage' CHECK (typ IN ('montage','wartung','erinnerung','urlaub')),
  datum    TEXT NOT NULL,
  kunde_id INTEGER REFERENCES kunden(id),
  notiz    TEXT,
  erledigt INTEGER NOT NULL DEFAULT 0
);

-- ---------- Einstellungen (Single-Row-Konfigurationstabelle) ----------
CREATE TABLE einstellungen (
  id                 INTEGER PRIMARY KEY CHECK (id = 1),
  stundenlohn_monteur   REAL NOT NULL DEFAULT 65,
  stundenlohn_helfer    REAL NOT NULL DEFAULT 45,
  stundenlohn_elektriker REAL NOT NULL DEFAULT 85,
  kilometerpreis        REAL NOT NULL DEFAULT 1.0,
  mwst_prozent          REAL NOT NULL DEFAULT 19,
  firmenname            TEXT,
  firmenlogo_pfad       TEXT,
  iban                  TEXT,
  bic                   TEXT
);

-- Indizes für häufige Suchen/Filter
CREATE INDEX idx_angebote_kunde ON angebote(kunde_id);
CREATE INDEX idx_rechnungen_kunde ON rechnungen(kunde_id);
CREATE INDEX idx_auftraege_kunde ON auftraege(kunde_id);
CREATE INDEX idx_wartungen_kunde ON wartungen(kunde_id);
