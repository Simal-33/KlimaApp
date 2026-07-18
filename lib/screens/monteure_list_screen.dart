import 'package:flutter/material.dart';
import '../data/monteure_repository.dart';
import '../models/monteur.dart';
import '../theme/app_theme.dart';
import 'monteur_form_screen.dart';

class MonteureListScreen extends StatefulWidget {
  const MonteureListScreen({super.key});

  @override
  State<MonteureListScreen> createState() => _MonteureListScreenState();
}

class _MonteureListScreenState extends State<MonteureListScreen> {
  final _repo = MonteureRepository();
  List<Monteur> _monteure = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final monteure = await _repo.alle();
    if (!mounted) return;
    setState(() {
      _monteure = monteure;
      _isLoading = false;
    });
  }

  Future<void> _oeffnen({Monteur? monteur}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MonteurFormScreen(monteur: monteur)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(Monteur monteur) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monteur löschen?'),
        content: Text('"${monteur.name}" wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (bestaetigt == true && monteur.id != null) {
      await _repo.loeschen(monteur.id!);
      _laden();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monteure')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffnen(),
        icon: const Icon(Icons.add),
        label: const Text('Neuer Monteur'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Stammdaten der Monteure. Arbeitszeiten, Fotos, Kunden-Unterschrift '
              'und Checklisten pro Einsatz folgen zusammen mit dem Auftrags-Modul.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _monteure.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Noch keine Monteure angelegt.\nTippe unten rechts auf "Neuer Monteur".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _laden,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: _monteure.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final m = _monteure[index];
                            return Dismissible(
                              key: ValueKey(m.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                _loeschen(m);
                                return false;
                              },
                              background: Container(
                                decoration: BoxDecoration(
                                    color: AppTheme.danger, borderRadius: BorderRadius.circular(14)),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              child: Card(
                                child: ListTile(
                                  onTap: () => _oeffnen(monteur: m),
                                  leading: CircleAvatar(
                                    backgroundColor: m.aktiv
                                        ? AppTheme.primary.withOpacity(0.12)
                                        : Colors.black12,
                                    child: Icon(Icons.engineering_outlined,
                                        color: m.aktiv ? AppTheme.primary : Colors.black38),
                                  ),
                                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    '${m.stundensatz.toStringAsFixed(2)} €/h'
                                    '${m.telefon != null && m.telefon!.isNotEmpty ? ' · ${m.telefon}' : ''}',
                                  ),
                                  trailing: m.aktiv
                                      ? null
                                      : const Text('Inaktiv',
                                          style: TextStyle(color: Colors.black38, fontSize: 12)),
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
