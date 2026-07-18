import '../data/db_helper.dart';
import '../models/kunde.dart';

/// Kapselt alle Datenbankzugriffe für das Kunden-Modul.
/// UI-Code ruft nur diese Methoden auf und weiß nichts von SQL.
class KundenRepository {
  Future<List<Kunde>> alle({String? suchtext}) async {
    final db = await DBHelper.instance.database;

    final List<Map<String, dynamic>> rows;
    if (suchtext != null && suchtext.trim().isNotEmpty) {
      final like = '%${suchtext.trim()}%';
      rows = await db.query(
        'kunden',
        where: 'name LIKE ? OR ort LIKE ? OR telefon LIKE ? OR email LIKE ?',
        whereArgs: [like, like, like, like],
        orderBy: 'name COLLATE NOCASE ASC',
      );
    } else {
      rows = await db.query('kunden', orderBy: 'name COLLATE NOCASE ASC');
    }

    return rows.map(Kunde.fromMap).toList();
  }

  Future<Kunde?> byId(int id) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('kunden', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Kunde.fromMap(rows.first);
  }

  Future<int> anlegen(Kunde kunde) async {
    final db = await DBHelper.instance.database;
    return db.insert('kunden', kunde.toMap());
  }

  Future<int> aktualisieren(Kunde kunde) async {
    final db = await DBHelper.instance.database;
    return db.update(
      'kunden',
      kunde.toMap(),
      where: 'id = ?',
      whereArgs: [kunde.id],
    );
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('kunden', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> anzahl() async {
    final db = await DBHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM kunden');
    return (result.first['c'] as int?) ?? 0;
  }
}
