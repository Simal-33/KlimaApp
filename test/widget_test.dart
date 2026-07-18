import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klima_app/main.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KlimaApp());

    expect(find.text('Klima-App'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Anmelden'), findsOneWidget);
  });
}
