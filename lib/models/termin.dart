/// Art des Kalender-Termins.
enum TerminTyp { montage, wartung, erinnerung, urlaub }

extension TerminTypLabel on TerminTyp {
  String get dbWert => switch (this) {
        TerminTyp.montage => 'montage',
        TerminTyp.wartung => 'wartung',
        TerminTyp.erinnerung => 'erinnerung',
        TerminTyp.urlaub => 'urlaub',
      };

  static TerminTyp fromDb(String wert) => switch (wert) {
        'wartung' => TerminTyp.wartung,
        'erinnerung' => TerminTyp.erinnerung,
        'urlaub' => TerminTyp.urlaub,
        _ => TerminTyp.montage,
      };

  String get label => switch (this) {
        TerminTyp.montage => 'Montagetermin',
        TerminTyp.wartung => 'Wartung',
        TerminTyp.erinnerung => 'Erinnerung',
        TerminTyp.urlaub => 'Urlaub',
      };
}

/// Ein Kalendereintrag (Tabelle `termine`).
class Termin {
  final int? id;
  final String titel;
  final TerminTyp typ;
  final DateTime datum;
  final int? kundeId;
  final String? notiz;
  final bool erledigt;

  const Termin({
    this.id,
    required this.titel,
    required this.typ,
    required this.datum,
    this.kundeId,
    this.notiz,
    this.erledigt = false,
  });

  Termin copyWith({bool? erledigt}) {
    return Termin(
      id: id,
      titel: titel,
      typ: typ,
      datum: datum,
      kundeId: kundeId,
      notiz: notiz,
      erledigt: erledigt ?? this.erledigt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titel': titel,
      'typ': typ.dbWert,
      'datum': datum.toIso8601String(),
      'kunde_id': kundeId,
      'notiz': notiz,
      'erledigt': erledigt ? 1 : 0,
    };
  }

  factory Termin.fromMap(Map<String, dynamic> map, {String? kundeName}) {
    return Termin(
      id: map['id'] as int?,
      titel: map['titel'] as String,
      typ: TerminTypLabel.fromDb(map['typ'] as String? ?? 'montage'),
      datum: DateTime.parse(map['datum'] as String),
      kundeId: map['kunde_id'] as int?,
      notiz: map['notiz'] as String?,
      erledigt: (map['erledigt'] as int?) == 1,
    );
  }
}
