import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/user.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart';

/// Manages auth loading/user/error state for the UI layer.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? authRepository, UserRepository? userRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      _userRepository = userRepository ?? UserRepository() {
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  late final StreamSubscription<User?> _authStateSubscription;

  User? _user;
  AppUser? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  AppUser? get profile => _profile;
  UserRole? get role => _profile?.role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _user != null;

  Future<bool> signIn({required String email, required String password}) {
    return _runAuthAction(
      () => _authRepository.signIn(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
  }) async {
    final success = await _runAuthAction(
      () => _authRepository.signUp(email: email, password: password),
    );
    if (success && _user != null) {
      final now = DateTime.now();
      final newProfile = AppUser(
        uid: _user!.uid,
        name: name,
        email: email,
        role: role,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _userRepository.createUserProfile(newProfile);
        _profile = newProfile;
      } catch (_) {
        _errorMessage = 'Account created but profile setup failed.';
      }
      notifyListeners();
    }
    return success;
  }

  /// Fetches the signed-in user's Firestore profile and role.
  Future<void> fetchCurrentUserProfile() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      _profile = await _userRepository.getUserProfile(uid);
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Failed to load user profile.';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.signOut();
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _runAuthAction(Future<User?> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await action();
      _user = user;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapErrorMessage(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
