import 'package:flutter/material.dart';

/// Fragt eine Menge (+ optionale Notiz) ab, z.B. für Wareneingang,
/// Warenausgang oder eine Inventurzählung.
class MengenDialog extends StatefulWidget {
  final String titel;
  final String mengenLabel;
  final double? startwert;

  const MengenDialog({
    super.key,
    required this.titel,
    this.mengenLabel = 'Menge',
    this.startwert,
  });

  @override
  State<MengenDialog> createState() => _MengenDialogState();
}

class _MengenDialogState extends State<MengenDialog> {
  late final _mengeController =
      TextEditingController(text: widget.startwert != null ? _fmt(widget.startwert!) : '');
  final _notizController = TextEditingController();

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _mengeController.dispose();
    _notizController.dispose();
    super.dispose();
  }

  void _bestaetigen() {
    final menge = double.tryParse(_mengeController.text.trim().replaceAll(',', '.'));
    if (menge == null || menge < 0) return;
    Navigator.of(context).pop({
      'menge': menge,
      'notiz': _notizController.text.trim().isEmpty ? null : _notizController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _mengeController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: widget.mengenLabel),
            onSubmitted: (_) => _bestaetigen(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notizController,
            decoration: const InputDecoration(labelText: 'Notiz (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        TextButton(onPressed: _bestaetigen, child: const Text('Bestätigen')),
      ],
    );
  }
}
