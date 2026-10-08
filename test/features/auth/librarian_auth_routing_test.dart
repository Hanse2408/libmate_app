import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

/// Librarian routes with the real (Firebase) AuthProvider and router, using
/// fake repositories in the same style as test/widget_test.dart.
class _FakeUser implements User {
  @override
  String get uid => 'librarian-uid';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Behaves like Firebase Auth: signing in/out is reported on the stream.
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

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async => const AppUser(
    uid: 'librarian-uid',
    name: 'Janith',
    email: 'janith@gmail.com',
    role: UserRole.librarian,
  );
}

Future<(GoRouter, _FakeAuthRepository)> _pumpApp(WidgetTester tester) async {
  // Same width as test/widget_test.dart (the login row is tight on narrow test fonts).
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final authRepository = _FakeAuthRepository();
  final authProvider = AuthProvider(
    authRepository: authRepository,
    userRepository: _FakeUserRepository(),
  );
  // In-memory Librarian data: these tests are about routing, not Firestore.
  final router = AppRouter(
    authProvider,
    createLibrarianRepository: LibrarianMockRepository.new,
  ).router;
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return (router, authRepository);
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

const _librarianPaths = [
  LibrarianRoutes.dashboard,
  LibrarianRoutes.reservations,
  LibrarianRoutes.books,
  LibrarianRoutes.seats,
  LibrarianRoutes.notifications,
  LibrarianRoutes.borrowings,
  LibrarianRoutes.members,
  LibrarianRoutes.reports,
  LibrarianRoutes.settings,
];

void main() {
  testWidgets('signed-out users are sent to Login from Librarian routes', (
    tester,
  ) async {
    final (router, _) = await _pumpApp(tester);
    expect(_path(router), AppRoutes.login);

    for (final path in _librarianPaths) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(_path(router), AppRoutes.login, reason: path);
    }
  });

  testWidgets(
    'a librarian account opens the Dashboard and every Librarian section',
    (tester) async {
      final (router, auth) = await _pumpApp(tester);

      auth.emitSignedIn(); // Firebase reports a signed-in user with role librarian
      await tester.pumpAndSettle();
      expect(_path(router), LibrarianRoutes.dashboard);
      expect(find.textContaining(', Janith'), findsOneWidget);

      for (final path in _librarianPaths) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(_path(router), path);
      }

      // A librarian cannot open another role's area.
      router.go(AppRoutes.studentHome);
      await tester.pumpAndSettle();
      expect(_path(router), LibrarianRoutes.dashboard);
    },
  );

  testWidgets('signing out from Settings returns to Login', (tester) async {
    final (router, auth) = await _pumpApp(tester);
    auth.emitSignedIn();
    await tester.pumpAndSettle();

    router.go(LibrarianRoutes.settings);
    await tester.pumpAndSettle();
    final logOut = find.text('Log Out');
    await tester.scrollUntilVisible(
      logOut,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(logOut); // not hidden behind the bottom nav
    await tester.pumpAndSettle();
    await tester.tap(logOut.hitTestable());
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.login);
  });
}
