import '../data/db_helper.dart';
import '../models/geraet.dart';

class GeraeteRepository {
  Future<List<Geraet>> alle({String? suchtext}) async {
    final db = await DBHelper.instance.database;

    final List<Map<String, dynamic>> rows;
    if (suchtext != null && suchtext.trim().isNotEmpty) {
      final like = '%${suchtext.trim()}%';
      rows = await db.query(
        'geraete',
        where: 'artikel LIKE ? OR hersteller LIKE ? OR modell LIKE ?',
        whereArgs: [like, like, like],
        orderBy: 'artikel COLLATE NOCASE ASC',
      );
    } else {
      rows = await db.query('geraete', orderBy: 'artikel COLLATE NOCASE ASC');
    }

    return rows.map(Geraet.fromMap).toList();
  }

  Future<int> anlegen(Geraet geraet) async {
    final db = await DBHelper.instance.database;
    return db.insert('geraete', geraet.toMap());
  }

  Future<int> aktualisieren(Geraet geraet) async {
    final db = await DBHelper.instance.database;
    return db.update('geraete', geraet.toMap(),
        where: 'id = ?', whereArgs: [geraet.id]);
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('geraete', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> anzahlUnterMindestbestand() async {
    final db = await DBHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM geraete WHERE lagerbestand <= mindestbestand');
    return (result.first['c'] as int?) ?? 0;
  }
}
