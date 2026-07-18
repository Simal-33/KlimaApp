import 'package:flutter/material.dart';

/// Platzhalter für Module, die in den nächsten Schritten
/// (Kunden, Angebote, Rechnungen, ...) implementiert werden.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              '$title – Modul folgt in einem der nächsten Schritte',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
