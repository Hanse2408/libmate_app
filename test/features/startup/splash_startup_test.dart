import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/app/startup/app_startup.dart';
import 'package:libmate_app/app/theme/app_colors.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/onboarding/screens/get_started_screen.dart';
import 'package:libmate_app/features/splash/screens/splash_screen.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

import '../library_sync/library_test_support.dart';

/// Start-up: splash first, then the existing auth / role routing.

class _FakeUser implements User {
  @override
  String get uid => 'user-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Reports the saved sign-in state when told to, like Firebase Auth does
/// shortly after start-up.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<User?>.broadcast();
  User? _current;

  void restore({required bool signedIn}) {
    _current = signedIn ? _FakeUser() : null;
    _controller.add(_current);
  }

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User?> signIn({required String email, required String password}) async => null;

  @override
  Future<User?> signUp({required String email, required String password}) async => null;

  @override
  Future<void> signOut() async => restore(signedIn: false);
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.role);
  final UserRole role;

  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async =>
      AppUser(uid: uid, name: 'Test', email: 'test@libmate.test', role: role);
}

const _minimum = Duration(milliseconds: 1500);

void main() {
  late _FakeAuthRepository auth;

  Future<GoRouter> pumpApp(WidgetTester tester, {UserRole role = UserRole.student}) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    auth = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: auth,
      userRepository: _FakeUserRepository(role),
    );
    final startup = AppStartup(auth: authProvider, minimumDisplay: _minimum);
    addTearDown(startup.dispose);
    final router = AppRouter(
      authProvider,
      startup: startup,
      createLibrarianRepository: LibrarianMockRepository.new,
      createStudentLibrary: () => studentRepo(FakeFirebaseFirestore()),
    ).router;
    // The device is in dark mode: the splash must still be light.
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
    await tester.pump();
    return router;
  }

  String path(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

  void expectSplash() {
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('libmate-splash-logo')), findsOneWidget);
  }

  testWidgets('splash shows the LibMate logo first, in the light theme', (tester) async {
    final router = await pumpApp(tester);
    expect(path(router), AppRoutes.splash);
    expectSplash();
    final logo = tester.widget<Image>(find.byKey(const ValueKey('libmate-splash-logo')));
    expect((logo.image as AssetImage).assetName, 'assets/logos/libmate_logo.png');
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.lightCard);
    expect(find.text('Welcome Back!'), findsNothing);
    await tester.pump(const Duration(seconds: 8)); // let start-up finish
  });

  testWidgets('logged out: splash, then Get Started, then (button) Login', (tester) async {
    final router = await pumpApp(tester);
    auth.restore(signedIn: false); // Firebase: nobody signed in
    await tester.pump(const Duration(milliseconds: 1000));
    expectSplash(); // not yet: minimum display
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(path(router), AppRoutes.getStarted);
    expect(find.byType(GetStartedScreen), findsOneWidget);
    expect(find.text('Your library,\nwithin reach.'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsNothing);

    // Same logo asset as the splash; light even though the device is dark.
    final logo = tester.widget<Image>(find.byKey(const ValueKey('get-started-logo')));
    expect((logo.image as AssetImage).assetName, SplashScreen.logoAsset);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(path(router), AppRoutes.login);
    expect(find.text('Welcome Back!'), findsOneWidget); // the existing Login
  });

  testWidgets('a signed-in user opening Get Started goes to their home', (tester) async {
    final router = await pumpApp(tester, role: UserRole.manager);
    auth.restore(signedIn: true);
    await tester.pump(_minimum);
    await tester.pump();
    router.go(AppRoutes.getStarted);
    await tester.pumpAndSettle();
    expect(path(router), AppRoutes.managerDashboard);
  });

  testWidgets('slow start-up: splash stays until the sign-in state is known', (tester) async {
    final router = await pumpApp(tester, role: UserRole.librarian);
    await tester.pump(const Duration(seconds: 3));
    expectSplash(); // minimum passed, Firebase has not answered yet
    // A deep link / refresh while starting waits on the splash too.
    router.go(AppRoutes.managerDashboard);
    await tester.pump();
    expect(path(router), AppRoutes.splash);

    auth.restore(signedIn: true); // saved session restored
    await tester.pump();
    await tester.pumpAndSettle();
    expect(path(router), AppRoutes.librarianDashboard); // no Login flash
  });

  for (final (role, home) in [
    (UserRole.student, AppRoutes.studentHome),
    (UserRole.librarian, AppRoutes.librarianDashboard),
    (UserRole.manager, AppRoutes.managerDashboard),
  ]) {
    testWidgets('signed-in ${role.name}: splash, then their home', (tester) async {
      final router = await pumpApp(tester, role: role);
      auth.restore(signedIn: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(path(router), AppRoutes.splash);
      await tester.pump(_minimum);
      await tester.pump();
      expect(path(router), home);
      expect(find.byType(SplashScreen), findsNothing);
    });
  }

  testWidgets('Firebase never answering does not keep the splash forever', (tester) async {
    final router = await pumpApp(tester);
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(path(router), AppRoutes.getStarted);
  });

  testWidgets('without a start-up gate the router behaves as before', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      userRepository: _FakeUserRepository(UserRole.student),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(path(router), AppRoutes.login);
  });
}
