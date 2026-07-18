import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/coming_soon_screen.dart';
import 'angebote_list_screen.dart';
import 'auftraege_list_screen.dart';
import 'einstellungen_screen.dart';
import 'excel_screen.dart';
import 'geraete_list_screen.dart';
import 'kalender_screen.dart';
import 'kunden_list_screen.dart';
import 'lagerverwaltung_screen.dart';
import 'login_screen.dart';
import 'material_list_screen.dart';
import 'monteure_list_screen.dart';
import 'rechnungen_list_screen.dart';

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isReady;

  const _DashboardItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color, {
    this.isReady = true,
  });
}

class _DashboardMetric {
  final String value;
  final String label;
  final IconData icon;

  const _DashboardMetric(this.value, this.label, this.icon);
}

class DashboardScreen extends StatelessWidget {
  final AppUser currentUser;

  const DashboardScreen({super.key, required this.currentUser});

  static const List<_DashboardMetric> _metrics = [
    _DashboardMetric('8', 'offene Angebote', Icons.description_outlined),
    _DashboardMetric('12', 'aktive Aufträge', Icons.assignment_outlined),
    _DashboardMetric('3', 'Termine heute', Icons.calendar_today_outlined),
  ];

  static const List<_DashboardItem> _items = [
    _DashboardItem(
      'Angebote',
      'Kalkulieren, senden und nachfassen',
      Icons.description_outlined,
      Color(0xFF0D6EFD),
    ),
    _DashboardItem(
      'Aufträge',
      'Montage und Service im Blick',
      Icons.assignment_outlined,
      Color(0xFF7C3AED),
    ),
    _DashboardItem(
      'Kunden',
      'Kontakte, Standorte und Geräte',
      Icons.people_outline,
      Color(0xFF17B8A6),
    ),
    _DashboardItem(
      'Lagerbestand',
      'Materialbestand und Bewegungen',
      Icons.inventory_2_outlined,
      Color(0xFFC6784A),
    ),
    _DashboardItem(
      'Monteure',
      'Teamdaten und Einsatzplanung',
      Icons.engineering_outlined,
      Color(0xFF6F42C1),
    ),
    _DashboardItem(
      'Kalender',
      'Termine, Wartungen und Urlaub',
      Icons.calendar_month_outlined,
      Color(0xFFDC3545),
    ),
    _DashboardItem(
      'Rechnungen',
      'Positionen, PDF und Zahlungslauf',
      Icons.receipt_long_outlined,
      Color(0xFF198754),
    ),
    _DashboardItem(
      'Statistiken',
      'Auswertungen und Kennzahlen',
      Icons.bar_chart_outlined,
      Color(0xFF0891B2),
      isReady: false,
    ),
  ];

