// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';

import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/main.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

void main() {
  testWidgets('Unauthenticated users can navigate between auth screens', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      userRepository: _FakeUserRepository(),
    );
    final appRouter = AppRouter(authProvider);
    await tester.pumpWidget(MyApp(router: appRouter.router));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);

    final signupLink = find.text('Sign Up');
    await tester.ensureVisible(signupLink);
    await tester.tap(signupLink);
    await tester.pumpAndSettle();
    expect(find.text('Create Your Account'), findsOneWidget);

    final loginLink = find.text('Login');
    await tester.ensureVisible(loginLink);
    await tester.tap(loginLink);
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.empty();

  @override
  Future<User?> signIn({required String email, required String password}) async {
    return null;
  }

  @override
  Future<User?> signUp({required String email, required String password}) async {
    return null;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async => null;
}

