import 'package:flutter/material.dart';
import '../data/kunden_repository.dart';
import '../data/termine_repository.dart';
import '../models/kunde.dart';
import '../models/termin.dart';
import '../theme/app_theme.dart';

class TerminFormScreen extends StatefulWidget {
  final Termin? termin;
  final DateTime? vorausgewaehltesDatum;

  const TerminFormScreen({super.key, this.termin, this.vorausgewaehltesDatum});

  @override
  State<TerminFormScreen> createState() => _TerminFormScreenState();
}

class _TerminFormScreenState extends State<TerminFormScreen> {
  final _repo = TermineRepository();
  final _kundenRepo = KundenRepository();

  final _titelController = TextEditingController();
  final _notizController = TextEditingController();

  TerminTyp _typ = TerminTyp.montage;
  late DateTime _datum;
  TimeOfDay? _uhrzeit;
  List<Kunde> _kunden = [];
  Kunde? _gewaehlterKunde;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEdit => widget.termin != null;

  @override
  void initState() {
    super.initState();
    final t = widget.termin;
    _titelController.text = t?.titel ?? '';
    _notizController.text = t?.notiz ?? '';
    _typ = t?.typ ?? TerminTyp.montage;
    _datum = t?.datum ?? widget.vorausgewaehltesDatum ?? DateTime.now();
    if (t != null && (t.datum.hour != 0 || t.datum.minute != 0)) {
      _uhrzeit = TimeOfDay(hour: t.datum.hour, minute: t.datum.minute);
    }
    _laden();
  }

  Future<void> _laden() async {
    _kunden = await _kundenRepo.alle();
    if (widget.termin?.kundeId != null) {
      _gewaehlterKunde = _kunden.where((k) => k.id == widget.termin!.kundeId).firstOrNull;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titelController.dispose();
    _notizController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (gewaehlt != null) setState(() => _datum = gewaehlt);
  }

  Future<void> _uhrzeitWaehlen() async {
    final gewaehlt = await showTimePicker(
      context: context,
      initialTime: _uhrzeit ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (gewaehlt != null) setState(() => _uhrzeit = gewaehlt);
  }

  Future<void> _speichern() async {
    if (_titelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte einen Titel eingeben')));
      return;
    }

    setState(() => _isSaving = true);
    final vollesDatum = DateTime(
      _datum.year, _datum.month, _datum.day,
      _uhrzeit?.hour ?? 0, _uhrzeit?.minute ?? 0,
    );

    final termin = Termin(
      id: widget.termin?.id,
      titel: _titelController.text.trim(),
      typ: _typ,
      datum: vollesDatum,
      kundeId: _gewaehlterKunde?.id,
      notiz: _notizController.text.trim().isEmpty ? null : _notizController.text.trim(),
      erledigt: widget.termin?.erledigt ?? false,
    );

    try {
      if (_isEdit) {
        await _repo.aktualisieren(termin);
      } else {
        await _repo.anlegen(termin);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  IconData _iconFuerTyp(TerminTyp typ) => switch (typ) {
        TerminTyp.montage => Icons.build_outlined,
        TerminTyp.wartung => Icons.handyman_outlined,
        TerminTyp.erinnerung => Icons.notifications_outlined,
        TerminTyp.urlaub => Icons.beach_access_outlined,
      };

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Termin bearbeiten' : 'Neuer Termin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: TerminTyp.values.map((typ) {
              final aktiv = _typ == typ;
              return ChoiceChip(
                avatar: Icon(_iconFuerTyp(typ), size: 16, color: aktiv ? AppTheme.primary : Colors.black45),
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
          const SizedBox(height: 20),
          TextField(
            controller: _titelController,
            decoration: const InputDecoration(labelText: 'Titel *'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _datumWaehlen,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Datum'),
                    child: Text(
                      '${_datum.day.toString().padLeft(2, '0')}.${_datum.month.toString().padLeft(2, '0')}.${_datum.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _uhrzeitWaehlen,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Uhrzeit'),
                    child: Text(_uhrzeit != null
                        ? '${_uhrzeit!.hour.toString().padLeft(2, '0')}:${_uhrzeit!.minute.toString().padLeft(2, '0')}'
                        : 'Ganztägig'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Kunde?>(
            initialValue: _gewaehlterKunde,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Kunde (optional)'),
            items: [
              const DropdownMenuItem<Kunde?>(value: null, child: Text('Kein Kunde')),
              ..._kunden.map((k) => DropdownMenuItem<Kunde?>(value: k, child: Text(k.name))),
            ],
            onChanged: (k) => setState(() => _gewaehlterKunde = k),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notizController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notiz'),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _speichern,
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: Text(_isEdit ? 'Änderungen speichern' : 'Termin anlegen'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