  void _openModule(BuildContext context, _DashboardItem item) {
    final Widget screen = switch (item.title) {
      'Kunden' => const KundenListScreen(),
      'Geräte' => const GeraeteListScreen(),
      'Material' => const MaterialListScreen(),
      'Aufträge' => const AuftraegeListScreen(),
      'Angebote' => const AngeboteListScreen(),
      'Rechnungen' => const RechnungenListScreen(),
      'Kalender' => const KalenderScreen(),
      'Monteure' => const MonteureListScreen(),
      'Lagerverwaltung' => const LagerverwaltungScreen(),
      'Lagerbestand' => const LagerverwaltungScreen(),
      'Excel Import/Export' => const ExcelScreen(),
      'Einstellungen' => const EinstellungenScreen(),
      _ => ComingSoonScreen(title: item.title, icon: item.icon),
    };

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  int _crossAxisCount(double width) {
    if (width >= 1180) return 4;
    if (width >= 820) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openModule(
              context,
              const _DashboardItem(
                'Einstellungen',
                'Firma, Nummernkreise und Vorlagen',
                Icons.settings,
                Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _AppDrawer(
        currentUser: currentUser,
        onLogout: () => _logout(context),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = _crossAxisCount(width);
          final isWide = width >= 760;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 16,
                  16,
                  isWide ? 24 : 16,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: _DashboardHeader(
                    currentUser: currentUser,
                    metrics: _metrics,
                    isWide: isWide,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 16,
                  8,
                  isWide ? 24 : 16,
                  96,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.45 : 2.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _items[index];
                      return _DashboardCard(
                        item: item,
                        onTap: () => _openModule(context, item),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AppUser currentUser;
  final List<_DashboardMetric> metrics;
  final bool isWide;

  const _DashboardHeader({
    required this.currentUser,
    required this.metrics,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Willkommen, ${currentUser.name}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${currentUser.role.label} · Arbeitsübersicht',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ],
    );

    final metricRow = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map((metric) => _MetricChip(metric: metric, compact: !isWide))
          .toList(),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: greeting),
                metricRow,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                greeting,
                const SizedBox(height: 16),
                metricRow,
              ],
            ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final _DashboardMetric metric;
  final bool compact;

  const _MetricChip({required this.metric, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 148 : 164,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(metric.icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;
  final VoidCallback onTap;

  const _DashboardCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 23),
                  ),
                  const Spacer(),
                  if (!item.isReady)
                    const _StatusPill(label: 'Bald')
                  else
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: item.color,
                      size: 20,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A6100),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Seitliches Menü mit Zugriff auf alle Module.
class _AppDrawer extends StatelessWidget {
  final AppUser currentUser;
  final VoidCallback onLogout;

  const _AppDrawer({required this.currentUser, required this.onLogout});

  static const List<_DashboardItem> _menuItems = [
    _DashboardItem('Kunden', 'Kontakte', Icons.people_outline, AppTheme.primary),
    _DashboardItem('Geräte', 'Anlagen', Icons.ac_unit, AppTheme.primary),
    _DashboardItem('Material', 'Artikel', Icons.category_outlined, AppTheme.primary),
    _DashboardItem(
      'Aufträge',
      'Einsätze',
      Icons.assignment_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Lagerverwaltung',
      'Bestand',
      Icons.warehouse_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Lieferanten',
      'Einkauf',
      Icons.local_shipping_outlined,
      AppTheme.primary,
      isReady: false,
    ),
    _DashboardItem(
      'Angebote',
      'Verkauf',
      Icons.description_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Rechnungen',
      'Faktura',
      Icons.receipt_long_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Kalender',
      'Termine',
      Icons.calendar_month_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Monteure',
      'Team',
      Icons.engineering_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Wartungsverträge',
      'Service',
      Icons.build_circle_outlined,
      AppTheme.primary,
      isReady: false,
    ),
    _DashboardItem(
      'Excel Import/Export',
      'Daten',
      Icons.grid_on_outlined,
      AppTheme.primary,
    ),
    _DashboardItem(
      'Statistiken',
      'Kennzahlen',
      Icons.bar_chart_outlined,
      AppTheme.primary,
      isReady: false,
    ),
    _DashboardItem(
      'Einstellungen',
      'System',
      Icons.settings_outlined,
      AppTheme.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              color: AppTheme.primary,
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          currentUser.role.label,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return ListTile(
                    leading: Icon(item.icon, color: AppTheme.textMuted),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    trailing: item.isReady
                        ? null
                        : const _StatusPill(label: 'Bald'),
                    onTap: () {
                      Navigator.pop(context);
                      final Widget screen = switch (item.title) {
                        'Kunden' => const KundenListScreen(),
                        'Geräte' => const GeraeteListScreen(),
                        'Material' => const MaterialListScreen(),
                        'Aufträge' => const AuftraegeListScreen(),
                        'Angebote' => const AngeboteListScreen(),
                        'Rechnungen' => const RechnungenListScreen(),
                        'Kalender' => const KalenderScreen(),
                        'Monteure' => const MonteureListScreen(),
                        'Lagerverwaltung' => const LagerverwaltungScreen(),
                        'Excel Import/Export' => const ExcelScreen(),
                        'Einstellungen' => const EinstellungenScreen(),
                        _ => ComingSoonScreen(
                            title: item.title, icon: item.icon),
                      };
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => screen),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: const Text(
                'Abmelden',
                style: TextStyle(color: AppTheme.danger),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
