import 'package:flutter/material.dart';
import '../data/kunden_repository.dart';
import '../models/kunde.dart';
import '../theme/app_theme.dart';
import 'kunde_form_screen.dart';

class KundenListScreen extends StatefulWidget {
  const KundenListScreen({super.key});

  @override
  State<KundenListScreen> createState() => _KundenListScreenState();
}

class _KundenListScreenState extends State<KundenListScreen> {
  final _repo = KundenRepository();
  final _searchController = TextEditingController();

  List<Kunde> _kunden = [];
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
    final kunden = await _repo.alle(suchtext: _suchtext);
    if (!mounted) return;
    setState(() {
      _kunden = kunden;
      _isLoading = false;
    });
  }

  Future<void> _oeffneFormular({Kunde? kunde}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => KundeFormScreen(kunde: kunde)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(Kunde kunde) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kunde löschen?'),
        content: Text('"${kunde.name}" wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (bestaetigt == true && kunde.id != null) {
      await _repo.loeschen(kunde.id!);
      _laden();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kunden')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffneFormular(),
        icon: const Icon(Icons.add),
        label: const Text('Neuer Kunde'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suche nach Name, Ort, Telefon, E-Mail …',
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kunden.isEmpty
                    ? _LeerZustand(hatSuche: _suchtext.isNotEmpty)
                    : RefreshIndicator(
                        onRefresh: _laden,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: _kunden.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final kunde = _kunden[index];
                            return _KundeCard(
                              kunde: kunde,
                              onTap: () => _oeffneFormular(kunde: kunde),
                              onDelete: () => _loeschen(kunde),
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

class _KundeCard extends StatelessWidget {
  final Kunde kunde;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _KundeCard({
    required this.kunde,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(kunde.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Löschung läuft über den Bestätigungsdialog in onDelete
      },
      child: Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(
              kunde.name.isNotEmpty ? kunde.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(kunde.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            [
              if (kunde.adresseKompakt.isNotEmpty) kunde.adresseKompakt,
              if (kunde.telefon != null && kunde.telefon!.isNotEmpty) kunde.telefon!,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: kunde.hatStandort
              ? const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 20)
              : null,
        ),
      ),
    );
  }
}

class _LeerZustand extends StatelessWidget {
  final bool hatSuche;
  const _LeerZustand({required this.hatSuche});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hatSuche ? Icons.search_off : Icons.people_outline,
              size: 56,
              color: Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              hatSuche
                  ? 'Keine Kunden für diese Suche gefunden.'
                  : 'Noch keine Kunden angelegt.\nTippe unten rechts auf "Neuer Kunde".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
