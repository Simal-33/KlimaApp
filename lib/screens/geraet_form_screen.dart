import 'package:flutter/material.dart';
import '../data/geraete_repository.dart';
import '../models/geraet.dart';

class GeraetFormScreen extends StatefulWidget {
  final Geraet? geraet;

  const GeraetFormScreen({super.key, this.geraet});

  @override
  State<GeraetFormScreen> createState() => _GeraetFormScreenState();
}

class _GeraetFormScreenState extends State<GeraetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = GeraeteRepository();

  late final TextEditingController _artikel;
  late final TextEditingController _hersteller;
  late final TextEditingController _modell;
  late final TextEditingController _einkauf;
  late final TextEditingController _verkauf;
  late final TextEditingController _lager;
  late final TextEditingController _mindest;

  bool _isSaving = false;
  bool get _isEdit => widget.geraet != null;

  @override
  void initState() {
    super.initState();
    final g = widget.geraet;
    _artikel = TextEditingController(text: g?.artikel ?? '');
    _hersteller = TextEditingController(text: g?.hersteller ?? '');
    _modell = TextEditingController(text: g?.modell ?? '');
    _einkauf = TextEditingController(text: g != null ? g.einkaufspreis.toStringAsFixed(2) : '');
    _verkauf = TextEditingController(text: g != null ? g.verkaufspreis.toStringAsFixed(2) : '');
    _lager = TextEditingController(text: g != null ? g.lagerbestand.toString() : '0');
    _mindest = TextEditingController(text: g != null ? g.mindestbestand.toString() : '0');
  }

  @override
  void dispose() {
    for (final c in [_artikel, _hersteller, _modell, _einkauf, _verkauf, _lager, _mindest]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final geraet = Geraet(
      id: widget.geraet?.id,
      artikel: _artikel.text.trim(),
      hersteller: _hersteller.text.trim().isEmpty ? null : _hersteller.text.trim(),
      modell: _modell.text.trim().isEmpty ? null : _modell.text.trim(),
      einkaufspreis: _parseDouble(_einkauf.text),
      verkaufspreis: _parseDouble(_verkauf.text),
      lagerbestand: _parseInt(_lager.text),
      mindestbestand: _parseInt(_mindest.text),
    );

    try {
      if (_isEdit) {
        await _repo.aktualisieren(geraet);
      } else {
        await _repo.anlegen(geraet);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Gerät bearbeiten' : 'Neues Gerät')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _artikel,
              decoration: const InputDecoration(labelText: 'Artikel *  (z. B. "Splitgerät 2,5 kW")'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Artikel eingeben' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hersteller,
                    decoration: const InputDecoration(labelText: 'Hersteller'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modell,
                    decoration: const InputDecoration(labelText: 'Modell'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _einkauf,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Einkaufspreis (€)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _verkauf,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Verkaufspreis (€)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lager,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Lagerbestand (Stück)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mindest,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mindestbestand'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _speichern,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Änderungen speichern' : 'Gerät anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
