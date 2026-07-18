import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/termine_repository.dart';
import '../models/termin.dart';
import '../theme/app_theme.dart';
import 'termin_form_screen.dart';

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  final _repo = TermineRepository();
  Map<DateTime, List<Termin>> _gruppiert = {};
  bool _isLoading = true;

  DateTime _fokusTag = DateTime.now();
  DateTime _gewaehlterTag = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    setState(() => _isLoading = true);
    final gruppiert = await _repo.alleGruppiert();
    if (!mounted) return;
    setState(() {
      _gruppiert = gruppiert;
      _isLoading = false;
    });
  }

  List<Termin> _terminefuerTag(DateTime tag) {
    final key = DateTime(tag.year, tag.month, tag.day);
    final liste = _gruppiert[key] ?? [];
    return liste..sort((a, b) => a.datum.compareTo(b.datum));
  }

  Future<void> _neuerTermin() async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TerminFormScreen(vorausgewaehltesDatum: _gewaehlterTag),
      ),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _terminBearbeiten(Termin termin) async {
    final gespeichert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TerminFormScreen(termin: termin)),
    );
    if (gespeichert == true) _laden();
  }

  Future<void> _erledigtTogglen(Termin termin) async {
    await _repo.erledigtSetzen(termin.id!, !termin.erledigt);
    _laden();
  }

  Future<void> _loeschen(Termin termin) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text('"${termin.titel}" wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (bestaetigt == true) {
      await _repo.loeschen(termin.id!);
      _laden();
    }
  }

  Color _farbeFuerTyp(TerminTyp typ) => switch (typ) {
        TerminTyp.montage => AppTheme.primary,
        TerminTyp.wartung => AppTheme.warning,
        TerminTyp.erinnerung => AppTheme.teal,
        TerminTyp.urlaub => AppTheme.success,
      };

  IconData _iconFuerTyp(TerminTyp typ) => switch (typ) {
        TerminTyp.montage => Icons.build_outlined,
        TerminTyp.wartung => Icons.handyman_outlined,
        TerminTyp.erinnerung => Icons.notifications_outlined,
        TerminTyp.urlaub => Icons.beach_access_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final terminHeute = _terminefuerTag(_gewaehlterTag);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neuerTermin,
        icon: const Icon(Icons.add),
        label: const Text('Neuer Termin'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<Termin>(
                  locale: 'de_DE',
                  firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                  focusedDay: _fokusTag,
                  selectedDayPredicate: (day) => isSameDay(_gewaehlterTag, day),
                  calendarFormat: _format,
                  eventLoader: _terminefuerTag,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onFormatChanged: (format) => setState(() => _format = format),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _gewaehlterTag = selected;
                      _fokusTag = focused;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.copper,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: terminHeute.isEmpty
                      ? const Center(
                          child: Text(
                            'Keine Termine an diesem Tag.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: terminHeute.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final t = terminHeute[index];
                            final farbe = _farbeFuerTyp(t.typ);
                            return Dismissible(
                              key: ValueKey(t.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                _loeschen(t);
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
                                  onTap: () => _terminBearbeiten(t),
                                  leading: CircleAvatar(
                                    backgroundColor: farbe.withOpacity(0.15),
                                    child: Icon(_iconFuerTyp(t.typ), color: farbe, size: 20),
                                  ),
                                  title: Text(
                                    t.titel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: t.erledigt ? TextDecoration.lineThrough : null,
                                      color: t.erledigt ? Colors.black38 : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    t.datum.hour == 0 && t.datum.minute == 0
                                        ? t.typ.label
                                        : '${t.typ.label} · ${t.datum.hour.toString().padLeft(2, '0')}:${t.datum.minute.toString().padLeft(2, '0')} Uhr',
                                  ),
                                  trailing: Checkbox(
                                    value: t.erledigt,
                                    onChanged: (_) => _erledigtTogglen(t),
                                    activeColor: AppTheme.success,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
