/// Vollständige Abbildung der `einstellungen`-Tabelle (Single-Row).
class Firmeneinstellungen {
  final String firmenname;
  final String? iban;
  final String? bic;
  final double mwstProzent;
  final double stundenlohnMonteur;
  final double stundenlohnHelfer;
  final double stundenlohnElektriker;
  final double kilometerpreis;

  const Firmeneinstellungen({
    required this.firmenname,
    this.iban,
    this.bic,
    this.mwstProzent = 19,
    this.stundenlohnMonteur = 65,
    this.stundenlohnHelfer = 45,
    this.stundenlohnElektriker = 85,
    this.kilometerpreis = 1.0,
  });

  Firmeneinstellungen copyWith({
    String? firmenname,
    String? iban,
    String? bic,
    double? mwstProzent,
    double? stundenlohnMonteur,
    double? stundenlohnHelfer,
    double? stundenlohnElektriker,
    double? kilometerpreis,
  }) {
    return Firmeneinstellungen(
      firmenname: firmenname ?? this.firmenname,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      mwstProzent: mwstProzent ?? this.mwstProzent,
      stundenlohnMonteur: stundenlohnMonteur ?? this.stundenlohnMonteur,
      stundenlohnHelfer: stundenlohnHelfer ?? this.stundenlohnHelfer,
      stundenlohnElektriker: stundenlohnElektriker ?? this.stundenlohnElektriker,
      kilometerpreis: kilometerpreis ?? this.kilometerpreis,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'firmenname': firmenname,
      'iban': iban,
      'bic': bic,
      'mwst_prozent': mwstProzent,
      'stundenlohn_monteur': stundenlohnMonteur,
      'stundenlohn_helfer': stundenlohnHelfer,
      'stundenlohn_elektriker': stundenlohnElektriker,
      'kilometerpreis': kilometerpreis,
    };
  }

  factory Firmeneinstellungen.fromMap(Map<String, dynamic> map) {
    return Firmeneinstellungen(
      firmenname: (map['firmenname'] as String?)?.trim().isNotEmpty == true
          ? map['firmenname'] as String
          : 'Mein Klimatechnik-Betrieb',
      iban: map['iban'] as String?,
      bic: map['bic'] as String?,
      mwstProzent: (map['mwst_prozent'] as num?)?.toDouble() ?? 19,
      stundenlohnMonteur: (map['stundenlohn_monteur'] as num?)?.toDouble() ?? 65,
      stundenlohnHelfer: (map['stundenlohn_helfer'] as num?)?.toDouble() ?? 45,
      stundenlohnElektriker: (map['stundenlohn_elektriker'] as num?)?.toDouble() ?? 85,
      kilometerpreis: (map['kilometerpreis'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
