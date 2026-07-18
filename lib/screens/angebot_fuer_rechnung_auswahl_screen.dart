import 'package:flutter/material.dart';
import '../data/angebote_repository.dart';
import '../models/angebot.dart';
import '../theme/app_theme.dart';

/// Zeigt alle angenommenen Angebote zur Auswahl an, um daraus eine
/// Rechnung zu erzeugen. Gibt die gewählte Angebots-Id zurück.
class AngebotFuerRechnungAuswahlScreen extends StatefulWidget {
  const AngebotFuerRechnungAuswahlScreen({super.key});

  @override
  State<AngebotFuerRechnungAuswahlScreen> createState() =>
      _AngebotFuerRechnungAuswahlScreenState();
}

class _AngebotFuerRechnungAuswahlScreenState
    extends State<AngebotFuerRechnungAuswahlScreen> {
  final _repo = AngeboteRepository();
  List<AngebotUebersicht> _angenommene = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    final alle = await _repo.uebersicht();
    if (!mounted) return;
    setState(() {
      _angenommene = alle.where((a) => a.status == AngebotStatus.angenommen).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Angebot auswählen')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _angenommene.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Keine angenommenen Angebote gefunden.\n'
                      'Setze im Angebots-Modul zuerst den Status auf "Angenommen".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _angenommene.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final a = _angenommene[index];
                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.of(context).pop(a.id),
                        leading: const Icon(Icons.description_outlined, color: AppTheme.success),
                        title: Text(a.nummer, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(a.kundeName),
                        trailing: Text('${a.gesamtpreis.toStringAsFixed(2)} €',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
    );
  }
}
