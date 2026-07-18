import 'package:flutter/material.dart';
import '../models/rechnung.dart';

class RechnungPositionDialog extends StatefulWidget {
  final RechnungPosition? position; // null = neue Position

  const RechnungPositionDialog({super.key, this.position});

  @override
  State<RechnungPositionDialog> createState() => _RechnungPositionDialogState();
}

class _RechnungPositionDialogState extends State<RechnungPositionDialog> {
  late final TextEditingController _bezeichnung;
  late final TextEditingController _menge;
  late final TextEditingController _preis;

  @override
  void initState() {
    super.initState();
    final p = widget.position;
    _bezeichnung = TextEditingController(text: p?.bezeichnung ?? '');
    _menge = TextEditingController(text: p != null ? _fmt(p.menge) : '1');
    _preis = TextEditingController(text: p != null ? p.einzelpreis.toStringAsFixed(2) : '');
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _bezeichnung.dispose();
    _menge.dispose();
    _preis.dispose();
    super.dispose();
  }

  void _uebernehmen() {
    if (_bezeichnung.text.trim().isEmpty) return;
    final menge = double.tryParse(_menge.text.trim().replaceAll(',', '.')) ?? 1;
    final preis = double.tryParse(_preis.text.trim().replaceAll(',', '.')) ?? 0;

    Navigator.of(context).pop(RechnungPosition(
      id: widget.position?.id,
      rechnungId: widget.position?.rechnungId,
      bezeichnung: _bezeichnung.text.trim(),
      menge: menge,
      einzelpreis: preis,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.position == null ? 'Position hinzufügen' : 'Position bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _bezeichnung,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Bezeichnung'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _menge,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Menge'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _preis,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Einzelpreis (€)'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        TextButton(onPressed: _uebernehmen, child: const Text('Übernehmen')),
      ],
    );
  }
}
