import 'package:flutter/material.dart';
import '../data/auftraege_repository.dart';
import '../models/auftrag.dart';
import '../theme/app_theme.dart';
import 'auftrag_form_screen.dart';

class AuftraegeListScreen extends StatefulWidget {
  const AuftraegeListScreen({super.key});

  @override
  State<AuftraegeListScreen> createState() => _AuftraegeListScreenState();
}

class _AuftraegeListScreenState extends State<AuftraegeListScreen> {
  final _repo = AuftraegeRepository();
  List<AuftragUebersicht> _auftraege = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final auftraege = await _repo.uebersicht();
    if (!mounted) return;
    setState(() {
      _auftraege = auftraege;
      _isLoading = false;
    });
  }

  Future<void> _oeffnen({int? auftragId}) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AuftragFormScreen(auftragId: auftragId)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _loeschen(AuftragUebersicht auftrag) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auftrag löschen?'),
        content: Text('Der Auftrag für ${auftrag.kundeName} wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Löschen',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (bestaetigt == true) {
      await _repo.loeschen(auftrag.id);
      _laden();
    }
  }

  Color _farbeFuerStatus(AuftragStatus status) => switch (status) {
        AuftragStatus.geplant => AppTheme.primary,
        AuftragStatus.inArbeit => AppTheme.copper,
        AuftragStatus.erledigt => AppTheme.teal,
        AuftragStatus.abgerechnet => AppTheme.success,
      };

  String _datumText(DateTime? datum) {
    if (datum == null) return 'Noch kein Termin';
    return '${datum.day.toString().padLeft(2, '0')}.'
        '${datum.month.toString().padLeft(2, '0')}.${datum.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aufträge')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffnen(),
        icon: const Icon(Icons.add),
        label: const Text('Neuer Auftrag'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auftraege.isEmpty
              ? const _LeerZustand()
              : RefreshIndicator(
                  onRefresh: _laden,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                    itemCount: _auftraege.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final auftrag = _auftraege[index];
                      final farbe = _farbeFuerStatus(auftrag.status);
                      return Dismissible(
                        key: ValueKey(auftrag.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          _loeschen(auftrag);
                          return false;
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        child: Card(
                          child: ListTile(
                            onTap: () => _oeffnen(auftragId: auftrag.id),
                            leading: CircleAvatar(
                              backgroundColor: farbe.withOpacity(0.12),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: farbe,
                              ),
                            ),
                            title: Text(
                              auftrag.kundeName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                _datumText(auftrag.termin),
                                if (auftrag.monteurName != null)
                                  auftrag.monteurName!,
                                if (auftrag.angebotsnummer != null)
                                  auftrag.angebotsnummer!,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: farbe.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                auftrag.status.label,
                                style: TextStyle(
                                  color: farbe,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _LeerZustand extends StatelessWidget {
  const _LeerZustand();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Colors.black26,
            ),
            SizedBox(height: 12),
            Text(
              'Noch keine Aufträge angelegt.\nTippe unten rechts auf "Neuer Auftrag".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
