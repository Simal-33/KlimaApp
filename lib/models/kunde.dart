/// Datenmodell für einen Kunden (Tabelle `kunden`).
class Kunde {
  final int? id;
  final String name;
  final String? adresse;
  final String? plz;
  final String? ort;
  final String? telefon;
  final String? email;
  final String? notizen;
  final double? breitengrad;
  final double? laengengrad;

  const Kunde({
    this.id,
    required this.name,
    this.adresse,
    this.plz,
    this.ort,
    this.telefon,
    this.email,
    this.notizen,
    this.breitengrad,
    this.laengengrad,
  });

  /// Erzeugt eine Kopie mit geänderten Feldern (nützlich beim Bearbeiten).
  Kunde copyWith({
    int? id,
    String? name,
    String? adresse,
    String? plz,
    String? ort,
    String? telefon,
    String? email,
    String? notizen,
    double? breitengrad,
    double? laengengrad,
  }) {
    return Kunde(
      id: id ?? this.id,
      name: name ?? this.name,
      adresse: adresse ?? this.adresse,
      plz: plz ?? this.plz,
      ort: ort ?? this.ort,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      notizen: notizen ?? this.notizen,
      breitengrad: breitengrad ?? this.breitengrad,
      laengengrad: laengengrad ?? this.laengengrad,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'adresse': adresse,
      'plz': plz,
      'ort': ort,
      'telefon': telefon,
      'email': email,
      'notizen': notizen,
      'breitengrad': breitengrad,
      'laengengrad': laengengrad,
    };
  }

  factory Kunde.fromMap(Map<String, dynamic> map) {
    return Kunde(
      id: map['id'] as int?,
      name: map['name'] as String,
      adresse: map['adresse'] as String?,
      plz: map['plz'] as String?,
      ort: map['ort'] as String?,
      telefon: map['telefon'] as String?,
      email: map['email'] as String?,
      notizen: map['notizen'] as String?,
      breitengrad: (map['breitengrad'] as num?)?.toDouble(),
      laengengrad: (map['laengengrad'] as num?)?.toDouble(),
    );
  }

  /// Adresse + PLZ/Ort für die Listenansicht zusammengesetzt.
  String get adresseKompakt {
    final teil2 = [plz, ort].where((s) => s != null && s.isNotEmpty).join(' ');
    return [adresse, teil2].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  bool get hatStandort => breitengrad != null && laengengrad != null;
}
