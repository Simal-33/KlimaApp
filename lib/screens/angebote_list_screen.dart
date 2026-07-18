import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/angebote_repository.dart';
import '../data/einstellungen_repository.dart';
import '../data/kunden_repository.dart';
import '../models/angebot.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import 'angebot_form_screen.dart';

class AngeboteListScreen extends StatefulWidget {
  const AngeboteListScreen({super.key});

  @override
  State<AngeboteListScreen> createState() => _AngeboteListScreenState();
}

class _AngeboteListScreenState extends State<AngeboteListScreen> {
  final _repo = AngeboteRepository();
  final _kundenRepo = KundenRepository();
  List<AngebotUebersicht> _angebote = [];
  bool _isLoading = true;
  int? _pdfLadendId;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final angebote = await _repo.uebersicht();
    if (!mounted) return;
    setState(() {
      _angebote = angebote;
      _isLoading = false;
    });
  }

  Future<void> _oeffnen({int? angebotId}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AngebotFormScreen(angebotId: angebotId)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(AngebotUebersicht angebot) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Angebot löschen?'),
        content: Text('Angebot ${angebot.nummer} wird unwiderruflich gelöscht.'),
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
      await _repo.loeschen(angebot.id);
      _laden();
    }
  }

  Future<void> _pdfExport(AngebotUebersicht uebersicht) async {
    setState(() => _pdfLadendId = uebersicht.id);
    try {
      final angebot = await _repo.byId(uebersicht.id);
      if (angebot == null) return;
      final positionen = await _repo.positionenFuer(uebersicht.id);
      final kunde = await _kundenRepo.byId(angebot.kundeId);
      if (kunde == null) return;
      final firma = await EinstellungenRepository().laden();

      final bytes = await PdfService.angebotPdf(
        angebot: angebot,
        positionen: positionen,
        kunde: kunde,
        firma: firma,
      );

      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: '${angebot.nummer}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler bei der PDF-Erzeugung: $e')));
    } finally {
      if (mounted) setState(() => _pdfLadendId = null);
    }
  }

  Color _farbeFuerStatus(AngebotStatus s) => switch (s) {
        AngebotStatus.offen => AppTheme.primary,
        AngebotStatus.angenommen => AppTheme.success,
        AngebotStatus.abgelehnt => AppTheme.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Angebote')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffnen(),
        icon: const Icon(Icons.add),
        label: const Text('Neues Angebot'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _angebote.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 56, color: Colors.black26),
                        const SizedBox(height: 12),
                        const Text(
                          'Noch keine Angebote erstellt.\nTippe unten rechts auf "Neues Angebot".',
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
                    itemCount: _angebote.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final a = _angebote[index];
                      final farbe = _farbeFuerStatus(a.status);
                      return Dismissible(
                        key: ValueKey(a.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          _loeschen(a);
                          return false;
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        child: Card(
                          child: ListTile(
                            onTap: () => _oeffnen(angebotId: a.id),
                            title: Text(a.nummer, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              '${a.kundeName} · ${a.datum.day.toString().padLeft(2, '0')}.'
                              '${a.datum.month.toString().padLeft(2, '0')}.${a.datum.year}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${a.gesamtpreis.toStringAsFixed(2)} €',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: farbe.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        a.status.label,
                                        style: TextStyle(
                                            color: farbe, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                _pdfLadendId == a.id
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
                                        onPressed: () => _pdfExport(a),
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
