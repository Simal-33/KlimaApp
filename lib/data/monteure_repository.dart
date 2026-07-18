import '../data/db_helper.dart';
import '../models/monteur.dart';

class MonteureRepository {
  Future<List<Monteur>> alle() async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('monteure', orderBy: 'aktiv DESC, name COLLATE NOCASE ASC');
    return rows.map(Monteur.fromMap).toList();
  }

  Future<int> anlegen(Monteur monteur) async {
    final db = await DBHelper.instance.database;
    return db.insert('monteure', monteur.toMap());
  }

  Future<int> aktualisieren(Monteur monteur) async {
    final db = await DBHelper.instance.database;
    return db.update('monteure', monteur.toMap(), where: 'id = ?', whereArgs: [monteur.id]);
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    return db.delete('monteure', where: 'id = ?', whereArgs: [id]);
  }
}
