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
      _isAuthResolved = true;
      _user = user;
      _profile = null;
      if (user == null) {
        _profile = null;
        notifyListeners();
      } else {
        notifyListeners();
        fetchCurrentUserProfile();
      }
    });
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  late final StreamSubscription<User?> _authStateSubscription;

  User? _user;
  bool _isAuthResolved = false;
  AppUser? _profile;
  bool _isLoading = false;
  bool _isProfileLoading = false;
  String? _errorMessage;

  User? get user => _user;
  AppUser? get profile => _profile;
  UserRole? get role => _profile?.role;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _user != null;

  /// True once Firebase has reported the initial sign-in state (on web the
  /// saved session is restored asynchronously after start-up).
  bool get isAuthResolved => _isAuthResolved;

  /// Single login form for every role. The Firestore `role` on `users/{uid}`
  /// decides the destination (see [fetchCurrentUserProfile]); the user never
  /// picks it themselves.
  Future<bool> signIn({required String email, required String password}) async {
    _profile = null;
    final authenticated = await _runAuthAction(
      () => _authRepository.signIn(email: email, password: password),
    );
    if (!authenticated || _user == null) return false;
    await fetchCurrentUserProfile();
    return _user != null && _profile?.accountStatus == AccountStatus.active;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
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

  // Security: public sign-up always creates a STUDENT account. Librarian and
  // manager accounts are provisioned separately and must never be self-assigned.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
  }) async {
    final success = await _runAuthAction(
      () => _authRepository.signUp(email: email, password: password),
    );
    if (success && _user != null) {
      final now = DateTime.now();
      final newProfile = AppUser(
        uid: _user!.uid,
        name: name,
        studentId: studentId,
        email: email,
        role: UserRole.student,
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

  /// Fetches the signed-in user's Firestore profile and decides, from the
  /// Firestore `role` and `accountStatus` alone, whether sign-in may
  /// continue. The user never picks their own role or destination.
  Future<void> fetchCurrentUserProfile() async {
    final uid = _user?.uid;
    if (uid == null) return;
    _isProfileLoading = true;
    notifyListeners();
    try {
      final loadedProfile = await _userRepository.getUserProfile(uid);
      if (_user?.uid != uid) return;
      if (loadedProfile == null) {
        await _rejectLogin(
          'User profile could not be found. Please contact the library.',
        );
        return;
      }
      switch (loadedProfile.accountStatus) {
        case AccountStatus.inactive:
          await _rejectLogin(
            'This account is inactive. Please contact the library.',
          );
          return;
        case AccountStatus.suspended:
          await _rejectLogin(
            'This account is inactive. Please contact the library.',
          );
          return;
        case AccountStatus.active:
          _profile = loadedProfile;
      }
    } on InvalidUserRoleException {
      await _rejectLogin(
        'User profile could not be found. Please contact the library.',
      );
    } catch (_) {
      _profile = null;
      _errorMessage = 'Failed to load user profile.';
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  /// Signs out a user whose profile/role/account-status did not pass the
  /// login checks above, so they never reach any dashboard.
  Future<void> _rejectLogin(String message) async {
    _profile = null;
    _errorMessage = message;
    try {
      await _authRepository.signOut();
    } catch (_) {
      _errorMessage = '$message Sign-out failed; please restart the app.';
    } finally {
      _user = null;
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
