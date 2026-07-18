import 'package:flutter/material.dart';
import '../data/geraete_repository.dart';
import '../data/lagerbewegungen_repository.dart';
import '../data/material_repository.dart';
import '../models/geraet.dart';
import '../models/lagerbewegung.dart';
import '../models/material_artikel.dart';
import '../theme/app_theme.dart';
import '../widgets/mengen_dialog.dart';

/// Vereinheitlichte Sicht auf ein Lagerobjekt, egal ob Gerät oder Material,
/// damit beide in einer gemeinsamen Liste dargestellt werden können.
class _LagerEintrag {
  final int id;
  final String artikel;
  final String? einheit; // null bei Geräten (Stück)
  final double lagerbestand;
  final double mindestbestand;
  final LagerArtikelTyp typ;

  _LagerEintrag.ausGeraet(Geraet g)
      : id = g.id!,
        artikel = g.artikel,
        einheit = null,
        lagerbestand = g.lagerbestand.toDouble(),
        mindestbestand = g.mindestbestand.toDouble(),
        typ = LagerArtikelTyp.geraet;

  _LagerEintrag.ausMaterial(MaterialArtikel m)
      : id = m.id!,
        artikel = m.artikel,
        einheit = m.einheit,
        lagerbestand = m.lagerbestand,
        mindestbestand = m.mindestbestand,
        typ = LagerArtikelTyp.material;

  bool get unterMindestbestand => lagerbestand <= mindestbestand;

  String get mengeText =>
      '${lagerbestand == lagerbestand.roundToDouble() ? lagerbestand.toStringAsFixed(0) : lagerbestand.toStringAsFixed(2)}'
      '${einheit != null ? ' $einheit' : ' Stk.'}';
}

class LagerverwaltungScreen extends StatefulWidget {
  const LagerverwaltungScreen({super.key});

  @override
  State<LagerverwaltungScreen> createState() => _LagerverwaltungScreenState();
}

class _LagerverwaltungScreenState extends State<LagerverwaltungScreen> {
  final _geraeteRepo = GeraeteRepository();
  final _materialRepo = MaterialRepository();
  final _bewegungenRepo = LagerbewegungenRepository();

  List<_LagerEintrag> _eintraege = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final geraete = await _geraeteRepo.alle();
    final material = await _materialRepo.alle();
    final eintraege = [
      ...geraete.map(_LagerEintrag.ausGeraet),
      ...material.map(_LagerEintrag.ausMaterial),
    ]..sort((a, b) => a.artikel.toLowerCase().compareTo(b.artikel.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _eintraege = eintraege;
      _isLoading = false;
    });
  }

  Future<void> _buchen(_LagerEintrag e, LagerbewegungTyp typ) async {
    final titel = switch (typ) {
      LagerbewegungTyp.eingang => 'Wareneingang: ${e.artikel}',
      LagerbewegungTyp.ausgang => 'Warenausgang: ${e.artikel}',
      LagerbewegungTyp.inventur => 'Inventur: ${e.artikel}',
    };
    final label = typ == LagerbewegungTyp.inventur ? 'Neuer Gesamtbestand' : 'Menge';

    final ergebnis = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MengenDialog(
        titel: titel,
        mengenLabel: label,
        startwert: typ == LagerbewegungTyp.inventur ? e.lagerbestand : null,
      ),
    );
    if (ergebnis == null) return;

    await _bewegungenRepo.buchen(
      typ: typ,
      bezugTyp: e.typ,
      bezugId: e.id,
      menge: ergebnis['menge'] as double,
      notiz: ergebnis['notiz'] as String?,
    );
    _laden();
  }

  @override
  Widget build(BuildContext context) {
    final bestellliste = _eintraege.where((e) => e.unterMindestbestand).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Lagerverwaltung')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _laden,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                children: [
                  if (bestellliste.isNotEmpty) ...[
                    _Abschnitt('Bestellliste (${bestellliste.length})', farbe: AppTheme.danger),
                    ...bestellliste.map((e) => _LagerKarte(
                          eintrag: e,
                          warnung: true,
                          onBuchen: (typ) => _buchen(e, typ),
                        )),
                    const SizedBox(height: 20),
                  ],
                  _Abschnitt('Alle Artikel (${_eintraege.length})'),
                  if (_eintraege.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Noch keine Geräte oder Material angelegt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    ..._eintraege.map((e) => _LagerKarte(
                          eintrag: e,
                          warnung: e.unterMindestbestand,
                          onBuchen: (typ) => _buchen(e, typ),
                        )),
                ],
              ),
            ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final String text;
  final Color? farbe;
  const _Abschnitt(this.text, {this.farbe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: farbe ?? Colors.black54,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _LagerKarte extends StatelessWidget {
  final _LagerEintrag eintrag;
  final bool warnung;
  final void Function(LagerbewegungTyp typ) onBuchen;

  const _LagerKarte({required this.eintrag, required this.warnung, required this.onBuchen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  eintrag.typ == LagerArtikelTyp.geraet ? Icons.ac_unit : Icons.category_outlined,
                  size: 18,
                  color: warnung ? AppTheme.danger : AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(eintrag.artikel,
                      style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
                Text(
                  eintrag.mengeText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: warnung ? AppTheme.danger : Colors.black87,
                  ),
                ),
              ],
            ),
            if (warnung)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 26),
                child: Text(
                  'Mindestbestand: ${eintrag.mindestbestand == eintrag.mindestbestand.roundToDouble() ? eintrag.mindestbestand.toStringAsFixed(0) : eintrag.mindestbestand.toStringAsFixed(2)}${eintrag.einheit != null ? ' ${eintrag.einheit}' : ' Stk.'}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.danger),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onBuchen(LagerbewegungTyp.eingang),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Eingang'),
                ),
                TextButton.icon(
                  onPressed: () => onBuchen(LagerbewegungTyp.ausgang),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Ausgang'),
                ),
                IconButton(
                  onPressed: () => onBuchen(LagerbewegungTyp.inventur),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  tooltip: 'Inventur',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
