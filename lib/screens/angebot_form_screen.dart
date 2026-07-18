import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/angebote_repository.dart';
import '../data/einstellungen_repository.dart';
import '../data/geraete_repository.dart';
import '../data/kunden_repository.dart';
import '../data/material_repository.dart';
import '../models/angebot.dart';
import '../models/kunde.dart';
import '../services/pdf_service.dart';
import 'rechnung_form_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/fahrtkosten_rechner_dialog.dart';
import '../widgets/position_hinzufuegen_sheet.dart';

class AngebotFormScreen extends StatefulWidget {
  final int? angebotId; // null = neues Angebot

  const AngebotFormScreen({super.key, this.angebotId});

  @override
  State<AngebotFormScreen> createState() => _AngebotFormScreenState();
}

class _AngebotFormScreenState extends State<AngebotFormScreen> {
  final _angeboteRepo = AngeboteRepository();
  final _kundenRepo = KundenRepository();
  final _geraeteRepo = GeraeteRepository();
  final _materialRepo = MaterialRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  bool get _isEdit => widget.angebotId != null;

  List<Kunde> _kunden = [];
  Kunde? _gewaehlterKunde;
  final List<AngebotPosition> _positionen = [];

  String? _nummer;
  AngebotStatus _status = AngebotStatus.offen;
  final _rabattController = TextEditingController(text: '0');
  final _fahrtkostenController = TextEditingController(text: '0');
  final _mwstController = TextEditingController(text: '19');

  @override
  void initState() {
    super.initState();
    _initialisieren();
  }

  @override
  void dispose() {
    _rabattController.dispose();
    _fahrtkostenController.dispose();
    _mwstController.dispose();
    super.dispose();
  }

