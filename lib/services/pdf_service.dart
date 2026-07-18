import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/angebot.dart';
import '../models/firmeneinstellungen.dart';
import '../models/kunde.dart';
import '../models/rechnung.dart';

/// Erzeugt PDF-Dokumente für Angebote (und später Rechnungen).
class PdfService {
  static final _dunkel = PdfColor.fromHex('#0F2430');
  static final _grau = PdfColor.fromHex('#5A7180');
  static final _akzent = PdfColor.fromHex('#1C7ED6');
  static final _linie = PdfColor.fromHex('#DCE6EA');

  static String _datum(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _euro(double v) => '${v.toStringAsFixed(2)} €';

  static String _menge(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Baut das Angebots-PDF und gibt die Bytes zurück (zum Anzeigen,
  /// Drucken oder Teilen z.B. über das `printing`-Paket).
  static Future<Uint8List> angebotPdf({
    required Angebot angebot,
    required List<AngebotPosition> positionen,
    required Kunde kunde,
    required Firmeneinstellungen firma,
  }) async {
    final doc = pw.Document();

    final berechnung = AngebotBerechnung(
      zwischensumme: positionen.fold(0.0, (sum, p) => sum + p.gesamt),
      rabattProzent: angebot.rabattProzent,
      fahrtkosten: angebot.fahrtkosten,
      mwstProzent: angebot.mwstProzent,
    );

    final labelStyle = pw.TextStyle(fontSize: 9, color: _grau, letterSpacing: 0.5);
    final normalStyle = pw.TextStyle(fontSize: 10, color: _dunkel);
    final kleinStyle = pw.TextStyle(fontSize: 8.5, color: _grau);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(color: _linie),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  firma.iban != null
                      ? '${firma.firmenname} · IBAN ${firma.iban}${firma.bic != null ? ' · BIC ${firma.bic}' : ''}'
                      : firma.firmenname,
                  style: kleinStyle,
                ),
                pw.Text('Seite ${context.pageNumber} / ${context.pagesCount}', style: kleinStyle),
              ],
            ),
          ],
        ),
        build: (context) => [
          // ---------- Kopfzeile ----------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    firma.firmenname,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _dunkel),
                  ),
                  if (firma.iban != null) pw.SizedBox(height: 3),
                  if (firma.iban != null) pw.Text('IBAN: ${firma.iban}', style: kleinStyle),
                  if (firma.bic != null) pw.Text('BIC: ${firma.bic}', style: kleinStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('ANGEBOT',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _akzent)),
                  pw.SizedBox(height: 4),
                  pw.Text(angebot.nummer, style: normalStyle),
                  pw.Text('Datum: ${_datum(angebot.datum)}', style: kleinStyle),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 28),

          // ---------- Kunde ----------
          pw.Text('KUNDE', style: labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(kunde.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _dunkel)),
          if (kunde.adresseKompakt.isNotEmpty) pw.Text(kunde.adresseKompakt, style: normalStyle),
          if (kunde.telefon != null && kunde.telefon!.isNotEmpty)
            pw.Text('Tel: ${kunde.telefon}', style: normalStyle),
          if (kunde.email != null && kunde.email!.isNotEmpty)
            pw.Text(kunde.email!, style: normalStyle),

          pw.SizedBox(height: 26),

          // ---------- Positionstabelle ----------
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _linie, width: 0.6),
              bottom: pw.BorderSide(color: _linie, width: 0.6),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(3.2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _dunkel, width: 1)),
                ),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Pos.', style: labelStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Bezeichnung', style: labelStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Menge', style: labelStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Einzelpreis', style: labelStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Gesamt', style: labelStyle, textAlign: pw.TextAlign.right)),
                ],
              ),
              ...positionen.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final p = entry.value;
                return pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text('$i', style: normalStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(p.bezeichnung, style: normalStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(_menge(p.menge), style: normalStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(_euro(p.einzelpreis), style: normalStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(_euro(p.gesamt), style: normalStyle, textAlign: pw.TextAlign.right)),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 20),

          // ---------- Zusammenfassung ----------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _summenZeile('Zwischensumme', _euro(berechnung.zwischensumme), normalStyle),
                  _summenZeile(
                      '- Rabatt (${_menge(berechnung.rabattProzent)}%)',
                      '- ${_euro(berechnung.rabattBetrag)}',
                      normalStyle),
                  _summenZeile('+ Fahrtkosten', _euro(berechnung.fahrtkosten), normalStyle),
                  _summenZeile(
                      '+ MwSt. (${_menge(berechnung.mwstProzent)}%)',
                      _euro(berechnung.mwstBetrag),
                      normalStyle),
                  pw.Divider(color: _linie),
                  _summenZeile(
                    'Gesamtpreis',
                    _euro(berechnung.gesamtpreis),
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _akzent),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 36),
          pw.Text(
            'Dieses Angebot ist freibleibend und 30 Tage ab Ausstellungsdatum gültig. '
            'Alle Preise verstehen sich inkl. der ausgewiesenen Mehrwertsteuer.',
            style: kleinStyle,
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Baut das Rechnungs-PDF (analoger Aufbau wie das Angebot, aber mit
  /// Fälligkeitsdatum, Zahlungshinweis und ggf. "BEZAHLT"-Vermerk).
  static Future<Uint8List> rechnungPdf({
    required Rechnung rechnung,
    required List<RechnungPosition> positionen,
    required Kunde kunde,
    required Firmeneinstellungen firma,
  }) async {
    final doc = pw.Document();

    final berechnung = RechnungBerechnung(
      netto: positionen.fold(0.0, (sum, p) => sum + p.gesamt),
      mwstProzent: rechnung.mwstProzent,
    );

    final labelStyle = pw.TextStyle(fontSize: 9, color: _grau, letterSpacing: 0.5);
    final normalStyle = pw.TextStyle(fontSize: 10, color: _dunkel);
    final kleinStyle = pw.TextStyle(fontSize: 8.5, color: _grau);
    final gruen = PdfColor.fromHex('#198754');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(color: _linie),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  firma.iban != null
                      ? '${firma.firmenname} · IBAN ${firma.iban}${firma.bic != null ? ' · BIC ${firma.bic}' : ''}'
                      : firma.firmenname,
                  style: kleinStyle,
                ),
                pw.Text('Seite ${context.pageNumber} / ${context.pagesCount}', style: kleinStyle),
              ],
            ),
          ],
        ),
        build: (context) => [
          // ---------- Kopfzeile ----------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    firma.firmenname,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _dunkel),
                  ),
                  if (firma.iban != null) pw.SizedBox(height: 3),
                  if (firma.iban != null) pw.Text('IBAN: ${firma.iban}', style: kleinStyle),
                  if (firma.bic != null) pw.Text('BIC: ${firma.bic}', style: kleinStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('RECHNUNG',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _akzent)),
                  pw.SizedBox(height: 4),
                  pw.Text(rechnung.nummer, style: normalStyle),
                  pw.Text('Datum: ${_datum(rechnung.datum)}', style: kleinStyle),
                  if (rechnung.faelligAm != null)
                    pw.Text('Fällig am: ${_datum(rechnung.faelligAm!)}', style: kleinStyle),
                  if (rechnung.bezahlt)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: gruen,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text('BEZAHLT',
                            style: pw.TextStyle(
                                color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 28),

          // ---------- Kunde ----------
          pw.Text('KUNDE', style: labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(kunde.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _dunkel)),
          if (kunde.adresseKompakt.isNotEmpty) pw.Text(kunde.adresseKompakt, style: normalStyle),
          if (kunde.telefon != null && kunde.telefon!.isNotEmpty)
            pw.Text('Tel: ${kunde.telefon}', style: normalStyle),
          if (kunde.email != null && kunde.email!.isNotEmpty)
            pw.Text(kunde.email!, style: normalStyle),

          pw.SizedBox(height: 26),

          // ---------- Positionstabelle ----------
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _linie, width: 0.6),
              bottom: pw.BorderSide(color: _linie, width: 0.6),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(3.2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _dunkel, width: 1)),
                ),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Pos.', style: labelStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Bezeichnung', style: labelStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Menge', style: labelStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Einzelpreis', style: labelStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text('Gesamt', style: labelStyle, textAlign: pw.TextAlign.right)),
                ],
              ),
              ...positionen.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final p = entry.value;
                return pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text('$i', style: normalStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(p.bezeichnung, style: normalStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(_menge(p.menge), style: normalStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(_euro(p.einzelpreis), style: normalStyle, textAlign: pw.TextAlign.right)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(_euro(p.gesamt), style: normalStyle, textAlign: pw.TextAlign.right)),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 20),

          // ---------- Zusammenfassung ----------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _summenZeile('Nettosumme', _euro(berechnung.netto), normalStyle),
                  _summenZeile(
                      '+ MwSt. (${_menge(berechnung.mwstProzent)}%)',
                      _euro(berechnung.mwstBetrag),
                      normalStyle),
                  pw.Divider(color: _linie),
                  _summenZeile(
                    'Rechnungsbetrag',
                    _euro(berechnung.gesamtpreis),
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _akzent),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 36),
          pw.Text(
            rechnung.bezahlt
                ? 'Vielen Dank, der Rechnungsbetrag ist bereits eingegangen.'
                : 'Bitte überweisen Sie den Rechnungsbetrag bis zum '
                    '${rechnung.faelligAm != null ? _datum(rechnung.faelligAm!) : "s.o."} '
                    'unter Angabe der Rechnungsnummer auf das oben genannte Konto.',
            style: kleinStyle,
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summenZeile(String label, String wert, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(wert, style: style),
        ],
      ),
    );
  }
}
