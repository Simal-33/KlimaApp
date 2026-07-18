/// Datenmodell für einen Material-Artikel (Tabelle `material`).
/// Bewusst nicht "Material" genannt, da dieser Name bereits durch
/// das gleichnamige Flutter-Widget belegt ist.
class MaterialArtikel {
  final int? id;
  final String artikel;
  final String einheit; // z.B. "m", "Stück"
  final double preis;
  final double lagerbestand;
  final double mindestbestand;

  const MaterialArtikel({
    this.id,
    required this.artikel,
    this.einheit = 'Stück',
    this.preis = 0,
    this.lagerbestand = 0,
    this.mindestbestand = 0,
  });

  bool get unterMindestbestand => lagerbestand <= mindestbestand;

  MaterialArtikel copyWith({
    int? id,
    String? artikel,
    String? einheit,
    double? preis,
    double? lagerbestand,
    double? mindestbestand,
  }) {
    return MaterialArtikel(
      id: id ?? this.id,
      artikel: artikel ?? this.artikel,
      einheit: einheit ?? this.einheit,
      preis: preis ?? this.preis,
      lagerbestand: lagerbestand ?? this.lagerbestand,
      mindestbestand: mindestbestand ?? this.mindestbestand,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'artikel': artikel,
      'einheit': einheit,
      'preis': preis,
      'lagerbestand': lagerbestand,
      'mindestbestand': mindestbestand,
    };
  }

  factory MaterialArtikel.fromMap(Map<String, dynamic> map) {
    return MaterialArtikel(
      id: map['id'] as int?,
      artikel: map['artikel'] as String,
      einheit: map['einheit'] as String? ?? 'Stück',
      preis: (map['preis'] as num?)?.toDouble() ?? 0,
      lagerbestand: (map['lagerbestand'] as num?)?.toDouble() ?? 0,
      mindestbestand: (map['mindestbestand'] as num?)?.toDouble() ?? 0,
    );
  }
}
