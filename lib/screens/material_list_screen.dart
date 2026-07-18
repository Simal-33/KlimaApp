import 'package:flutter/material.dart';
import '../data/material_repository.dart';
import '../models/material_artikel.dart';
import '../theme/app_theme.dart';
import 'material_form_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final _repo = MaterialRepository();
  final _searchController = TextEditingController();

  List<MaterialArtikel> _material = [];
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
    final material = await _repo.alle(suchtext: _suchtext);
    if (!mounted) return;
    setState(() {
      _material = material;
      _isLoading = false;
    });
  }

  Future<void> _oeffneFormular({MaterialArtikel? material}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MaterialFormScreen(material: material)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(MaterialArtikel material) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Material löschen?'),
        content: Text('"${material.artikel}" wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (bestaetigt == true && material.id != null) {
      await _repo.loeschen(material.id!);
      _laden();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unterMindestbestand = _material.where((m) => m.unterMindestbestand).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Material')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffneFormular(),
        icon: const Icon(Icons.add),
        label: const Text('Neues Material'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suche nach Artikel …',
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
                      '$unterMindestbestand Artikel am oder unter Mindestbestand',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _material.isEmpty
                    ? Center(
                        child: Text(
                          _suchtext.isNotEmpty
                              ? 'Kein Material für diese Suche gefunden.'
                              : 'Noch kein Material angelegt.\nTippe unten rechts auf "Neues Material".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _laden,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: _material.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final material = _material[index];
                            return Card(
                              child: ListTile(
                                onTap: () => _oeffneFormular(material: material),
                                onLongPress: () => _loeschen(material),
                                leading: CircleAvatar(
                                  backgroundColor: material.unterMindestbestand
                                      ? AppTheme.warning.withOpacity(0.18)
                                      : AppTheme.primary.withOpacity(0.12),
                                  child: Icon(Icons.category_outlined,
                                      color: material.unterMindestbestand
                                          ? AppTheme.warning
                                          : AppTheme.primary),
                                ),
                                title: Text(material.artikel,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    '${material.preis.toStringAsFixed(2)} € / ${material.einheit}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${material.lagerbestand.toStringAsFixed(material.lagerbestand.truncateToDouble() == material.lagerbestand ? 0 : 1)} ${material.einheit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: material.unterMindestbestand
                                            ? AppTheme.danger
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text('Min. ${material.mindestbestand.toStringAsFixed(0)}',
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
