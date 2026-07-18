import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/angebote_repository.dart';
import '../data/einstellungen_repository.dart';
import '../data/kunden_repository.dart';
import '../data/rechnungen_repository.dart';
import '../models/kunde.dart';
import '../models/rechnung.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rechnung_position_dialog.dart';

class RechnungFormScreen extends StatefulWidget {
  final int? rechnungId; // gesetzt = bestehende Rechnung bearbeiten
  final int? ausAngebotId; // gesetzt = neue Rechnung aus Angebot erzeugen

  const RechnungFormScreen({super.key, this.rechnungId, this.ausAngebotId});

  @override
  State<RechnungFormScreen> createState() => _RechnungFormScreenState();
}

class _RechnungFormScreenState extends State<RechnungFormScreen> {
  final _rechnungenRepo = RechnungenRepository();
  final _kundenRepo = KundenRepository();
  final _angeboteRepo = AngeboteRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPdfLoading = false;
  bool get _isEdit => widget.rechnungId != null;

  List<Kunde> _kunden = [];
  Kunde? _gewaehlterKunde;
  final List<RechnungPosition> _positionen = [];

  String? _nummer;
  DateTime? _faelligAm;
  bool _bezahlt = false;
  DateTime? _bezahltAm;
  final _mwstController = TextEditingController(text: '19');

  @override
  void initState() {
    super.initState();
    _initialisieren();
  }

  @override
  void dispose() {
    _mwstController.dispose();
    super.dispose();
  }

