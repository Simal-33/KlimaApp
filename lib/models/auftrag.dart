/// Status eines Auftrags.
enum AuftragStatus { geplant, inArbeit, erledigt, abgerechnet }

extension AuftragStatusLabel on AuftragStatus {
  String get dbWert => switch (this) {
        AuftragStatus.geplant => 'geplant',
        AuftragStatus.inArbeit => 'in_arbeit',
        AuftragStatus.erledigt => 'erledigt',
        AuftragStatus.abgerechnet => 'abgerechnet',
      };

  static AuftragStatus fromDb(String wert) => switch (wert) {
        'in_arbeit' => AuftragStatus.inArbeit,
        'erledigt' => AuftragStatus.erledigt,
        'abgerechnet' => AuftragStatus.abgerechnet,
        _ => AuftragStatus.geplant,
      };

  String get label => switch (this) {
        AuftragStatus.geplant => 'Geplant',
        AuftragStatus.inArbeit => 'In Arbeit',
        AuftragStatus.erledigt => 'Erledigt',
        AuftragStatus.abgerechnet => 'Abgerechnet',
      };
}

/// Auftrags-Kopfdaten (Tabelle `auftraege`).
class Auftrag {
  final int? id;
  final int? angebotId;
  final int kundeId;
  final AuftragStatus status;
  final DateTime? termin;
  final int? monteurId;

  const Auftrag({
    this.id,
    this.angebotId,
    required this.kundeId,
    this.status = AuftragStatus.geplant,
    this.termin,
    this.monteurId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'angebot_id': angebotId,
      'kunde_id': kundeId,
      'status': status.dbWert,
      'termin': termin?.toIso8601String(),
      'monteur_id': monteurId,
    };
  }

  factory Auftrag.fromMap(Map<String, dynamic> map) {
    return Auftrag(
      id: map['id'] as int?,
      angebotId: map['angebot_id'] as int?,
      kundeId: map['kunde_id'] as int,
      status: AuftragStatusLabel.fromDb(map['status'] as String? ?? 'geplant'),
      termin: map['termin'] == null
          ? null
          : DateTime.tryParse(map['termin'] as String),
      monteurId: map['monteur_id'] as int?,
    );
  }
}

/// Zusammenfassung fuer die Listenansicht.
class AuftragUebersicht {
  final int id;
  final int? angebotId;
  final String? angebotsnummer;
  final String kundeName;
  final AuftragStatus status;
  final DateTime? termin;
  final String? monteurName;

  const AuftragUebersicht({
    required this.id,
    this.angebotId,
    this.angebotsnummer,
    required this.kundeName,
    required this.status,
    this.termin,
    this.monteurName,
  });

  factory AuftragUebersicht.fromMap(Map<String, dynamic> map) {
    return AuftragUebersicht(
      id: map['id'] as int,
      angebotId: map['angebot_id'] as int?,
      angebotsnummer: map['angebotsnummer'] as String?,
      kundeName: map['kunde_name'] as String? ?? 'Unbekannt',
      status: AuftragStatusLabel.fromDb(map['status'] as String? ?? 'geplant'),
      termin: map['termin'] == null
          ? null
          : DateTime.tryParse(map['termin'] as String),
      monteurName: map['monteur_name'] as String?,
    );
  }
}
