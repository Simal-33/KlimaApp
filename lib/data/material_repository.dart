import '../data/db_helper.dart';
import '../models/material_artikel.dart';

class MaterialRepository {
  Future<List<MaterialArtikel>> alle({String? suchtext}) async {
    final db = await DBHelper.instance.database;

    final List<Map<String, dynamic>> rows;
    if (suchtext != null && suchtext.trim().isNotEmpty) {
      final like = '%${suchtext.trim()}%';
      rows = await db.query(
        'material',
        where: 'artikel LIKE ?',
        whereArgs: [like],
        orderBy: 'artikel COLLATE NOCASE ASC',
      );
    } else {
      rows = await db.query('material', orderBy: 'artikel COLLATE NOCASE ASC');
    }

    return rows.map(MaterialArtikel.fromMap).toList();
  }

  Future<int> anlegen(MaterialArtikel material) async {
    final db = await DBHelper.instance.database;
    return db.insert('material', material.toMap());
  }

  Future<int> aktualisieren(MaterialArtikel material) async {
    final db = await DBHelper.instance.database;
    return db.update('material', material.toMap(),
        where: 'id = ?', whereArgs: [material.id]);
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('material', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> anzahlUnterMindestbestand() async {
    final db = await DBHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM material WHERE lagerbestand <= mindestbestand');
    return (result.first['c'] as int?) ?? 0;
  }
}
