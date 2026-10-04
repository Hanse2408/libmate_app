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
}
