import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/angebot.dart';
import '../models/geraet.dart';
import '../models/material_artikel.dart';
import '../models/rechnung.dart';

/// Erzeugt und liest .xlsx-Dateien für die verschiedenen Module.
/// Export-Methoden geben den Dateipfad zurück (zum Teilen z.B. via
/// `share_plus`), Import-Methoden lesen eine .xlsx-Datei und geben die
/// eingelesenen Objekte zurück (ohne Datenbank-Id, zum anschließenden
/// Anlegen über das jeweilige Repository).
class ExcelService {
  static Future<String> _speichern(Excel excel, String dateiname) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$dateiname';
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Excel-Datei konnte nicht erzeugt werden.');
    }
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  static String _text(Data? cell) => cell?.value?.toString().trim() ?? '';

  static double _zahl(Data? cell) {
    final raw = cell?.value;
    if (raw is IntCellValue) return raw.value.toDouble();
    if (raw is DoubleCellValue) return raw.value;
    return double.tryParse(_text(cell).replaceAll(',', '.')) ?? 0;
  }

  // ---------------------------------------------------------------------
  // Geräte
  // ---------------------------------------------------------------------

  static Future<String> exportGeraete(List<Geraet> geraete) async {
    final excel = Excel.createExcel();
    final sheet = excel['Geräte'];
    sheet.appendRow([
      TextCellValue('Artikel'),
      TextCellValue('Hersteller'),
      TextCellValue('Modell'),
      TextCellValue('Einkaufspreis'),
      TextCellValue('Verkaufspreis'),
      TextCellValue('Lagerbestand'),
      TextCellValue('Mindestbestand'),
    ]);
    for (final g in geraete) {
      sheet.appendRow([
        TextCellValue(g.artikel),
        TextCellValue(g.hersteller ?? ''),
        TextCellValue(g.modell ?? ''),
        DoubleCellValue(g.einkaufspreis),
        DoubleCellValue(g.verkaufspreis),
        IntCellValue(g.lagerbestand),
        IntCellValue(g.mindestbestand),
      ]);
    }
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
    return _speichern(excel, 'geraete_export.xlsx');
  }

  static Future<List<Geraet>> importGeraete(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    final ergebnis = <Geraet>[];

    for (final row in sheet.rows.skip(1)) {
      final artikel = _text(row.elementAtOrNull(0));
      if (artikel.isEmpty) continue;
      ergebnis.add(Geraet(
        artikel: artikel,
        hersteller: _text(row.elementAtOrNull(1)).isEmpty ? null : _text(row.elementAtOrNull(1)),
        modell: _text(row.elementAtOrNull(2)).isEmpty ? null : _text(row.elementAtOrNull(2)),
        einkaufspreis: _zahl(row.elementAtOrNull(3)),
        verkaufspreis: _zahl(row.elementAtOrNull(4)),
        lagerbestand: _zahl(row.elementAtOrNull(5)).round(),
        mindestbestand: _zahl(row.elementAtOrNull(6)).round(),
      ));
    }
    return ergebnis;
  }

  // ---------------------------------------------------------------------
  // Material
  // ---------------------------------------------------------------------

  static Future<String> exportMaterial(List<MaterialArtikel> material) async {
    final excel = Excel.createExcel();
    final sheet = excel['Material'];
    sheet.appendRow([
      TextCellValue('Artikel'),
      TextCellValue('Einheit'),
      TextCellValue('Preis'),
      TextCellValue('Lagerbestand'),
      TextCellValue('Mindestbestand'),
    ]);
    for (final m in material) {
      sheet.appendRow([
        TextCellValue(m.artikel),
        TextCellValue(m.einheit),
        DoubleCellValue(m.preis),
        DoubleCellValue(m.lagerbestand),
        DoubleCellValue(m.mindestbestand),
      ]);
    }
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
    return _speichern(excel, 'material_export.xlsx');
  }

  static Future<List<MaterialArtikel>> importMaterial(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    final ergebnis = <MaterialArtikel>[];

    for (final row in sheet.rows.skip(1)) {
      final artikel = _text(row.elementAtOrNull(0));
      if (artikel.isEmpty) continue;
      final einheit = _text(row.elementAtOrNull(1));
      ergebnis.add(MaterialArtikel(
        artikel: artikel,
        einheit: einheit.isEmpty ? 'Stück' : einheit,
        preis: _zahl(row.elementAtOrNull(2)),
        lagerbestand: _zahl(row.elementAtOrNull(3)),
        mindestbestand: _zahl(row.elementAtOrNull(4)),
      ));
    }
    return ergebnis;
  }

  // ---------------------------------------------------------------------
  // Lagerbestand (kombinierte Übersicht, nur Export)
  // ---------------------------------------------------------------------

  static Future<String> exportLagerbestand(
    List<Geraet> geraete,
    List<MaterialArtikel> material,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Lagerbestand'];
    sheet.appendRow([
      TextCellValue('Typ'),
      TextCellValue('Artikel'),
      TextCellValue('Einheit'),
      TextCellValue('Lagerbestand'),
      TextCellValue('Mindestbestand'),
      TextCellValue('Unter Mindestbestand'),
    ]);
    for (final g in geraete) {
      sheet.appendRow([
        TextCellValue('Gerät'),
        TextCellValue(g.artikel),
        TextCellValue('Stk.'),
        IntCellValue(g.lagerbestand),
        IntCellValue(g.mindestbestand),
        TextCellValue(g.unterMindestbestand ? 'Ja' : 'Nein'),
      ]);
    }
    for (final m in material) {
      sheet.appendRow([
        TextCellValue('Material'),
        TextCellValue(m.artikel),
        TextCellValue(m.einheit),
        DoubleCellValue(m.lagerbestand),
        DoubleCellValue(m.mindestbestand),
        TextCellValue(m.lagerbestand <= m.mindestbestand ? 'Ja' : 'Nein'),
      ]);
    }
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
    return _speichern(excel, 'lagerbestand_export.xlsx');
  }

  // ---------------------------------------------------------------------
  // Angebote & Rechnungen (Übersicht, nur Export)
  // ---------------------------------------------------------------------

  static Future<String> exportAngebote(List<AngebotUebersicht> angebote) async {
    final excel = Excel.createExcel();
    final sheet = excel['Angebote'];
    sheet.appendRow([
      TextCellValue('Nummer'),
      TextCellValue('Kunde'),
      TextCellValue('Datum'),
      TextCellValue('Status'),
      TextCellValue('Gesamtpreis'),
    ]);
    for (final a in angebote) {
      sheet.appendRow([
        TextCellValue(a.nummer),
        TextCellValue(a.kundeName),
        TextCellValue(_datum(a.datum)),
        TextCellValue(a.status.label),
        DoubleCellValue(a.gesamtpreis),
      ]);
    }
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
    return _speichern(excel, 'angebote_export.xlsx');
  }

  static Future<String> exportRechnungen(List<RechnungUebersicht> rechnungen) async {
    final excel = Excel.createExcel();
    final sheet = excel['Rechnungen'];
    sheet.appendRow([
      TextCellValue('Nummer'),
      TextCellValue('Kunde'),
      TextCellValue('Datum'),
      TextCellValue('Fällig am'),
      TextCellValue('Status'),
      TextCellValue('Gesamtpreis'),
    ]);
    for (final r in rechnungen) {
      sheet.appendRow([
        TextCellValue(r.nummer),
        TextCellValue(r.kundeName),
        TextCellValue(_datum(r.datum)),
        TextCellValue(r.faelligAm != null ? _datum(r.faelligAm!) : ''),
        TextCellValue(r.status.label),
        DoubleCellValue(r.gesamtpreis),
      ]);
    }
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
    return _speichern(excel, 'rechnungen_export.xlsx');
  }

  static String _datum(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

extension _ElementAtOrNull<T> on List<T> {
  T? elementAtOrNull(int index) => index < length ? this[index] : null;
}
