import 'package:flutter/material.dart';
import '../data/monteure_repository.dart';
import '../models/monteur.dart';

class MonteurFormScreen extends StatefulWidget {
  final Monteur? monteur;
  const MonteurFormScreen({super.key, this.monteur});

  @override
  State<MonteurFormScreen> createState() => _MonteurFormScreenState();
}

class _MonteurFormScreenState extends State<MonteurFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MonteureRepository();

  late final _nameController = TextEditingController(text: widget.monteur?.name ?? '');
  late final _telefonController = TextEditingController(text: widget.monteur?.telefon ?? '');
  late final _emailController = TextEditingController(text: widget.monteur?.email ?? '');
  late final _stundensatzController =
      TextEditingController(text: (widget.monteur?.stundensatz ?? 65).toStringAsFixed(2));
  late bool _aktiv = widget.monteur?.aktiv ?? true;
  bool _isSaving = false;

  bool get _isEdit => widget.monteur != null;

  @override
  void dispose() {
    _nameController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _stundensatzController.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final monteur = Monteur(
      id: widget.monteur?.id,
      name: _nameController.text.trim(),
      telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      stundensatz: double.tryParse(_stundensatzController.text.trim().replaceAll(',', '.')) ?? 65,
      aktiv: _aktiv,
    );

    try {
      if (_isEdit) {
        await _repo.aktualisieren(monteur);
      } else {
        await _repo.anlegen(monteur);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Monteur bearbeiten' : 'Neuer Monteur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Namen eingeben' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-Mail'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stundensatzController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Stundensatz (€)'),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktiv (verfügbar für Einsätze)'),
              value: _aktiv,
              onChanged: (v) => setState(() => _aktiv = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _speichern,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Änderungen speichern' : 'Monteur anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
