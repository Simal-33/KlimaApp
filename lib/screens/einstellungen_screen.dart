import 'package:flutter/material.dart';
import '../data/einstellungen_repository.dart';
import '../models/firmeneinstellungen.dart';

class EinstellungenScreen extends StatefulWidget {
  const EinstellungenScreen({super.key});

  @override
  State<EinstellungenScreen> createState() => _EinstellungenScreenState();
}

class _EinstellungenScreenState extends State<EinstellungenScreen> {
  final _repo = EinstellungenRepository();
  bool _isLoading = true;
  bool _isSaving = false;

  late final _firmennameController = TextEditingController();
  late final _ibanController = TextEditingController();
  late final _bicController = TextEditingController();
  late final _mwstController = TextEditingController();
  late final _stundenlohnMonteurController = TextEditingController();
  late final _stundenlohnHelferController = TextEditingController();
  late final _stundenlohnElektrikerController = TextEditingController();
  late final _kilometerpreisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    final e = await _repo.laden();
    _firmennameController.text = e.firmenname;
    _ibanController.text = e.iban ?? '';
    _bicController.text = e.bic ?? '';
    _mwstController.text = _fmt(e.mwstProzent);
    _stundenlohnMonteurController.text = _fmt(e.stundenlohnMonteur);
    _stundenlohnHelferController.text = _fmt(e.stundenlohnHelfer);
    _stundenlohnElektrikerController.text = _fmt(e.stundenlohnElektriker);
    _kilometerpreisController.text = _fmt(e.kilometerpreis);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  double _zahl(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _firmennameController.dispose();
    _ibanController.dispose();
    _bicController.dispose();
    _mwstController.dispose();
    _stundenlohnMonteurController.dispose();
    _stundenlohnHelferController.dispose();
    _stundenlohnElektrikerController.dispose();
    _kilometerpreisController.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    setState(() => _isSaving = true);
    final e = Firmeneinstellungen(
      firmenname: _firmennameController.text.trim().isEmpty
          ? 'Mein Klimatechnik-Betrieb'
          : _firmennameController.text.trim(),
      iban: _ibanController.text.trim().isEmpty ? null : _ibanController.text.trim(),
      bic: _bicController.text.trim().isEmpty ? null : _bicController.text.trim(),
      mwstProzent: _zahl(_mwstController.text),
      stundenlohnMonteur: _zahl(_stundenlohnMonteurController.text),
      stundenlohnHelfer: _zahl(_stundenlohnHelferController.text),
      stundenlohnElektriker: _zahl(_stundenlohnElektrikerController.text),
      kilometerpreis: _zahl(_kilometerpreisController.text),
    );

    await _repo.speichern(e);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Einstellungen gespeichert.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Abschnitt('Firma'),
          TextField(
            controller: _firmennameController,
            decoration: const InputDecoration(labelText: 'Firmenname'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ibanController,
            decoration: const InputDecoration(labelText: 'IBAN'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bicController,
            decoration: const InputDecoration(labelText: 'BIC'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Firmenlogo und individuelle PDF-Vorlagen folgen in einem späteren Schritt.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),

          const SizedBox(height: 24),
          const _Abschnitt('Preise & Sätze'),
          TextField(
            controller: _mwstController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Mehrwertsteuer (%) – Standardwert für neue Angebote/Rechnungen'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kilometerpreisController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Kilometerpreis (€/km) über 100 km'),
          ),

          const SizedBox(height: 24),
          const _Abschnitt('Stundensätze'),
          TextField(
            controller: _stundenlohnMonteurController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monteur (€/h)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stundenlohnHelferController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Helfer (€/h)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stundenlohnElektrikerController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Elektriker (€/h)'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hinweis: Diese Werte dienen aktuell als Referenz. Die automatische '
            'Übernahme in die Positions-Auswahl bei Angeboten folgt in einem '
            'der nächsten Schritte.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),

          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _speichern,
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: const Text('Einstellungen speichern'),
          ),
        ],
      ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final String text;
  const _Abschnitt(this.text);

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
