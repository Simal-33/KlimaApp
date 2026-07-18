/// Einzelne Position einer Rechnung (Tabelle `rechnung_positionen`).
/// Bewusst schlanker als `AngebotPosition` (kein Typ/Bezug), da eine
/// Rechnung meist aus einem angenommenen Angebot 1:1 übernommen wird.
class RechnungPosition {
  final int? id;
  final int? rechnungId;
  final String bezeichnung;
  final double menge;
  final double einzelpreis;

  const RechnungPosition({
    this.id,
    this.rechnungId,
    required this.bezeichnung,
    required this.menge,
    required this.einzelpreis,
  });

  double get gesamt => menge * einzelpreis;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (rechnungId != null) 'rechnung_id': rechnungId,
      'bezeichnung': bezeichnung,
      'menge': menge,
      'einzelpreis': einzelpreis,
    };
  }

  factory RechnungPosition.fromMap(Map<String, dynamic> map) {
    return RechnungPosition(
      id: map['id'] as int?,
      rechnungId: map['rechnung_id'] as int?,
      bezeichnung: map['bezeichnung'] as String,
      menge: (map['menge'] as num).toDouble(),
      einzelpreis: (map['einzelpreis'] as num).toDouble(),
    );
  }
}

/// Rechnungs-Kopfdaten (Tabelle `rechnungen`).
class Rechnung {
  final int? id;
  final String nummer;
  final int kundeId;
  final int? auftragId;
  final DateTime datum;
  final DateTime? faelligAm;
  final double mwstProzent;
  final double gesamtpreis;
  final bool bezahlt;
  final DateTime? bezahltAm;
  final String? pdfPfad;

  const Rechnung({
    this.id,
    required this.nummer,
    required this.kundeId,
    this.auftragId,
    required this.datum,
    this.faelligAm,
    this.mwstProzent = 19,
    this.gesamtpreis = 0,
    this.bezahlt = false,
    this.bezahltAm,
    this.pdfPfad,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nummer': nummer,
      'kunde_id': kundeId,
      'auftrag_id': auftragId,
      'datum': datum.toIso8601String(),
      'faellig_am': faelligAm?.toIso8601String(),
      'mwst_prozent': mwstProzent,
      'gesamtpreis': gesamtpreis,
      'bezahlt': bezahlt ? 1 : 0,
      'bezahlt_am': bezahltAm?.toIso8601String(),
      'pdf_pfad': pdfPfad,
    };
  }

  factory Rechnung.fromMap(Map<String, dynamic> map) {
    return Rechnung(
      id: map['id'] as int?,
      nummer: map['nummer'] as String,
      kundeId: map['kunde_id'] as int,
      auftragId: map['auftrag_id'] as int?,
      datum: DateTime.tryParse(map['datum'] as String) ?? DateTime.now(),
      faelligAm: map['faellig_am'] != null
          ? DateTime.tryParse(map['faellig_am'] as String)
          : null,
      mwstProzent: (map['mwst_prozent'] as num?)?.toDouble() ?? 19,
      gesamtpreis: (map['gesamtpreis'] as num?)?.toDouble() ?? 0,
      bezahlt: (map['bezahlt'] as int?) == 1,
      bezahltAm: map['bezahlt_am'] != null
          ? DateTime.tryParse(map['bezahlt_am'] as String)
          : null,
      pdfPfad: map['pdf_pfad'] as String?,
    );
  }
}

enum RechnungStatus { offen, ueberfaellig, bezahlt }

extension RechnungStatusLabel on RechnungStatus {
  String get label => switch (this) {
        RechnungStatus.offen => 'Offen',
        RechnungStatus.ueberfaellig => 'Überfällig',
        RechnungStatus.bezahlt => 'Bezahlt',
      };
}

/// Zusammenfassung für die Listenansicht (Rechnung + Kundenname + Status).
class RechnungUebersicht {
  final int id;
  final String nummer;
  final String kundeName;
  final DateTime datum;
  final DateTime? faelligAm;
  final bool bezahlt;
  final double gesamtpreis;

  const RechnungUebersicht({
    required this.id,
    required this.nummer,
    required this.kundeName,
    required this.datum,
    required this.faelligAm,
    required this.bezahlt,
    required this.gesamtpreis,
  });

  RechnungStatus get status {
    if (bezahlt) return RechnungStatus.bezahlt;
    if (faelligAm != null && faelligAm!.isBefore(DateTime.now())) {
      return RechnungStatus.ueberfaellig;
    }
    return RechnungStatus.offen;
  }

  factory RechnungUebersicht.fromMap(Map<String, dynamic> map) {
    return RechnungUebersicht(
      id: map['id'] as int,
      nummer: map['nummer'] as String,
      kundeName: map['kunde_name'] as String? ?? 'Unbekannt',
      datum: DateTime.tryParse(map['datum'] as String) ?? DateTime.now(),
      faelligAm: map['faellig_am'] != null
          ? DateTime.tryParse(map['faellig_am'] as String)
          : null,
      bezahlt: (map['bezahlt'] as int?) == 1,
      gesamtpreis: (map['gesamtpreis'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Kapselt die Preisberechnung einer Rechnung (Netto aus Positionen + MwSt.).
class RechnungBerechnung {
  final double netto;
  final double mwstProzent;

  const RechnungBerechnung({required this.netto, required this.mwstProzent});

  double get mwstBetrag => netto * (mwstProzent / 100);
  double get gesamtpreis => netto + mwstBetrag;
}