  Future<void> _initialisieren() async {
    _kunden = await _kundenRepo.alle();

    if (_isEdit) {
      final rechnung = await _rechnungenRepo.byId(widget.rechnungId!);
      final positionen = await _rechnungenRepo.positionenFuer(widget.rechnungId!);
      if (rechnung != null) {
        _nummer = rechnung.nummer;
        _faelligAm = rechnung.faelligAm;
        _bezahlt = rechnung.bezahlt;
        _bezahltAm = rechnung.bezahltAm;
        _mwstController.text = _fmt(rechnung.mwstProzent);
        _gewaehlterKunde = _kunden.where((k) => k.id == rechnung.kundeId).firstOrNull;
        _positionen.addAll(positionen);
      }
    } else {
      _nummer = await _rechnungenRepo.naechsteNummer();
      _faelligAm = DateTime.now().add(const Duration(days: 14));

      if (widget.ausAngebotId != null) {
        // Aus einem angenommenen Angebot erzeugen: Positionen + Fahrtkosten/
        // Rabatt als zusätzliche Positionen übernehmen, MwSt. übernehmen.
        final angebot = await _angeboteRepo.byId(widget.ausAngebotId!);
        final angebotPositionen = await _angeboteRepo.positionenFuer(widget.ausAngebotId!);
        if (angebot != null) {
          _gewaehlterKunde =
              _kunden.where((k) => k.id == angebot.kundeId).firstOrNull;
          _mwstController.text = _fmt(angebot.mwstProzent);

          for (final p in angebotPositionen) {
            _positionen.add(RechnungPosition(
              bezeichnung: p.bezeichnung,
              menge: p.menge,
              einzelpreis: p.einzelpreis,
            ));
          }
          if (angebot.rabattProzent > 0) {
            final netto = angebotPositionen.fold(0.0, (s, p) => s + p.gesamt);
            final rabattBetrag = netto * (angebot.rabattProzent / 100);
            _positionen.add(RechnungPosition(
              bezeichnung: 'Rabatt (${_fmt(angebot.rabattProzent)}%)',
              menge: 1,
              einzelpreis: -rabattBetrag,
            ));
          }
          if (angebot.fahrtkosten > 0) {
            _positionen.add(RechnungPosition(
              bezeichnung: 'Fahrtkosten',
              menge: 1,
              einzelpreis: angebot.fahrtkosten,
            ));
          }
        }
      } else if (_kunden.isNotEmpty) {
        _gewaehlterKunde = _kunden.first;
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  double _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  RechnungBerechnung get _berechnung => RechnungBerechnung(
        netto: _positionen.fold(0.0, (sum, p) => sum + p.gesamt),
        mwstProzent: _parseDouble(_mwstController.text),
      );

  Future<void> _positionHinzufuegen() async {
    final neu = await showDialog<RechnungPosition>(
      context: context,
      builder: (_) => const RechnungPositionDialog(),
    );
    if (neu != null) setState(() => _positionen.add(neu));
  }

  Future<void> _positionBearbeiten(int index) async {
    final bearbeitet = await showDialog<RechnungPosition>(
      context: context,
      builder: (_) => RechnungPositionDialog(position: _positionen[index]),
    );
    if (bearbeitet != null) setState(() => _positionen[index] = bearbeitet);
  }

  Future<void> _faelligAmWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _faelligAm ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (gewaehlt != null) setState(() => _faelligAm = gewaehlt);
  }

  void _zahlungTogglen(bool wert) {
    setState(() {
      _bezahlt = wert;
      _bezahltAm = wert ? DateTime.now() : null;
    });
  }

  Future<void> _speichern() async {
    if (_gewaehlterKunde == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte einen Kunden auswählen')));
      return;
    }
    if (_positionen.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte mindestens eine Position hinzufügen')));
      return;
    }

    setState(() => _isSaving = true);
    final b = _berechnung;

    final rechnung = Rechnung(
      id: widget.rechnungId,
      nummer: _nummer!,
      kundeId: _gewaehlterKunde!.id!,
      datum: DateTime.now(),
      faelligAm: _faelligAm,
      mwstProzent: b.mwstProzent,
      gesamtpreis: b.gesamtpreis,
      bezahlt: _bezahlt,
      bezahltAm: _bezahltAm,
    );

    try {
      if (_isEdit) {
        await _rechnungenRepo.aktualisierenMitPositionen(rechnung, _positionen);
      } else {
        await _rechnungenRepo.anlegenMitPositionen(rechnung, _positionen);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pdfExport() async {
    if (_gewaehlterKunde == null || _positionen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst Kunde und Positionen ausfüllen')),
      );
      return;
    }

    setState(() => _isPdfLoading = true);
    try {
      final firma = await EinstellungenRepository().laden();
      final b = _berechnung;

      final rechnungFuerPdf = Rechnung(
        id: widget.rechnungId,
        nummer: _nummer!,
        kundeId: _gewaehlterKunde!.id ?? 0,
        datum: DateTime.now(),
        faelligAm: _faelligAm,
        mwstProzent: b.mwstProzent,
        gesamtpreis: b.gesamtpreis,
        bezahlt: _bezahlt,
        bezahltAm: _bezahltAm,
      );

      final bytes = await PdfService.rechnungPdf(
        rechnung: rechnungFuerPdf,
        positionen: _positionen,
        kunde: _gewaehlterKunde!,
        firma: firma,
      );

      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: '${_nummer ?? 'Rechnung'}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler bei der PDF-Erzeugung: $e')));
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final b = _berechnung;
    final waehrung = (double v) => '${v.toStringAsFixed(2)} €';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Rechnung $_nummer' : 'Neue Rechnung'),
        actions: [
          IconButton(
            icon: _isPdfLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF erzeugen',
            onPressed: _isPdfLoading ? null : _pdfExport,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (!_isEdit)
            Text('Rechnungsnummer: $_nummer', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          if (!_isEdit) const SizedBox(height: 12),

          const _SectionLabel('Kunde'),
          _kunden.isEmpty
              ? const Text('Noch keine Kunden angelegt.', style: TextStyle(color: AppTheme.danger))
              : DropdownButtonFormField<Kunde>(
                  initialValue: _gewaehlterKunde,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kunde auswählen'),
                  items: _kunden
                      .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(
                              k.ort != null && k.ort!.isNotEmpty ? '${k.name} · ${k.ort}' : k.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (k) => setState(() => _gewaehlterKunde = k),
                ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Positionen'),
              TextButton.icon(
                onPressed: _positionHinzufuegen,
                icon: const Icon(Icons.add),
                label: const Text('Hinzufügen'),
              ),
            ],
          ),
          if (_positionen.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Noch keine Positionen. Übernimm sie aus einem Angebot oder füge sie manuell hinzu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...List.generate(_positionen.length, (i) {
              final p = _positionen[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  onTap: () => _positionBearbeiten(i),
                  title: Text(p.bezeichnung, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${p.menge.toStringAsFixed(p.menge == p.menge.roundToDouble() ? 0 : 2)} × ${waehrung(p.einzelpreis)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(waehrung(p.gesamt), style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _positionen.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          const _SectionLabel('Fälligkeit, MwSt. & Zahlung'),
          InkWell(
            onTap: _faelligAmWaehlen,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Fällig am'),
              child: Text(
                _faelligAm != null
                    ? '${_faelligAm!.day.toString().padLeft(2, '0')}.${_faelligAm!.month.toString().padLeft(2, '0')}.${_faelligAm!.year}'
                    : 'Kein Datum gewählt',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mwstController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'MwSt. (%)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Zahlung eingegangen'),
            subtitle: _bezahlt && _bezahltAm != null
                ? Text('Bezahlt am ${_bezahltAm!.day.toString().padLeft(2, '0')}.'
                    '${_bezahltAm!.month.toString().padLeft(2, '0')}.${_bezahltAm!.year}')
                : null,
            value: _bezahlt,
            activeColor: AppTheme.success,
            onChanged: _zahlungTogglen,
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                _SummenZeile('Nettosumme', waehrung(b.netto)),
                _SummenZeile('+ MwSt. (${_fmt(b.mwstProzent)}%)', waehrung(b.mwstBetrag)),
                const Divider(height: 20),
                _SummenZeile('Rechnungsbetrag', waehrung(b.gesamtpreis), fett: true),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _speichern,
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: Text(_isEdit ? 'Änderungen speichern' : 'Rechnung speichern'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isPdfLoading ? null : _pdfExport,
            icon: _isPdfLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF erzeugen'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.3),
      ),
    );
  }
}

class _SummenZeile extends StatelessWidget {
  final String label;
  final String wert;
  final bool fett;
  const _SummenZeile(this.label, this.wert, {this.fett = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: fett ? FontWeight.w800 : FontWeight.w500,
      fontSize: fett ? 17 : 14,
      color: fett ? AppTheme.primary : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(wert, style: style)],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
