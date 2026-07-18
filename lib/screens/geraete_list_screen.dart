import 'package:flutter/material.dart';
import '../data/geraete_repository.dart';
import '../models/geraet.dart';
import '../theme/app_theme.dart';
import 'geraet_form_screen.dart';

class GeraeteListScreen extends StatefulWidget {
  const GeraeteListScreen({super.key});

  @override
  State<GeraeteListScreen> createState() => _GeraeteListScreenState();
}

class _GeraeteListScreenState extends State<GeraeteListScreen> {
  final _repo = GeraeteRepository();
  final _searchController = TextEditingController();

  List<Geraet> _geraete = [];
  bool _isLoading = true;
  String _suchtext = '';

  @override
  void initState() {
    super.initState();
    _laden();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final geraete = await _repo.alle(suchtext: _suchtext);
    if (!mounted) return;
    setState(() {
      _geraete = geraete;
      _isLoading = false;
    });
  }

  Future<void> _oeffneFormular({Geraet? geraet}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GeraetFormScreen(geraet: geraet)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(Geraet geraet) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerät löschen?'),
        content: Text('"${geraet.artikel}" wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (bestaetigt == true && geraet.id != null) {
      await _repo.loeschen(geraet.id!);
      _laden();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unterMindestbestand = _geraete.where((g) => g.unterMindestbestand).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Geräte')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffneFormular(),
        icon: const Icon(Icons.add),
        label: const Text('Neues Gerät'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suche nach Artikel, Hersteller, Modell …',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _suchtext.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suchtext = '');
                          _laden();
                        },
                      ),
              ),
              onChanged: (value) {
                setState(() => _suchtext = value);
                _laden();
              },
            ),
          ),
          if (!_isLoading && unterMindestbestand > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$unterMindestbestand Gerät(e) am oder unter Mindestbestand',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _geraete.isEmpty
                    ? Center(
                        child: Text(
                          _suchtext.isNotEmpty
                              ? 'Keine Geräte für diese Suche gefunden.'
                              : 'Noch keine Geräte angelegt.\nTippe unten rechts auf "Neues Gerät".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _laden,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: _geraete.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final geraet = _geraete[index];
                            return Card(
                              child: ListTile(
                                onTap: () => _oeffneFormular(geraet: geraet),
                                onLongPress: () => _loeschen(geraet),
                                leading: CircleAvatar(
                                  backgroundColor: geraet.unterMindestbestand
                                      ? AppTheme.warning.withOpacity(0.18)
                                      : AppTheme.primary.withOpacity(0.12),
                                  child: Icon(Icons.ac_unit,
                                      color: geraet.unterMindestbestand
                                          ? AppTheme.warning
                                          : AppTheme.primary),
                                ),
                                title: Text(geraet.artikel,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [
                                    if (geraet.hersteller != null) geraet.hersteller!,
                                    if (geraet.modell != null) geraet.modell!,
                                    '${geraet.verkaufspreis.toStringAsFixed(2)} €',
                                  ].join(' · '),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${geraet.lagerbestand} Stk.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: geraet.unterMindestbestand
                                              ? AppTheme.danger
                                              : Colors.black87,
                                        )),
                                    Text('Min. ${geraet.mindestbestand}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
