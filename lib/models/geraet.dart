/// Datenmodell für ein Klimagerät (Tabelle `geraete`).
class Geraet {
  final int? id;
  final String artikel;
  final String? hersteller;
  final String? modell;
  final double einkaufspreis;
  final double verkaufspreis;
  final int lagerbestand;
  final int mindestbestand;

  const Geraet({
    this.id,
    required this.artikel,
    this.hersteller,
    this.modell,
    this.einkaufspreis = 0,
    this.verkaufspreis = 0,
    this.lagerbestand = 0,
    this.mindestbestand = 0,
  });

  bool get unterMindestbestand => lagerbestand <= mindestbestand;

  double get marge => verkaufspreis - einkaufspreis;

  double get margeProzent =>
      einkaufspreis == 0 ? 0 : (marge / einkaufspreis) * 100;

  Geraet copyWith({
    int? id,
    String? artikel,
    String? hersteller,
    String? modell,
    double? einkaufspreis,
    double? verkaufspreis,
    int? lagerbestand,
    int? mindestbestand,
  }) {
    return Geraet(
      id: id ?? this.id,
      artikel: artikel ?? this.artikel,
      hersteller: hersteller ?? this.hersteller,
      modell: modell ?? this.modell,
      einkaufspreis: einkaufspreis ?? this.einkaufspreis,
      verkaufspreis: verkaufspreis ?? this.verkaufspreis,
      lagerbestand: lagerbestand ?? this.lagerbestand,
      mindestbestand: mindestbestand ?? this.mindestbestand,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'artikel': artikel,
      'hersteller': hersteller,
      'modell': modell,
      'einkaufspreis': einkaufspreis,
      'verkaufspreis': verkaufspreis,
      'lagerbestand': lagerbestand,
      'mindestbestand': mindestbestand,
    };
  }

  factory Geraet.fromMap(Map<String, dynamic> map) {
    return Geraet(
      id: map['id'] as int?,
      artikel: map['artikel'] as String,
      hersteller: map['hersteller'] as String?,
      modell: map['modell'] as String?,
      einkaufspreis: (map['einkaufspreis'] as num?)?.toDouble() ?? 0,
      verkaufspreis: (map['verkaufspreis'] as num?)?.toDouble() ?? 0,
      lagerbestand: (map['lagerbestand'] as num?)?.toInt() ?? 0,
      mindestbestand: (map['mindestbestand'] as num?)?.toInt() ?? 0,
    );
  }
}
