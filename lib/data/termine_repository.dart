import '../data/db_helper.dart';
import '../models/termin.dart';

class TermineRepository {
  Future<List<Termin>> alle() async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('termine', orderBy: 'datum ASC');
    return rows.map(Termin.fromMap).toList();
  }

  /// Alle Termine, gruppiert nach Tag (nur Datum, ohne Uhrzeit), für die
  /// Punkte-Markierung im Kalender.
  Future<Map<DateTime, List<Termin>>> alleGruppiert() async {
    final termine = await alle();
    final Map<DateTime, List<Termin>> gruppiert = {};
    for (final t in termine) {
      final tag = DateTime(t.datum.year, t.datum.month, t.datum.day);
      gruppiert.putIfAbsent(tag, () => []).add(t);
    }
    return gruppiert;
  }

  Future<int> anlegen(Termin termin) async {
    final db = await DBHelper.instance.database;
    return db.insert('termine', termin.toMap());
  }

  Future<int> aktualisieren(Termin termin) async {
    final db = await DBHelper.instance.database;
    return db.update('termine', termin.toMap(), where: 'id = ?', whereArgs: [termin.id]);
  }

  Future<void> erledigtSetzen(int id, bool erledigt) async {
    final db = await DBHelper.instance.database;
    await db.update('termine', {'erledigt': erledigt ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('termine', where: 'id = ?', whereArgs: [id]);
  }
}
