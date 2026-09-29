import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/auth_service.dart';

/// Sits between AuthProvider and AuthService. Holds no Firebase calls itself.
class AuthRepository {
  AuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<User?> signIn({required String email, required String password}) {
    return _authService.signIn(email: email, password: password);
  }

  Future<User?> signUp({required String email, required String password}) {
    return _authService.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return _authService.signOut();
  }
}
