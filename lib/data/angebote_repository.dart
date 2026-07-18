import '../data/db_helper.dart';
import '../models/angebot.dart';

/// Kapselt alle Datenbankzugriffe für das Angebots-Modul.
/// Angebot + Positionen werden immer gemeinsam in einer Transaktion
/// gespeichert, damit nie ein Angebot ohne (oder mit falschen) Positionen
/// in der Datenbank landet.
class AngeboteRepository {
  Future<List<AngebotUebersicht>> uebersicht() async {
    final db = await DBHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT a.id, a.nummer, a.datum, a.status, a.gesamtpreis,
             k.name AS kunde_name
      FROM angebote a
      JOIN kunden k ON k.id = a.kunde_id
      ORDER BY a.datum DESC
    ''');
    return rows.map(AngebotUebersicht.fromMap).toList();
  }

  Future<Angebot?> byId(int id) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('angebote', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Angebot.fromMap(rows.first);
  }

  Future<List<AngebotPosition>> positionenFuer(int angebotId) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query(
      'angebot_positionen',
      where: 'angebot_id = ?',
      whereArgs: [angebotId],
    );
    return rows.map(AngebotPosition.fromMap).toList();
  }

  /// Erzeugt eine fortlaufende Angebotsnummer im Format AN-<Jahr>-<lfd. Nr.>,
  /// z.B. "AN-2026-0007".
  Future<String> naechsteNummer() async {
    final db = await DBHelper.instance.database;
    final jahr = DateTime.now().year;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM angebote WHERE nummer LIKE ?",
      ['AN-$jahr-%'],
    );
    final anzahl = (result.first['c'] as int?) ?? 0;
    final lfdNr = (anzahl + 1).toString().padLeft(4, '0');
    return 'AN-$jahr-$lfdNr';
  }

  Future<int> anlegenMitPositionen(
    Angebot angebot,
    List<AngebotPosition> positionen,
  ) async {
    final db = await DBHelper.instance.database;
    return db.transaction<int>((txn) async {
      final angebotId = await txn.insert('angebote', angebot.toMap());
      for (final pos in positionen) {
        await txn.insert(
          'angebot_positionen',
          pos.toMap()..['angebot_id'] = angebotId,
        );
      }
      return angebotId;
    });
  }

  Future<void> aktualisierenMitPositionen(
    Angebot angebot,
    List<AngebotPosition> positionen,
  ) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'angebote',
        angebot.toMap(),
        where: 'id = ?',
        whereArgs: [angebot.id],
      );
      // Einfachster konsistenter Ansatz: alte Positionen ersetzen.
      await txn.delete(
        'angebot_positionen',
        where: 'angebot_id = ?',
        whereArgs: [angebot.id],
      );
      for (final pos in positionen) {
        await txn.insert(
          'angebot_positionen',
          pos.toMap()..['angebot_id'] = angebot.id,
        );
      }
    });
  }

  Future<void> statusAendern(int id, AngebotStatus status) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'angebote',
      {'status': status.dbWert},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> loeschen(int id) async {
    final db = await DBHelper.instance.database;
    // ON DELETE CASCADE im Schema entfernt die zugehörigen Positionen mit.
    return db.delete('angebote', where: 'id = ?', whereArgs: [id]);
  }
}
