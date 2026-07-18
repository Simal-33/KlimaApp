enum LagerbewegungTyp { eingang, ausgang, inventur }

extension LagerbewegungTypLabel on LagerbewegungTyp {
  String get dbWert => switch (this) {
        LagerbewegungTyp.eingang => 'eingang',
        LagerbewegungTyp.ausgang => 'ausgang',
        LagerbewegungTyp.inventur => 'inventur',
      };

  static LagerbewegungTyp fromDb(String wert) => switch (wert) {
        'ausgang' => LagerbewegungTyp.ausgang,
        'inventur' => LagerbewegungTyp.inventur,
        _ => LagerbewegungTyp.eingang,
      };

  String get label => switch (this) {
        LagerbewegungTyp.eingang => 'Wareneingang',
        LagerbewegungTyp.ausgang => 'Warenausgang',
        LagerbewegungTyp.inventur => 'Inventur',
      };
}

enum LagerArtikelTyp { geraet, material }

extension LagerArtikelTypLabel on LagerArtikelTyp {
  String get dbWert => this == LagerArtikelTyp.geraet ? 'geraet' : 'material';
  static LagerArtikelTyp fromDb(String wert) =>
      wert == 'geraet' ? LagerArtikelTyp.geraet : LagerArtikelTyp.material;
  String get tabelle => this == LagerArtikelTyp.geraet ? 'geraete' : 'material';
}

/// Ein Eintrag im Lagerbewegungs-Journal (Tabelle `lagerbewegungen`).
class Lagerbewegung {
  final int? id;
  final LagerbewegungTyp typ;
  final LagerArtikelTyp bezugTyp;
  final int bezugId;
  final double menge;
  final DateTime datum;
  final String? notiz;

  const Lagerbewegung({
    this.id,
    required this.typ,
    required this.bezugTyp,
    required this.bezugId,
    required this.menge,
    required this.datum,
    this.notiz,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'typ': typ.dbWert,
      'bezug_typ': bezugTyp.dbWert,
      'bezug_id': bezugId,
      'menge': menge,
      'datum': datum.toIso8601String(),
      'notiz': notiz,
    };
  }

  factory Lagerbewegung.fromMap(Map<String, dynamic> map) {
    return Lagerbewegung(
      id: map['id'] as int?,
      typ: LagerbewegungTypLabel.fromDb(map['typ'] as String),
      bezugTyp: LagerArtikelTypLabel.fromDb(map['bezug_typ'] as String),
      bezugId: map['bezug_id'] as int,
      menge: (map['menge'] as num).toDouble(),
      datum: DateTime.tryParse(map['datum'] as String) ?? DateTime.now(),
      notiz: map['notiz'] as String?,
    );
  }
}
