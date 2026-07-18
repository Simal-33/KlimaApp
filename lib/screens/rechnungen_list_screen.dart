import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/einstellungen_repository.dart';
import '../data/kunden_repository.dart';
import '../data/rechnungen_repository.dart';
import '../models/rechnung.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import 'angebot_fuer_rechnung_auswahl_screen.dart';
import 'rechnung_form_screen.dart';

class RechnungenListScreen extends StatefulWidget {
  const RechnungenListScreen({super.key});

  @override
  State<RechnungenListScreen> createState() => _RechnungenListScreenState();
}

class _RechnungenListScreenState extends State<RechnungenListScreen> {
  final _repo = RechnungenRepository();
  final _kundenRepo = KundenRepository();
  List<RechnungUebersicht> _rechnungen = [];
  bool _isLoading = true;
  int? _pdfLadendId;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final rechnungen = await _repo.uebersicht();
    if (!mounted) return;
    setState(() {
      _rechnungen = rechnungen;
      _isLoading = false;
    });
  }

  Future<void> _neueRechnung() async {
    final auswahl = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Neue Rechnung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppTheme.primary),
              title: const Text('Aus angenommenem Angebot'),
              subtitle: const Text('Übernimmt Kunde, Positionen, Fahrtkosten & Rabatt'),
              onTap: () => Navigator.pop(ctx, 'angebot'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined, color: AppTheme.primary),
              title: const Text('Manuell erstellen'),
              onTap: () => Navigator.pop(ctx, 'manuell'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (auswahl == 'manuell') {
      await _oeffnen();
    } else if (auswahl == 'angebot') {
      if (!mounted) return;
      final angebotId = await Navigator.of(context).push<int>(
        MaterialPageRoute(builder: (_) => const AngebotFuerRechnungAuswahlScreen()),
      );
      if (angebotId != null) {
        await _oeffnen(ausAngebotId: angebotId);
      }
    }
  }

  Future<void> _oeffnen({int? rechnungId, int? ausAngebotId}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RechnungFormScreen(rechnungId: rechnungId, ausAngebotId: ausAngebotId),
      ),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(RechnungUebersicht rechnung) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechnung löschen?'),
        content: Text('Rechnung ${rechnung.nummer} wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (bestaetigt == true) {
      await _repo.loeschen(rechnung.id);
      _laden();
    }
  }

  Future<void> _zahlungTogglen(RechnungUebersicht rechnung) async {
    if (rechnung.bezahlt) {
      await _repo.zahlungZuruecksetzen(rechnung.id);
    } else {
      await _repo.alsBezahltMarkieren(rechnung.id);
    }
    _laden();
  }

  Future<void> _pdfExport(RechnungUebersicht uebersicht) async {
    setState(() => _pdfLadendId = uebersicht.id);
    try {
      final rechnung = await _repo.byId(uebersicht.id);
      if (rechnung == null) return;
      final positionen = await _repo.positionenFuer(uebersicht.id);
      final kunde = await _kundenRepo.byId(rechnung.kundeId);
      if (kunde == null) return;
      final firma = await EinstellungenRepository().laden();

      final bytes = await PdfService.rechnungPdf(
        rechnung: rechnung,
        positionen: positionen,
        kunde: kunde,
        firma: firma,
      );

      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: '${rechnung.nummer}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler bei der PDF-Erzeugung: $e')));
    } finally {
      if (mounted) setState(() => _pdfLadendId = null);
    }
  }

  Color _farbeFuerStatus(RechnungStatus s) => switch (s) {
        RechnungStatus.offen => AppTheme.primary,
        RechnungStatus.ueberfaellig => AppTheme.danger,
        RechnungStatus.bezahlt => AppTheme.success,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechnungen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neueRechnung,
        icon: const Icon(Icons.add),
        label: const Text('Neue Rechnung'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rechnungen.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.black26),
                        const SizedBox(height: 12),
                        const Text(
                          'Noch keine Rechnungen erstellt.\nTippe unten rechts auf "Neue Rechnung".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _laden,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                    itemCount: _rechnungen.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = _rechnungen[index];
                      final farbe = _farbeFuerStatus(r.status);
                      return Dismissible(
                        key: ValueKey(r.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          _loeschen(r);
                          return false;
                        },
                        background: Container(
                          decoration:
                              BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        child: Card(
                          child: ListTile(
                            onTap: () => _oeffnen(rechnungId: r.id),
                            title: Text(r.nummer, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              r.faelligAm != null
                                  ? '${r.kundeName} · fällig ${r.faelligAm!.day.toString().padLeft(2, '0')}.'
                                      '${r.faelligAm!.month.toString().padLeft(2, '0')}.${r.faelligAm!.year}'
                                  : r.kundeName,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${r.gesamtpreis.toStringAsFixed(2)} €',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _zahlungTogglen(r),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: farbe.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          r.status.label,
                                          style: TextStyle(
                                              color: farbe, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                _pdfLadendId == r.id
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(2),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.picture_as_pdf_outlined,
                                            color: AppTheme.primary, size: 20),
                                        tooltip: 'PDF erzeugen',
                                        onPressed: () => _pdfExport(r),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
