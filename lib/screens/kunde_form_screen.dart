import 'package:flutter/material.dart';
import '../data/kunden_repository.dart';
import '../models/kunde.dart';

class KundeFormScreen extends StatefulWidget {
  final Kunde? kunde; // null = neuer Kunde, sonst Bearbeiten

  const KundeFormScreen({super.key, this.kunde});

  @override
  State<KundeFormScreen> createState() => _KundeFormScreenState();
}

class _KundeFormScreenState extends State<KundeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = KundenRepository();

  late final TextEditingController _name;
  late final TextEditingController _adresse;
  late final TextEditingController _plz;
  late final TextEditingController _ort;
  late final TextEditingController _telefon;
  late final TextEditingController _email;
  late final TextEditingController _notizen;
  late final TextEditingController _breitengrad;
  late final TextEditingController _laengengrad;

  bool _isSaving = false;
  bool get _isEdit => widget.kunde != null;

  @override
  void initState() {
    super.initState();
    final k = widget.kunde;
    _name = TextEditingController(text: k?.name ?? '');
    _adresse = TextEditingController(text: k?.adresse ?? '');
    _plz = TextEditingController(text: k?.plz ?? '');
    _ort = TextEditingController(text: k?.ort ?? '');
    _telefon = TextEditingController(text: k?.telefon ?? '');
    _email = TextEditingController(text: k?.email ?? '');
    _notizen = TextEditingController(text: k?.notizen ?? '');
    _breitengrad = TextEditingController(text: k?.breitengrad?.toString() ?? '');
    _laengengrad = TextEditingController(text: k?.laengengrad?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _name, _adresse, _plz, _ort, _telefon, _email,
      _notizen, _breitengrad, _laengengrad,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final kunde = Kunde(
      id: widget.kunde?.id,
      name: _name.text.trim(),
      adresse: _adresse.text.trim().isEmpty ? null : _adresse.text.trim(),
      plz: _plz.text.trim().isEmpty ? null : _plz.text.trim(),
      ort: _ort.text.trim().isEmpty ? null : _ort.text.trim(),
      telefon: _telefon.text.trim().isEmpty ? null : _telefon.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
      breitengrad: double.tryParse(_breitengrad.text.trim().replaceAll(',', '.')),
      laengengrad: double.tryParse(_laengengrad.text.trim().replaceAll(',', '.')),
    );

    try {
      if (_isEdit) {
        await _repo.aktualisieren(kunde);
      } else {
        await _repo.anlegen(kunde);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true); // true = Liste soll neu laden
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Kunde bearbeiten' : 'Neuer Kunde'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bitte Namen eingeben' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresse,
              decoration: const InputDecoration(labelText: 'Adresse (Straße, Nr.)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _plz,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'PLZ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _ort,
                    decoration: const InputDecoration(labelText: 'Ort'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefon,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-Mail'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return v.contains('@') ? null : 'Ungültige E-Mail-Adresse';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notizen,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notizen'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.map_outlined, size: 18, color: Colors.black45),
                SizedBox(width: 6),
                Text('Standort auf Karte',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _breitengrad,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Breitengrad'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _laengengrad,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Längengrad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Hinweis: Manuelle Eingabe im Grundgerüst. In einem späteren '
              'Schritt per GPS/Kartenauswahl (z. B. Google Maps) automatisch befüllbar.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _speichern,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Änderungen speichern' : 'Kunde anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
