import '../data/db_helper.dart';
import '../models/auftrag.dart';

class AuftraegeRepository {
  Future<List<AuftragUebersicht>> uebersicht() async {
    final db = await DBHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT auf.id, auf.angebot_id, auf.status, auf.termin,
             a.nummer AS angebotsnummer,
             k.name AS kunde_name,
             m.name AS monteur_name
      FROM auftraege auf
      JOIN kunden k ON k.id = auf.kunde_id
      LEFT JOIN angebote a ON a.id = auf.angebot_id
      LEFT JOIN monteure m ON m.id = auf.monteur_id
      ORDER BY
        CASE WHEN auf.termin IS NULL THEN 1 ELSE 0 END,
        auf.termin ASC,
        auf.id DESC
    ''');
    return rows.map(AuftragUebersicht.fromMap).toList();
  }

  Future<Auftrag?> byId(int id) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('auftraege', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Auftrag.fromMap(rows.first);
  }

  Future<int> anlegen(Auftrag auftrag) async {
    final db = await DBHelper.instance.database;
    return db.insert('auftraege', auftrag.toMap());
  }

  Future<int> aktualisieren(Auftrag auftrag) async {
    final db = await DBHelper.instance.database;
    return db.update(
      'auftraege',
      auftrag.toMap(),
      where: 'id = ?',
      whereArgs: [auftrag.id],
    );
  }

  Future<void> statusAendern(int id, AuftragStatus status) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'auftraege',
      {'status': status.dbWert},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('auftraege', where: 'id = ?', whereArgs: [id]);
  }
}