  Future<void> _initialisieren() async {
    _kunden = await _kundenRepo.alle();

    if (_isEdit) {
      final angebot = await _angeboteRepo.byId(widget.angebotId!);
      final positionen = await _angeboteRepo.positionenFuer(widget.angebotId!);
      if (angebot != null) {
        _nummer = angebot.nummer;
        _status = angebot.status;
        _rabattController.text = _fmt(angebot.rabattProzent);
        _fahrtkostenController.text = _fmt(angebot.fahrtkosten);
        _mwstController.text = _fmt(angebot.mwstProzent);
        _gewaehlterKunde = _kunden.where((k) => k.id == angebot.kundeId).firstOrNull;
        _positionen.addAll(positionen);
      }
    } else {
      _nummer = await _angeboteRepo.naechsteNummer();
      if (_kunden.isNotEmpty) _gewaehlterKunde = _kunden.first;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  AngebotBerechnung get _berechnung => AngebotBerechnung(
        zwischensumme: _positionen.fold(0.0, (sum, p) => sum + p.gesamt),
        rabattProzent: _parseDouble(_rabattController.text),
        fahrtkosten: _parseDouble(_fahrtkostenController.text),
        mwstProzent: _parseDouble(_mwstController.text),
      );

  Future<void> _positionHinzufuegen() async {
    final geraete = await _geraeteRepo.alle();
    final material = await _materialRepo.alle();
    if (!mounted) return;

    final neuePosition = await showModalBottomSheet<AngebotPosition>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PositionHinzufuegenSheet(geraete: geraete, material: material),
    );

    if (neuePosition != null) {
      setState(() => _positionen.add(neuePosition));
    }
  }

  Future<void> _fahrtkostenRechner() async {
    final ergebnis = await showDialog<double>(
      context: context,
      builder: (_) => const FahrtkostenRechnerDialog(),
    );
    if (ergebnis != null) {
      setState(() => _fahrtkostenController.text = _fmt(ergebnis));
    }
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

    final angebot = Angebot(
      id: widget.angebotId,
      nummer: _nummer!,
      kundeId: _gewaehlterKunde!.id!,
      datum: DateTime.now(),
      mwstProzent: b.mwstProzent,
      rabattProzent: b.rabattProzent,
      fahrtkosten: b.fahrtkosten,
      status: _status,
      gesamtpreis: b.gesamtpreis,
    );

    try {
      if (_isEdit) {
        await _angeboteRepo.aktualisierenMitPositionen(angebot, _positionen);
      } else {
        await _angeboteRepo.anlegenMitPositionen(angebot, _positionen);
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

  bool _isPdfLoading = false;

  Future<void> _pdfExport() async {
    if (_gewaehlterKunde == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte zuerst einen Kunden auswählen')));
      return;
    }
    if (_positionen.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte zuerst mindestens eine Position hinzufügen')));
      return;
    }

    setState(() => _isPdfLoading = true);
    try {
      final firma = await EinstellungenRepository().laden();
      final b = _berechnung;

      final angebotFuerPdf = Angebot(
        id: widget.angebotId,
        nummer: _nummer!,
        kundeId: _gewaehlterKunde!.id ?? 0,
        datum: DateTime.now(),
        mwstProzent: b.mwstProzent,
        rabattProzent: b.rabattProzent,
        fahrtkosten: b.fahrtkosten,
        status: _status,
        gesamtpreis: b.gesamtpreis,
      );

      final bytes = await PdfService.angebotPdf(
        angebot: angebotFuerPdf,
        positionen: _positionen,
        kunde: _gewaehlterKunde!,
        firma: firma,
      );

      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: '${_nummer ?? 'Angebot'}.pdf',
      );
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
        title: Text(_isEdit ? 'Angebot $_nummer' : 'Neues Angebot'),
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
            Text('Angebotsnummer: $_nummer',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          if (!_isEdit) const SizedBox(height: 12),

          // ---------- Kunde ----------
          const _SectionLabel('Kunde'),
          _kunden.isEmpty
              ? const Text(
                  'Noch keine Kunden angelegt. Bitte zuerst im Kunden-Modul einen Kunden anlegen.',
                  style: TextStyle(color: AppTheme.danger),
                )
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

          // ---------- Positionen ----------
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
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Noch keine Positionen. Füge Geräte, Material, Arbeitszeit oder freie Posten hinzu.',
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
                  leading: Icon(_iconFuerTyp(p.typ), color: AppTheme.primary),
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

          // ---------- Fahrtkosten / Rabatt / MwSt ----------
          const _SectionLabel('Fahrtkosten, Rabatt & MwSt'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fahrtkostenController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Fahrtkosten (€)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calculate_outlined),
                tooltip: 'Aus Entfernung berechnen',
                onPressed: _fahrtkostenRechner,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rabattController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rabatt (%)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _mwstController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'MwSt. (%)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ---------- Status (nur beim Bearbeiten sichtbar) ----------
          if (_isEdit) ...[
            const _SectionLabel('Status'),
            Wrap(
              spacing: 8,
              children: AngebotStatus.values.map((s) {
                final aktiv = _status == s;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: aktiv,
                  onSelected: (_) => setState(() => _status = s),
                  selectedColor: _farbeFuerStatus(s).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: aktiv ? _farbeFuerStatus(s) : Colors.black87,
                    fontWeight: aktiv ? FontWeight.w700 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            if (_status == AngebotStatus.angenommen) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RechnungFormScreen(ausAngebotId: widget.angebotId),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Rechnung aus diesem Angebot erstellen'),
              ),
            ],
            const SizedBox(height: 24),
          ],

          // ---------- Zusammenfassung ----------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                _SummenZeile('Zwischensumme', waehrung(b.zwischensumme)),
                _SummenZeile('- Rabatt (${_fmt(b.rabattProzent)}%)', '- ${waehrung(b.rabattBetrag)}'),
                _SummenZeile('+ Fahrtkosten', waehrung(b.fahrtkosten)),
                _SummenZeile('+ MwSt. (${_fmt(b.mwstProzent)}%)', waehrung(b.mwstBetrag)),
                const Divider(height: 20),
                _SummenZeile('Gesamtpreis', waehrung(b.gesamtpreis), fett: true),
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
            label: Text(_isEdit ? 'Änderungen speichern' : 'Angebot speichern'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isPdfLoading ? null : _pdfExport,
            icon: _isPdfLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF erzeugen'),
          ),
        ],
      ),
    );
  }

  IconData _iconFuerTyp(PositionsTyp typ) => switch (typ) {
        PositionsTyp.geraet => Icons.ac_unit,
        PositionsTyp.material => Icons.category_outlined,
        PositionsTyp.arbeitszeit => Icons.schedule_outlined,
        PositionsTyp.frei => Icons.edit_note_outlined,
      };

  Color _farbeFuerStatus(AngebotStatus s) => switch (s) {
        AngebotStatus.offen => AppTheme.primary,
        AngebotStatus.angenommen => AppTheme.success,
        AngebotStatus.abgelehnt => AppTheme.danger,
      };
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
          letterSpacing: 0.3,
        ),
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
        children: [
          Text(label, style: style),
          Text(wert, style: style),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
