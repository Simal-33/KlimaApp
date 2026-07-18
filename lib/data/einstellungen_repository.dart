import '../data/db_helper.dart';
import '../models/firmeneinstellungen.dart';

class EinstellungenRepository {
  Future<Firmeneinstellungen> laden() async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('einstellungen', where: 'id = 1');
    if (rows.isEmpty) {
      return const Firmeneinstellungen(firmenname: 'Mein Klimatechnik-Betrieb');
    }
    return Firmeneinstellungen.fromMap(rows.first);
  }

  Future<void> speichern(Firmeneinstellungen einstellungen) async {
    final db = await DBHelper.instance.database;
    final anzahl = await db.query('einstellungen', where: 'id = 1');
    if (anzahl.isEmpty) {
      await db.insert('einstellungen', einstellungen.toMap());
    } else {
      await db.update('einstellungen', einstellungen.toMap(), where: 'id = 1');
    }
  }
}
