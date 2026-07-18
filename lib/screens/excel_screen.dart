import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/angebote_repository.dart';
import '../data/geraete_repository.dart';
import '../data/material_repository.dart';
import '../data/rechnungen_repository.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class ExcelScreen extends StatefulWidget {
  const ExcelScreen({super.key});

  @override
  State<ExcelScreen> createState() => _ExcelScreenState();
}

class _ExcelScreenState extends State<ExcelScreen> {
  final _geraeteRepo = GeraeteRepository();
  final _materialRepo = MaterialRepository();
  final _angeboteRepo = AngeboteRepository();
  final _rechnungenRepo = RechnungenRepository();

  bool _isBusy = false;
  String? _aktuelleAktion;

  Future<void> _run(String label, Future<void> Function() aktion) async {
    setState(() {
      _isBusy = true;
      _aktuelleAktion = label;
    });
    try {
      // ignore: avoid_print
      print('EXCEL DEBUG: starting $label');
      await aktion();
      // ignore: avoid_print
      print('EXCEL DEBUG: finished $label');
    } catch (e, st) {
      // ignore: avoid_print
      print('EXCEL DEBUG: error in $label: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _teilen(String path, String name) async {
    await Share.shareXFiles([XFile(path)], text: name);
  }

  Future<void> _exportGeraete() => _run('Export Geräte …', () async {
        final geraete = await _geraeteRepo.alle();
        final path = await ExcelService.exportGeraete(geraete);
        await _teilen(path, 'Geräte-Export');
      });

  Future<void> _exportMaterial() => _run('Export Material …', () async {
        final material = await _materialRepo.alle();
        final path = await ExcelService.exportMaterial(material);
        await _teilen(path, 'Material-Export');
      });

  Future<void> _exportLagerbestand() => _run('Export Lagerbestand …', () async {
        final geraete = await _geraeteRepo.alle();
        final material = await _materialRepo.alle();
        final path = await ExcelService.exportLagerbestand(geraete, material);
        await _teilen(path, 'Lagerbestand-Export');
      });

  Future<void> _exportAngebote() => _run('Export Angebote …', () async {
        final angebote = await _angeboteRepo.uebersicht();
        final path = await ExcelService.exportAngebote(angebote);
        await _teilen(path, 'Angebote-Export');
      });

  Future<void> _exportRechnungen() => _run('Export Rechnungen …', () async {
        final rechnungen = await _rechnungenRepo.uebersicht();
        final path = await ExcelService.exportRechnungen(rechnungen);
        await _teilen(path, 'Rechnungen-Export');
      });

  Future<void> _importGeraete() => _run('Import Geräte …', () async {
        final datei = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        final path = datei?.files.single.path;
        if (path == null) return;

        final geraete = await ExcelService.importGeraete(path);
        for (final g in geraete) {
          await _geraeteRepo.anlegen(g);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${geraete.length} Geräte importiert.')));
      });

  Future<void> _importMaterial() => _run('Import Material …', () async {
        final datei = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        final path = datei?.files.single.path;
        if (path == null) return;

        final material = await ExcelService.importMaterial(path);
        for (final m in material) {
          await _materialRepo.anlegen(m);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${material.length} Material-Artikel importiert.')));
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excel Import/Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isBusy)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(_aktuelleAktion ?? '', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          const _Ueberschrift('Export'),
          _AktionsKarte(
            icon: Icons.ac_unit,
            titel: 'Geräte exportieren',
            beschreibung: 'Artikel, Hersteller, Preise, Lagerbestand als .xlsx',
            onTap: _isBusy ? null : _exportGeraete,
          ),
          _AktionsKarte(
            icon: Icons.category_outlined,
            titel: 'Material exportieren',
            beschreibung: 'Artikel, Einheit, Preis, Lagerbestand als .xlsx',
            onTap: _isBusy ? null : _exportMaterial,
          ),
          _AktionsKarte(
            icon: Icons.inventory_2_outlined,
            titel: 'Lagerbestand exportieren',
            beschreibung: 'Geräte & Material kombiniert, inkl. Mindestbestand-Warnung',
            onTap: _isBusy ? null : _exportLagerbestand,
          ),
          _AktionsKarte(
            icon: Icons.description_outlined,
            titel: 'Angebote exportieren',
            beschreibung: 'Übersicht aller Angebote mit Status & Gesamtpreis',
            onTap: _isBusy ? null : _exportAngebote,
          ),
          _AktionsKarte(
            icon: Icons.receipt_long_outlined,
            titel: 'Rechnungen exportieren',
            beschreibung: 'Übersicht aller Rechnungen mit Status & Gesamtpreis',
            onTap: _isBusy ? null : _exportRechnungen,
          ),
          const SizedBox(height: 12),
          const _Ueberschrift('Import'),
          _AktionsKarte(
            icon: Icons.upload_file_outlined,
            titel: 'Geräte importieren',
            beschreibung: 'Erwartet dieselben Spalten wie beim Export',
            onTap: _isBusy ? null : _importGeraete,
          ),
          _AktionsKarte(
            icon: Icons.upload_file_outlined,
            titel: 'Material importieren',
            beschreibung: 'Erwartet dieselben Spalten wie beim Export',
            onTap: _isBusy ? null : _importMaterial,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Tipp: Beim Import werden Zeilen ohne Artikel-Namen übersprungen. '
              'Bestehende Artikel werden nicht überschrieben, sondern als neue '
              'Einträge angelegt — bei erneutem Import ggf. vorher bestehende '
              'Duplikate manuell entfernen.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ueberschrift extends StatelessWidget {
  final String text;
  const _Ueberschrift(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.3),
      ),
    );
  }
}

class _AktionsKarte extends StatelessWidget {
  final IconData icon;
  final String titel;
  final String beschreibung;
  final VoidCallback? onTap;

  const _AktionsKarte({
    required this.icon,
    required this.titel,
    required this.beschreibung,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(titel, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(beschreibung, style: const TextStyle(fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
