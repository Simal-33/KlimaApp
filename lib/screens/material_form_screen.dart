import 'package:flutter/material.dart';
import '../data/material_repository.dart';
import '../models/material_artikel.dart';

class MaterialFormScreen extends StatefulWidget {
  final MaterialArtikel? material;

  const MaterialFormScreen({super.key, this.material});

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MaterialRepository();

  late final TextEditingController _artikel;
  late final TextEditingController _preis;
  late final TextEditingController _lager;
  late final TextEditingController _mindest;
  late String _einheit;

  bool _isSaving = false;
  bool get _isEdit => widget.material != null;

  static const _einheiten = ['m', 'Stück', 'kg', 'l'];

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _artikel = TextEditingController(text: m?.artikel ?? '');
    _preis = TextEditingController(text: m != null ? m.preis.toStringAsFixed(2) : '');
    _lager = TextEditingController(text: m != null ? m.lagerbestand.toString() : '0');
    _mindest = TextEditingController(text: m != null ? m.mindestbestand.toString() : '0');
    _einheit = m?.einheit ?? 'Stück';
    if (!_einheiten.contains(_einheit)) _einheit = 'Stück';
  }

  @override
  void dispose() {
    for (final c in [_artikel, _preis, _lager, _mindest]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final material = MaterialArtikel(
      id: widget.material?.id,
      artikel: _artikel.text.trim(),
      einheit: _einheit,
      preis: _parseDouble(_preis.text),
      lagerbestand: _parseDouble(_lager.text),
      mindestbestand: _parseDouble(_mindest.text),
    );

    try {
      if (_isEdit) {
        await _repo.aktualisieren(material);
      } else {
        await _repo.anlegen(material);
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
      appBar: AppBar(title: Text(_isEdit ? 'Material bearbeiten' : 'Neues Material')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _artikel,
              decoration: const InputDecoration(labelText: 'Artikel *  (z. B. "Kupferrohr 1/4")'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Artikel eingeben' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _preis,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preis (€)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _einheit,
                    decoration: const InputDecoration(labelText: 'Einheit'),
                    items: _einheiten
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _einheit = v ?? _einheit),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Lagerbestand ($_einheit)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mindest,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              label: Text(_isEdit ? 'Änderungen speichern' : 'Material anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
