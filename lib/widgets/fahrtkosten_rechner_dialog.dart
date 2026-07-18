import 'package:flutter/material.dart';

/// Berechnet Fahrtkosten nach der Staffel aus dem Konzept:
/// bis 20 km kostenlos, 20–50 km 45 €, 50–100 km 85 €, über 100 km 1 €/km.
double berechneFahrtkostenAusEntfernung(double km) {
  if (km <= 20) return 0;
  if (km <= 50) return 45;
  if (km <= 100) return 85;
  return km * 1.0;
}

class FahrtkostenRechnerDialog extends StatefulWidget {
  const FahrtkostenRechnerDialog({super.key});

  @override
  State<FahrtkostenRechnerDialog> createState() => _FahrtkostenRechnerDialogState();
}

class _FahrtkostenRechnerDialogState extends State<FahrtkostenRechnerDialog> {
  final _kmController = TextEditingController();
  double? _ergebnis;

  void _berechnen() {
    final km = double.tryParse(_kmController.text.trim().replaceAll(',', '.'));
    if (km == null) return;
    setState(() => _ergebnis = berechneFahrtkostenAusEntfernung(km));
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fahrtkosten berechnen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'bis 20 km kostenlos · 20–50 km 45 € · 50–100 km 85 € · über 100 km 1 €/km',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _kmController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Entfernung (km, einfache Strecke)'),
            onChanged: (_) => _berechnen(),
            onSubmitted: (_) => _berechnen(),
          ),
          if (_ergebnis != null) ...[
            const SizedBox(height: 14),
            Text(
              'Fahrtkosten: ${_ergebnis!.toStringAsFixed(2)} €',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: _ergebnis == null ? null : () => Navigator.pop(context, _ergebnis),
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }
}
