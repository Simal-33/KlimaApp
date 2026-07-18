/// Positions-Typen innerhalb eines Angebots.
enum PositionsTyp { geraet, material, arbeitszeit, frei }

extension PositionsTypLabel on PositionsTyp {
  String get dbWert => switch (this) {
        PositionsTyp.geraet => 'geraet',
        PositionsTyp.material => 'material',
        PositionsTyp.arbeitszeit => 'arbeitszeit',
        PositionsTyp.frei => 'frei',
      };

  static PositionsTyp fromDb(String wert) => switch (wert) {
        'geraet' => PositionsTyp.geraet,
        'material' => PositionsTyp.material,
        'arbeitszeit' => PositionsTyp.arbeitszeit,
        _ => PositionsTyp.frei,
      };

  String get label => switch (this) {
        PositionsTyp.geraet => 'Gerät',
        PositionsTyp.material => 'Material',
        PositionsTyp.arbeitszeit => 'Arbeitszeit',
        PositionsTyp.frei => 'Freie Position',
      };
}

/// Einzelne Position eines Angebots (Gerät, Material, Arbeitszeit oder frei).
class AngebotPosition {
  final int? id;
  final int? angebotId;
  final PositionsTyp typ;
  final int? bezugId; // id aus geraete/material, falls zutreffend
  final String bezeichnung;
  final double menge;
  final double einzelpreis;

  const AngebotPosition({
    this.id,
    this.angebotId,
    required this.typ,
    this.bezugId,
    required this.bezeichnung,
    required this.menge,
    required this.einzelpreis,
  });

  double get gesamt => menge * einzelpreis;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (angebotId != null) 'angebot_id': angebotId,
      'typ': typ.dbWert,
      'bezug_id': bezugId,
      'bezeichnung': bezeichnung,
      'menge': menge,
      'einzelpreis': einzelpreis,
    };
  }

  factory AngebotPosition.fromMap(Map<String, dynamic> map) {
    return AngebotPosition(
      id: map['id'] as int?,
      angebotId: map['angebot_id'] as int?,
      typ: PositionsTypLabel.fromDb(map['typ'] as String),
      bezugId: map['bezug_id'] as int?,
      bezeichnung: map['bezeichnung'] as String,
      menge: (map['menge'] as num).toDouble(),
      einzelpreis: (map['einzelpreis'] as num).toDouble(),
    );
  }
}

/// Status eines Angebots.
enum AngebotStatus { offen, angenommen, abgelehnt }

extension AngebotStatusLabel on AngebotStatus {
  String get dbWert => switch (this) {
        AngebotStatus.offen => 'offen',
        AngebotStatus.angenommen => 'angenommen',
        AngebotStatus.abgelehnt => 'abgelehnt',
      };

  static AngebotStatus fromDb(String wert) => switch (wert) {
        'angenommen' => AngebotStatus.angenommen,
        'abgelehnt' => AngebotStatus.abgelehnt,
        _ => AngebotStatus.offen,
      };

  String get label => switch (this) {
        AngebotStatus.offen => 'Offen',
        AngebotStatus.angenommen => 'Angenommen',
        AngebotStatus.abgelehnt => 'Abgelehnt',
      };
}

/// Angebots-Kopfdaten (Tabelle `angebote`).
class Angebot {
  final int? id;
  final String nummer;
  final int kundeId;
  final DateTime datum;
  final double mwstProzent;
  final double rabattProzent;
  final double fahrtkosten;
  final AngebotStatus status;
  final double gesamtpreis;
  final String? pdfPfad;

  const Angebot({
    this.id,
    required this.nummer,
    required this.kundeId,
    required this.datum,
    this.mwstProzent = 19,
    this.rabattProzent = 0,
    this.fahrtkosten = 0,
    this.status = AngebotStatus.offen,
    this.gesamtpreis = 0,
    this.pdfPfad,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nummer': nummer,
      'kunde_id': kundeId,
      'datum': datum.toIso8601String(),
      'mwst_prozent': mwstProzent,
      'rabatt_prozent': rabattProzent,
      'fahrtkosten': fahrtkosten,
      'status': status.dbWert,
      'gesamtpreis': gesamtpreis,
      'pdf_pfad': pdfPfad,
    };
  }

  factory Angebot.fromMap(Map<String, dynamic> map) {
    return Angebot(
      id: map['id'] as int?,
      nummer: map['nummer'] as String,
      kundeId: map['kunde_id'] as int,
      datum: DateTime.tryParse(map['datum'] as String) ?? DateTime.now(),
      mwstProzent: (map['mwst_prozent'] as num?)?.toDouble() ?? 19,
      rabattProzent: (map['rabatt_prozent'] as num?)?.toDouble() ?? 0,
      fahrtkosten: (map['fahrtkosten'] as num?)?.toDouble() ?? 0,
      status: AngebotStatusLabel.fromDb(map['status'] as String? ?? 'offen'),
      gesamtpreis: (map['gesamtpreis'] as num?)?.toDouble() ?? 0,
      pdfPfad: map['pdf_pfad'] as String?,
    );
  }
}

/// Zusammenfassung für die Listenansicht (Angebot + Kundenname).
class AngebotUebersicht {
  final int id;
  final String nummer;
  final String kundeName;
  final DateTime datum;
  final AngebotStatus status;
  final double gesamtpreis;

  const AngebotUebersicht({
    required this.id,
    required this.nummer,
    required this.kundeName,
    required this.datum,
    required this.status,
    required this.gesamtpreis,
  });

  factory AngebotUebersicht.fromMap(Map<String, dynamic> map) {
    return AngebotUebersicht(
      id: map['id'] as int,
      nummer: map['nummer'] as String,
      kundeName: map['kunde_name'] as String? ?? 'Unbekannt',
      datum: DateTime.tryParse(map['datum'] as String) ?? DateTime.now(),
      status: AngebotStatusLabel.fromDb(map['status'] as String? ?? 'offen'),
      gesamtpreis: (map['gesamtpreis'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Kapselt die Preisberechnung eines Angebots, damit Formular und
/// Repository exakt dieselbe Logik verwenden.
class AngebotBerechnung {
  final double zwischensumme; // Summe aller Positionen
  final double rabattProzent;
  final double fahrtkosten;
  final double mwstProzent;

  const AngebotBerechnung({
    required this.zwischensumme,
    required this.rabattProzent,
    required this.fahrtkosten,
    required this.mwstProzent,
  });

  double get rabattBetrag => zwischensumme * (rabattProzent / 100);
  double get nettoNachRabatt => zwischensumme - rabattBetrag;
  double get nettoInklFahrt => nettoNachRabatt + fahrtkosten;
  double get mwstBetrag => nettoInklFahrt * (mwstProzent / 100);
  double get gesamtpreis => nettoInklFahrt + mwstBetrag;
}
