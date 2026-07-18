import 'package:flutter/material.dart';
import '../models/angebot.dart';
import '../models/geraet.dart';
import '../models/material_artikel.dart';
import '../theme/app_theme.dart';

/// Feste Stundensätze laut Konzept (Tätigkeit -> Preis pro Stunde).
/// Später aus der Einstellungen-Tabelle ladbar.
const Map<String, double> kStundensaetze = {
  'Monteur': 65,
  'Helfer': 45,
  'Elektriker': 85,
};

class PositionHinzufuegenSheet extends StatefulWidget {
  final List<Geraet> geraete;
  final List<MaterialArtikel> material;

  const PositionHinzufuegenSheet({
    super.key,
    required this.geraete,
    required this.material,
  });

  @override
  State<PositionHinzufuegenSheet> createState() => _PositionHinzufuegenSheetState();
}

class _PositionHinzufuegenSheetState extends State<PositionHinzufuegenSheet> {
  PositionsTyp _typ = PositionsTyp.geraet;

  Geraet? _gewaehltesGeraet;
  MaterialArtikel? _gewaehltesMaterial;
  String _taetigkeit = 'Monteur';

  final _mengeController = TextEditingController(text: '1');
  final _preisController = TextEditingController();
  final _bezeichnungController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.geraete.isNotEmpty) _waehleGeraet(widget.geraete.first);
    _preisController.text = kStundensaetze['Monteur']!.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _mengeController.dispose();
    _preisController.dispose();
    _bezeichnungController.dispose();
    super.dispose();
  }

  void _waehleGeraet(Geraet g) {
    _gewaehltesGeraet = g;
    _preisController.text = g.verkaufspreis.toStringAsFixed(2);
  }

  void _waehleMaterial(MaterialArtikel m) {
    _gewaehltesMaterial = m;
    _preisController.text = m.preis.toStringAsFixed(2);
  }

  double _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  void _uebernehmen() {
    final menge = _parseDouble(_mengeController.text);
    final preis = _parseDouble(_preisController.text);
    if (menge <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte eine Menge größer 0 eingeben')));
      return;
    }

    late final AngebotPosition position;
    switch (_typ) {
      case PositionsTyp.geraet:
        if (_gewaehltesGeraet == null) return;
        position = AngebotPosition(
          typ: PositionsTyp.geraet,
          bezugId: _gewaehltesGeraet!.id,
          bezeichnung: _gewaehltesGeraet!.artikel,
          menge: menge,
          einzelpreis: preis,
        );
        break;
      case PositionsTyp.material:
        if (_gewaehltesMaterial == null) return;
        position = AngebotPosition(
          typ: PositionsTyp.material,
          bezugId: _gewaehltesMaterial!.id,
          bezeichnung: '${_gewaehltesMaterial!.artikel} (${_gewaehltesMaterial!.einheit})',
          menge: menge,
          einzelpreis: preis,
        );
        break;
      case PositionsTyp.arbeitszeit:
        position = AngebotPosition(
          typ: PositionsTyp.arbeitszeit,
          bezeichnung: '$_taetigkeit (Std.)',
          menge: menge,
          einzelpreis: preis,
        );
        break;
      case PositionsTyp.frei:
        if (_bezeichnungController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Bitte eine Bezeichnung eingeben')));
          return;
        }
        position = AngebotPosition(
          typ: PositionsTyp.frei,
          bezeichnung: _bezeichnungController.text.trim(),
          menge: menge,
          einzelpreis: preis,
        );
        break;
    }

    Navigator.of(context).pop(position);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Position hinzufügen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: PositionsTyp.values.map((typ) {
                final aktiv = _typ == typ;
                return ChoiceChip(
                  label: Text(typ.label),
                  selected: aktiv,
                  onSelected: (_) => setState(() => _typ = typ),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: aktiv ? AppTheme.primary : Colors.black87,
                    fontWeight: aktiv ? FontWeight.w700 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            if (_typ == PositionsTyp.geraet) ...[
              if (widget.geraete.isEmpty)
                const Text('Noch keine Geräte angelegt.',
                    style: TextStyle(color: Colors.black54))
              else
                DropdownButtonFormField<Geraet>(
                  initialValue: _gewaehltesGeraet,
                  decoration: const InputDecoration(labelText: 'Gerät'),
                  items: widget.geraete
                      .map((g) => DropdownMenuItem(value: g, child: Text(g.artikel)))
                      .toList(),
                  onChanged: (g) => setState(() {
                    if (g != null) _waehleGeraet(g);
                  }),
                ),
            ],
            if (_typ == PositionsTyp.material) ...[
              if (widget.material.isEmpty)
                const Text('Noch kein Material angelegt.',
                    style: TextStyle(color: Colors.black54))
              else
                DropdownButtonFormField<MaterialArtikel>(
                  initialValue: _gewaehltesMaterial,
                  decoration: const InputDecoration(labelText: 'Material'),
                  items: widget.material
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text('${m.artikel} (${m.einheit})')))
                      .toList(),
                  onChanged: (m) => setState(() {
                    if (m != null) _waehleMaterial(m);
                  }),
                ),
            ],
            if (_typ == PositionsTyp.arbeitszeit)
              DropdownButtonFormField<String>(
                initialValue: _taetigkeit,
                decoration: const InputDecoration(labelText: 'Tätigkeit'),
                items: kStundensaetze.keys
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (t) => setState(() {
                  _taetigkeit = t ?? _taetigkeit;
                  _preisController.text = kStundensaetze[_taetigkeit]!.toStringAsFixed(2);
                }),
              ),
            if (_typ == PositionsTyp.frei)
              TextField(
                controller: _bezeichnungController,
                decoration: const InputDecoration(labelText: 'Bezeichnung'),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mengeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _typ == PositionsTyp.arbeitszeit ? 'Stunden' : 'Menge',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _preisController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Einzelpreis (€)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _uebernehmen,
              icon: const Icon(Icons.add),
              label: const Text('Position übernehmen'),
            ),
          ],
        ),
      ),
    );
  }
}
