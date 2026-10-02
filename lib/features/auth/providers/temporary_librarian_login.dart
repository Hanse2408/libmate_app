// TEMPORARY LIBRARIAN LOGIN
// Replace with Firebase Auth when backend/database integration is available.
//
// Development-only credentials so the Librarian UI can be used before the
// team's Firebase project is connected. This is NOT production
// authentication: delete this file and its uses in AuthProvider and
// LoginScreen when real librarian accounts exist in Firebase.

import '../../../models/user.dart';

class TemporaryLibrarianLogin {
  const TemporaryLibrarianLogin._();

  static const String _email = 'janith@gmail.com';
  static const String _password = 'janith@123';

  /// True when the entered credentials match the temporary librarian.
  /// The email is compared case-insensitively, the password exactly.
  static bool matches(String email, String password) {
    return email.trim().toLowerCase() == _email && password == _password;
  }

  /// Profile used for the temporary session (shown on the dashboard).
  static const AppUser profile = AppUser(
    uid: 'temporary-librarian',
    name: 'Janith',
    email: _email,
    role: UserRole.librarian,
  );
}
