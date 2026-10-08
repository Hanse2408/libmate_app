import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/manager/data/manager_mock_data.dart';
import 'package:libmate_app/features/manager/data/manager_repository.dart';
import 'package:libmate_app/features/manager/providers/manager_scope.dart';
import 'package:libmate_app/features/manager/screens/manager_users_screen.dart';
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

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
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

class _LoadingManagerRepository extends ManagerRepository {
  @override
  List<ManagerUser> get users => const [];

  @override
  List<ManagerReservation> get reservations => const [];

  @override
  List<ManagerNotice> get notices => const [];

  @override
  List<int> get policyValues => const [3, 5, 7, 2, 7];

  @override
  bool get isLoading => true;

  @override
  void replaceUsers(List<ManagerUser> users) {}

  @override
  void replaceReservations(List<ManagerReservation> reservations) {}

  @override
  void replacePolicyValues(List<int> values) {}
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
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
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

  testWidgets('manager routes reuse a single repository instance', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var factoryCalls = 0;
    final authRepository = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: authRepository,
      userRepository: _FakeUserRepository(),
    );
    final router = AppRouter(
      authProvider,
      createManagerRepository: () {
        factoryCalls += 1;
        return ManagerMockRepository.instance;
      },
    ).router;
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    authRepository.emitSignedIn();
    await tester.pumpAndSettle();

    router.go(AppRoutes.managerUsers);
    await tester.pumpAndSettle();
    router.go(AppRoutes.managerReports);
    await tester.pumpAndSettle();

    expect(factoryCalls, 1);
  });

  testWidgets('manager user screen shows a loading state while the live data is still loading', (
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

    final loadingRepository = _LoadingManagerRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerScope(
          repository: loadingRepository,
          authProvider: authProvider,
          child: const ManagerUsersScreen(),
        ),
      ),
    );

    expect(find.text('Loading users...'), findsOneWidget);
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
    await tester.enterText(find.byType(TextFormField).at(2), 'Temp1234');
    await tester.enterText(find.byType(TextFormField).at(3), 'TEST-MGR-001');
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
    await tester.tap(find.text('Deactivate User').last);
    await tester.pumpAndSettle();
    expect(find.text('Updated Manager'), findsOneWidget);
    expect(find.text('Inactive'), findsWidgets);
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
      find.text('This report is ready to be exported as CSV.'),
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
    expect(find.text('Policy & Limits'), findsOneWidget);
    expect(find.textContaining('Demo mode'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.managerDashboard);
  });

  testWidgets('policy apply updates the visible value immediately', (
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
    await tester.tap(find.text('Book Reservation Limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsWidgets);
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

  testWidgets('manager profile logs out to the unified login screen', (tester) async {
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
      find.text('You will be returned to the login screen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Log Out').last);
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.login);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Login as'), findsNothing);
  });
}
