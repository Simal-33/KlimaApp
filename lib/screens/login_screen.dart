import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // TODO: Echte Authentifizierung gegen SQL-Datenbank / Firebase Auth.
    // Aktuell: Mock-Login zur Demonstration der Navigation.
    await Future.delayed(const Duration(milliseconds: 600));

    final mockUser = AppUser(
      id: '1',
      name: 'Max Mustermann',
      email: _emailController.text.trim(),
      role: UserRole.chef,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(currentUser: mockUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Platzhalter für Firmenlogo (aus Einstellungen)
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.ac_unit,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Klima-App',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Montage & Verwaltung für Klimaanlagenbetriebe',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte E-Mail eingeben';
                      }
                      if (!value.contains('@')) {
                        return 'Ungültige E-Mail-Adresse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      return null;
                    },
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(_errorText!,
                        style: const TextStyle(color: AppTheme.danger)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Anmelden'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // TODO: Passwort-Reset implementieren
                    },
                    child: const Text('Passwort vergessen?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
