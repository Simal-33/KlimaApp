import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }
  runApp(const KlimaApp());
}

class KlimaApp extends StatelessWidget {
  const KlimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klima-App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginScreen(),
    );
  }
}
