import 'package:flutter/material.dart';
import '../data/angebote_repository.dart';
import '../data/auftraege_repository.dart';
import '../data/kunden_repository.dart';
import '../data/monteure_repository.dart';
import '../models/angebot.dart';
import '../models/auftrag.dart';
import '../models/kunde.dart';
import '../models/monteur.dart';

class AuftragFormScreen extends StatefulWidget {
  final int? auftragId;

  const AuftragFormScreen({super.key, this.auftragId});

  @override
  State<AuftragFormScreen> createState() => _AuftragFormScreenState();
}

class _AuftragFormScreenState extends State<AuftragFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AuftraegeRepository();

  List<Kunde> _kunden = [];
  List<Monteur> _monteure = [];
  List<AngebotUebersicht> _angebote = [];
  bool _isLoading = true;
  bool _isSaving = false;

  int? _kundeId;
  int? _monteurId;
  int? _angebotId;
  DateTime? _termin;
  AuftragStatus _status = AuftragStatus.geplant;

  bool get _isEdit => widget.auftragId != null;

  Monteur? get _gewaehlterMonteur {
    if (_monteurId == null) return null;
    for (final monteur in _monteure) {
      if (monteur.id == _monteurId) return monteur;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    final kunden = await KundenRepository().alle();
    final monteure = await MonteureRepository().alle();
    final angebote = await AngeboteRepository().uebersicht();

    Auftrag? auftrag;
    if (_isEdit) {
      auftrag = await _repo.byId(widget.auftragId!);
    }

    if (!mounted) return;
    setState(() {
      _kunden = kunden;
      _monteure = monteure;
      _angebote = angebote
          .where((a) => a.status == AngebotStatus.angenommen)
          .toList();
      _kundeId = auftrag?.kundeId;
      _monteurId = auftrag?.monteurId;
      _angebotId = auftrag?.angebotId;
      _termin = auftrag?.termin;
      _status = auftrag?.status ?? AuftragStatus.geplant;
      _isLoading = false;
    });
  }

  Future<void> _terminWaehlen() async {
    final jetzt = DateTime.now();
    final initialDate = _termin ?? jetzt;
    final datum = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(jetzt.year - 1),
      lastDate: DateTime(jetzt.year + 5),
    );
    if (datum == null || !mounted) return;
    setState(() => _termin = datum);
  }

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kundeId == null) return;

    setState(() => _isSaving = true);
    final auftrag = Auftrag(
      id: widget.auftragId,
      angebotId: _angebotId,
      kundeId: _kundeId!,
      status: _status,
      termin: _termin,
      monteurId: _monteurId,
    );

    try {
      if (_isEdit) {
        await _repo.aktualisieren(auftrag);
      } else {
        await _repo.anlegen(auftrag);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _datumText(DateTime? datum) {
    if (datum == null) return 'Termin auswählen';
    return '${datum.day.toString().padLeft(2, '0')}.'
        '${datum.month.toString().padLeft(2, '0')}.${datum.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Auftrag bearbeiten' : 'Neuer Auftrag'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int?>(
                    value: _kundeId,
                    decoration: const InputDecoration(labelText: 'Kunde *'),
                    items: _kunden
                        .map(
                          (kunde) => DropdownMenuItem<int?>(
                            value: kunde.id,
                            child: Text(kunde.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Bitte Kunden auswählen' : null,
                    onChanged: (value) => setState(() => _kundeId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _angebotId,
                    decoration: const InputDecoration(
                      labelText: 'Angenommenes Angebot',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Kein Angebot verknüpfen'),
                      ),
                      ..._angebote.map(
                        (angebot) => DropdownMenuItem<int?>(
                          value: angebot.id,
                          child: Text('${angebot.nummer} · ${angebot.kundeName}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _angebotId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Monteur?>(
                    value: _gewaehlterMonteur,
                    decoration: const InputDecoration(labelText: 'Monteur'),
                    items: [
                      const DropdownMenuItem<Monteur?>(
                        value: null,
                        child: Text('Noch nicht zuweisen'),
                      ),
                      ..._monteure.map(
                        (monteur) => DropdownMenuItem<Monteur?>(
                          value: monteur,
                          child: Text(
                            monteur.aktiv
                                ? monteur.name
                                : '${monteur.name} (inaktiv)',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _monteurId = value?.id),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AuftragStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: AuftragStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _terminWaehlen,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_datumText(_termin)),
                  ),
                  if (_termin != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _termin = null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Termin entfernen'),
                    ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _speichern,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isEdit ? 'Änderungen speichern' : 'Auftrag anlegen',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
