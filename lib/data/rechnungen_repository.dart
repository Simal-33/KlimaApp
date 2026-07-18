import '../data/db_helper.dart';
import '../models/rechnung.dart';

class RechnungenRepository {
  Future<List<RechnungUebersicht>> uebersicht() async {
    final db = await DBHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT r.id, r.nummer, r.datum, r.faellig_am, r.bezahlt, r.gesamtpreis,
             k.name AS kunde_name
      FROM rechnungen r
      JOIN kunden k ON k.id = r.kunde_id
      ORDER BY r.datum DESC
    ''');
    return rows.map(RechnungUebersicht.fromMap).toList();
  }

  Future<Rechnung?> byId(int id) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('rechnungen', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Rechnung.fromMap(rows.first);
  }

  Future<List<RechnungPosition>> positionenFuer(int rechnungId) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query(
      'rechnung_positionen',
      where: 'rechnung_id = ?',
      whereArgs: [rechnungId],
    );
    return rows.map(RechnungPosition.fromMap).toList();
  }

  /// Fortlaufende Rechnungsnummer im Format RE-<Jahr>-<lfd. Nr.>.
  Future<String> naechsteNummer() async {
    final db = await DBHelper.instance.database;
    final jahr = DateTime.now().year;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM rechnungen WHERE nummer LIKE ?",
      ['RE-$jahr-%'],
    );
    final anzahl = (result.first['c'] as int?) ?? 0;
    return 'RE-$jahr-${(anzahl + 1).toString().padLeft(4, '0')}';
  }

  Future<int> anlegenMitPositionen(
    Rechnung rechnung,
    List<RechnungPosition> positionen,
  ) async {
    final db = await DBHelper.instance.database;
    return db.transaction<int>((txn) async {
      final rechnungId = await txn.insert('rechnungen', rechnung.toMap());
      for (final pos in positionen) {
        await txn.insert(
          'rechnung_positionen',
          pos.toMap()..['rechnung_id'] = rechnungId,
        );
      }
      return rechnungId;
    });
  }

  Future<void> aktualisierenMitPositionen(
    Rechnung rechnung,
    List<RechnungPosition> positionen,
  ) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'rechnungen',
        rechnung.toMap(),
        where: 'id = ?',
        whereArgs: [rechnung.id],
      );
      await txn.delete(
        'rechnung_positionen',
        where: 'rechnung_id = ?',
        whereArgs: [rechnung.id],
      );
      for (final pos in positionen) {
        await txn.insert(
          'rechnung_positionen',
          pos.toMap()..['rechnung_id'] = rechnung.id,
        );
      }
    });
  }

  Future<void> alsBezahltMarkieren(int id, {DateTime? bezahltAm}) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'rechnungen',
      {
        'bezahlt': 1,
        'bezahlt_am': (bezahltAm ?? DateTime.now()).toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> zahlungZuruecksetzen(int id) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'rechnungen',
      {'bezahlt': 0, 'bezahlt_am': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('rechnungen', where: 'id = ?', whereArgs: [id]);
  }
}
