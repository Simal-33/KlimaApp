import '../data/db_helper.dart';
import '../models/lagerbewegung.dart';

class LagerbewegungenRepository {
  Future<List<Lagerbewegung>> historieFuer(LagerArtikelTyp typ, int bezugId) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query(
      'lagerbewegungen',
      where: 'bezug_typ = ? AND bezug_id = ?',
      whereArgs: [typ.dbWert, bezugId],
      orderBy: 'datum DESC',
    );
    return rows.map(Lagerbewegung.fromMap).toList();
  }

  /// Bucht Wareneingang/-ausgang oder eine Inventurkorrektur und
  /// aktualisiert den Lagerbestand in `geraete` bzw. `material` in
  /// derselben Transaktion, damit beides immer konsistent bleibt.
  ///
  /// Bei [LagerbewegungTyp.inventur] ist [menge] der neu gezählte
  /// Gesamtbestand (nicht die Differenz).
  Future<void> buchen({
    required LagerbewegungTyp typ,
    required LagerArtikelTyp bezugTyp,
    required int bezugId,
    required double menge,
    String? notiz,
  }) async {
    final db = await DBHelper.instance.database;
    final tabelle = bezugTyp.tabelle;

    await db.transaction((txn) async {
      final rows = await txn.query(tabelle, where: 'id = ?', whereArgs: [bezugId]);
      if (rows.isEmpty) return;
      final aktuellerBestand = (rows.first['lagerbestand'] as num).toDouble();

      final double neuerBestand;
      switch (typ) {
        case LagerbewegungTyp.eingang:
          neuerBestand = aktuellerBestand + menge;
          break;
        case LagerbewegungTyp.ausgang:
          neuerBestand = (aktuellerBestand - menge).clamp(0, double.infinity);
          break;
        case LagerbewegungTyp.inventur:
          neuerBestand = menge;
          break;
      }

      // Geräte führen den Bestand als INTEGER, Material als REAL.
      final istGeraet = bezugTyp == LagerArtikelTyp.geraet;
      await txn.update(
        tabelle,
        {'lagerbestand': istGeraet ? neuerBestand.round() : neuerBestand},
        where: 'id = ?',
        whereArgs: [bezugId],
      );

      await txn.insert(
        'lagerbewegungen',
        Lagerbewegung(
          typ: typ,
          bezugTyp: bezugTyp,
          bezugId: bezugId,
          menge: menge,
          datum: DateTime.now(),
          notiz: notiz,
        ).toMap(),
      );
    });
  }
}
