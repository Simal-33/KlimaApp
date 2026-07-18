/// Datenmodell für einen Monteur (Tabelle `monteure`).
class Monteur {
  final int? id;
  final String name;
  final String? telefon;
  final String? email;
  final double stundensatz;
  final bool aktiv;

  const Monteur({
    this.id,
    required this.name,
    this.telefon,
    this.email,
    this.stundensatz = 65,
    this.aktiv = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'telefon': telefon,
      'email': email,
      'stundensatz': stundensatz,
      'aktiv': aktiv ? 1 : 0,
    };
  }

  factory Monteur.fromMap(Map<String, dynamic> map) {
    return Monteur(
      id: map['id'] as int?,
      name: map['name'] as String,
      telefon: map['telefon'] as String?,
      email: map['email'] as String?,
      stundensatz: (map['stundensatz'] as num?)?.toDouble() ?? 65,
      aktiv: (map['aktiv'] as int?) != 0,
    );
  }
}
