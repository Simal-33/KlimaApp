/// Benutzerrollen laut Funktionsumfang (siehe "Benutzer" im Konzept).
enum UserRole { administrator, buero, monteur, chef }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.buero:
        return 'Büro';
      case UserRole.monteur:
        return 'Monteur';
      case UserRole.chef:
        return 'Chef';
    }
  }
}

/// Platzhalter-Modell für den eingeloggten Benutzer.
/// Wird später durch echte Authentifizierung (Firebase/SQL) ersetzt.
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}
