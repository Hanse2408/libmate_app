import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/models/user.dart';

import '../librarian/librarian_test_helpers.dart';

/// Starts the whole app router (real redirects) with Firebase faked out.
Future<GoRouter> _pumpApp(WidgetTester tester, {Size size = const Size(400, 1100)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = AppRouter(buildFakeAuthProvider()).router;
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _login(
  WidgetTester tester, {
  String email = 'janith@gmail.com',
  String password = 'janith@123',
  bool chooseLibrarian = true,
}) async {
  if (chooseLibrarian) {
    await tester.tap(find.text('Librarian'));
    await tester.pumpAndSettle();
  }
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  final loginButton = find.widgetWithText(FilledButton, 'Login');
  await tester.ensureVisible(loginButton);
  await tester.pumpAndSettle();
  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Account'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out'));
  await tester.pumpAndSettle();
}

void main() {
  group('Temporary librarian session (AuthProvider)', () {
    test('accepts only the temporary credentials and signs out', () {
      final auth = buildFakeAuthProvider();

      expect(auth.signInTemporaryLibrarian(email: 'janith@gmail.com', password: 'wrong'), isFalse);
      expect(auth.errorMessage, 'Invalid email or password.');
      expect(auth.isSignedIn, isFalse);

      expect(auth.signInTemporaryLibrarian(email: ' Janith@Gmail.com ', password: 'janith@123'), isTrue);
      expect(auth.isSignedIn, isTrue);
      expect(auth.role, UserRole.librarian);
      expect(auth.profile!.name, 'Janith');
      expect(auth.errorMessage, isNull);

      auth.signOut();
      expect(auth.isSignedIn, isFalse);
      expect(auth.profile, isNull);
    });
  });

  group('Login screen', () {
    testWidgets('opens on Login and renders the Figma elements', (tester) async {
      final router = await _pumpApp(tester);

      expect(router.currentPath, AppRoutes.login);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('LEARN • RESERVE • BELONG'), findsOneWidget);
      for (final label in ['Student', 'Librarian', 'Administrator', 'Email or User ID', 'Password', 'Remember me', 'Forgot password?', 'Continue with Google', 'Sign Up']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('validates empty fields and missing role', (tester) async {
      final router = await _pumpApp(tester);

      await _login(tester, email: '', password: '', chooseLibrarian: false);
      expect(find.text('Please enter your email or user ID'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please choose how you are logging in.'), findsOneWidget);
      expect(router.currentPath, AppRoutes.login);
    });

    testWidgets('rejects incorrect credentials without revealing them', (tester) async {
      final router = await _pumpApp(tester);

      await _login(tester, password: 'not-the-password');
      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.textContaining('janith@123'), findsNothing);
      expect(router.currentPath, AppRoutes.login);
    });

    testWidgets('password visibility toggle', (tester) async {
      await _pumpApp(tester);
      TextField passwordField() => tester.widget<TextField>(find.byType(TextField).at(1));

      expect(passwordField().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(passwordField().obscureText, isFalse);
    });

    testWidgets('correct credentials open the Librarian Dashboard', (tester) async {
      final router = await _pumpApp(tester);

      await _login(tester);
      expect(router.currentPath, LibrarianRoutes.dashboard);
      expect(find.textContaining(', Janith'), findsOneWidget);
    });
  });

  group('Librarian session', () {
    testWidgets('stays signed in while moving between Librarian pages', (tester) async {
      final router = await _pumpApp(tester, size: const Size(400, 900));
      await _login(tester);

      final nav = find.byType(NavigationBar);
      for (final (label, path) in [
        ('Reservations', LibrarianRoutes.reservations),
        ('Books', LibrarianRoutes.books),
        ('Seats', LibrarianRoutes.seats),
        ('Dashboard', LibrarianRoutes.dashboard),
      ]) {
        await tester.tap(find.descendant(of: nav, matching: find.text(label)));
        await tester.pumpAndSettle();
        expect(router.currentPath, path);
      }

      router.go(LibrarianRoutes.notifications);
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.notifications);

      // A signed-in librarian cannot open other roles' areas.
      router.go(AppRoutes.managerDashboard);
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.dashboard);
    });

    testWidgets('sign out returns to Login and protects Librarian routes', (tester) async {
      final router = await _pumpApp(tester, size: const Size(400, 900));
      await _login(tester);

      await _signOut(tester);
      expect(router.currentPath, AppRoutes.login);

      for (final path in [
        LibrarianRoutes.dashboard,
        LibrarianRoutes.books,
        LibrarianRoutes.reservationDetails('RSV-1001'),
        LibrarianRoutes.borrowings,
        LibrarianRoutes.borrowingDetails('LN-2001'),
        LibrarianRoutes.members,
        LibrarianRoutes.memberDetails('IT23004512'),
        LibrarianRoutes.reports,
        LibrarianRoutes.settings,
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.currentPath, AppRoutes.login, reason: path);
      }
    });

    testWidgets('Log Out on the Settings screen returns to Login', (tester) async {
      final router = await _pumpApp(tester, size: const Size(400, 900));
      await _login(tester);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.settings);
      expect(find.text('janith@gmail.com'), findsWidgets);

      await tapVisible(tester, find.text('Log Out'));
      expect(router.currentPath, AppRoutes.login);
    });

    testWidgets('new sections are reachable after login', (tester) async {
      final router = await _pumpApp(tester, size: const Size(400, 900));
      await _login(tester);

      for (final path in [
        LibrarianRoutes.borrowings,
        LibrarianRoutes.members,
        LibrarianRoutes.reports,
        LibrarianRoutes.settings,
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.currentPath, path);
      }
    });

    testWidgets('full flow: login, approve a reservation, sign out', (tester) async {
      final router = await _pumpApp(tester, size: const Size(400, 900));
      await _login(tester);

      await tapVisible(tester, find.text('Review'));
      expect(find.text('06 reservations found'), findsOneWidget);
      await tapVisible(tester, find.text('Nethmi Perera'));
      await tapVisible(tester, find.text('Approve Reservation'));
      expect(router.currentPath, LibrarianRoutes.reservationConfirmation('RSV-1001'));
      expect(find.text('Reservation Approved!'), findsOneWidget);

      await tapVisible(tester, find.text('Back to Home'));
      expect(router.currentPath, LibrarianRoutes.dashboard);
      expect(find.text('05'), findsOneWidget); // pending count updated

      await _signOut(tester);
      expect(router.currentPath, AppRoutes.login);
    });
  });

  for (final width in [360.0, 390.0, 720.0, 1280.0]) {
    testWidgets('Login fits at ${width.toInt()}px', (tester) async {
      await _pumpApp(tester, size: Size(width, 800));
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
