import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

class _FakeUser implements User {
  @override
  String get uid => 'manager-uid';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<User?>.broadcast();
  User? _current;

  void emitSignedIn() {
    _current = _FakeUser();
    _controller.add(_current);
  }

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<User?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async => const AppUser(
    uid: 'manager-uid',
    name: 'Library Manager',
    email: 'manager@libmate.com',
    role: UserRole.manager,
  );
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void _expectManagerLightTheme(WidgetTester tester) {
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Theme && widget.data.brightness == Brightness.light,
    ),
    findsWidgets,
  );
}

void main() {
  testWidgets('manager workflow stays light under system dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.managerDashboard);
    _expectManagerLightTheme(tester);

    router.go(AppRoutes.managerReservations);
    await tester.pumpAndSettle();
    _expectManagerLightTheme(tester);
    final conflictReservation = find.ancestor(
      of: find.text('RES-1023').first,
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(conflictReservation);
    await tester.tap(conflictReservation.hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Book Information'), findsOneWidget);
    _expectManagerLightTheme(tester);

    await tester.tap(find.text('Resolve Conflict'));
    await tester.pumpAndSettle();
    _expectManagerLightTheme(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Current Seat'), findsOneWidget);
    _expectManagerLightTheme(tester);

    await tester.tap(find.text('Confirm Reassignment'));
    await tester.pumpAndSettle();
    expect(find.text('Conflict Resolved'), findsOneWidget);
    expect(find.text('A08'), findsOneWidget);
    _expectManagerLightTheme(tester);

    await tester.tap(find.text('Back to Reservations'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.managerReservations);
    expect(find.text('RES-1024'), findsOneWidget);
  });

  testWidgets('manager can create, edit and deactivate a user locally', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();

    router.go(AppRoutes.managerUsers);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add User'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'New Manager Test',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'new.manager.test@libmate.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'TEST-MGR-001');
    await tester.tap(find.byType(DropdownButtonFormField<UserRole>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Librarian').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create User'));
    await tester.pumpAndSettle();

    expect(find.text('New Manager Test'), findsOneWidget);
    await tester.tap(
      find
          .ancestor(
            of: find.text('New Manager Test'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Librarian'), findsOneWidget);

    await tester.tap(find.text('Edit User'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Manager');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Manager'), findsOneWidget);

    await tester.tap(find.text('Deactivate User'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate').last);
    await tester.pumpAndSettle();
    expect(find.text('Updated Manager'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('reports open preview and honest export confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();

    router.go(AppRoutes.managerReports);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Popular Books').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview / Export Report'));
    await tester.pumpAndSettle();
    expect(find.text('Popular Books Report'), findsOneWidget);
    await tester.tap(find.text('Export Report'));
    await tester.pumpAndSettle();
    expect(find.text('Export Preview Ready'), findsOneWidget);
    expect(
      find.text('This is a UI demo. No CSV file has been created yet.'),
      findsOneWidget,
    );
  });

  testWidgets('policy screen provides back and home navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();

    router.go(AppRoutes.managerPolicies);
    await tester.pumpAndSettle();
    expect(find.text('Book Reservation Limit'), findsOneWidget);
    expect(find.byTooltip('Back to dashboard'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Home'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Home'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.managerDashboard);

    router.go(AppRoutes.managerPolicies);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.managerDashboard);
  });

  testWidgets('dashboard fits a phone layout and exposes manager shortcuts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    expect(find.text('Manager Dashboard'), findsOneWidget);
    expect(find.text('People at a glance'), findsOneWidget);
    expect(find.text('Manage Users'), findsOneWidget);
    expect(find.text('Policy & Limits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager profile logs out to role selection', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(authProvider).router;
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('My Profile'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.managerProfile);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Library Manager'), findsOneWidget);
    expect(find.text('manager@libmate.com'), findsWidgets);

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(
      find.text('You will be returned to role selection.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Log Out').last);
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.roleSelection);
    expect(find.text('Login as'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Librarian'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
  });
}
