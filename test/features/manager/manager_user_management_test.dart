import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'manager_user_provisioning_test.dart' as provisioning;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/manager/data/manager_mock_data.dart';
import 'package:libmate_app/features/manager/data/manager_repository.dart';
import 'package:libmate_app/features/manager/providers/manager_scope.dart';
import 'package:libmate_app/features/manager/screens/manager_user_details_screen.dart';
import 'package:libmate_app/features/manager/screens/manager_user_form_screen.dart';
import 'package:libmate_app/features/manager/screens/manager_users_screen.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

class LoginUser implements User {
  @override
  String get uid => 'manager-uid';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class LoginAuth implements AuthRepository {
  final events = StreamController<User?>.broadcast();
  User? current;
  int signOuts = 0;
  @override
  User? get currentUser => current;
  @override
  Stream<User?> get authStateChanges => events.stream;
  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    current = LoginUser();
    events.add(current);
    return current;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    current = null;
    events.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Profiles implements UserRepository {
  Profiles(this.status, {this.role = UserRole.manager});
  final AccountStatus status;
  final UserRole role;
  @override
  Future<AppUser?> getUserProfile(String uid) async => AppUser(
    uid: uid,
    name: 'Manager',
    email: 'manager@test.com',
    role: role,
    accountStatus: status,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Users extends ManagerRepository {
  Users(this.people);
  List<ManagerUser> people;
  @override
  List<ManagerUser> get users => people;
  @override
  void replaceUsers(List<ManagerUser> users) {
    people = users;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const other = ManagerUser(
  id: 'other',
  name: 'Other',
  email: 'other@test.com',
  role: 'Student',
);
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen,
  Users repo,
  AuthProvider auth,
) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ManagerScope(repository: repo, authProvider: auth, child: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Add User preserves the signed-in Manager session', () async {
    final auth = LoginAuth();
    final provider = AuthProvider(
      authRepository: auth,
      userRepository: Profiles(AccountStatus.active),
    );
    addTearDown(provider.dispose);
    addTearDown(auth.events.close);
    await provider.signIn(email: 'manager@test.com', password: 'secret123');
    final originalUser = provider.user;
    final repo = provisioning.repository(
      FakeFirebaseFirestore(),
      provisioning.SecondaryAuth(),
    );
    addTearDown(repo.dispose);
    expect(
      (await repo.addUser(
        name: 'New',
        email: 'new@test.com',
        password: 'secret123',
        role: UserRole.student,
      )).success,
      true,
    );
    expect(provider.user, same(originalUser));
    expect(provider.role, UserRole.manager);
    expect(provider.isSignedIn, true);
    expect(auth.signOuts, 0);
  });

  for (final status in AccountStatus.values) {
    testWidgets(
      '${status.name} login is checked before any Manager dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = LoginAuth();
        final provider = AuthProvider(
          authRepository: auth,
          userRepository: Profiles(status),
        );
        final router = AppRouter(
          provider,
          createLibrarianRepository: LibrarianMockRepository.new,
        ).router;
        addTearDown(router.dispose);
        addTearDown(provider.dispose);
        addTearDown(auth.events.close);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final allowed = await provider.signIn(
          email: 'manager@test.com',
          password: 'secret123',
        );
        await tester.pumpAndSettle();
        expect(allowed, status == AccountStatus.active);
        expect(provider.isSignedIn, status == AccountStatus.active);
        if (status != AccountStatus.active) {
          expect(auth.signOuts, greaterThanOrEqualTo(1));
          expect(provider.profile, isNull);
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            AppRoutes.login,
          );
          for (final route in [
            AppRoutes.managerDashboard,
            AppRoutes.studentHome,
            AppRoutes.librarianDashboard,
          ]) {
            router.go(route);
            await tester.pumpAndSettle();
            expect(
              router.routerDelegate.currentConfiguration.uri.path,
              AppRoutes.login,
            );
          }
        } else {
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            AppRoutes.managerDashboard,
          );
        }
      },
    );
  }
  testWidgets('librarian cannot open Manager user administration routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = LoginAuth();
    final provider = AuthProvider(
      authRepository: auth,
      userRepository: Profiles(AccountStatus.active, role: UserRole.librarian),
    );
    final router = AppRouter(
      provider,
      createLibrarianRepository: LibrarianMockRepository.new,
    ).router;
    addTearDown(provider.dispose);
    addTearDown(router.dispose);
    addTearDown(auth.events.close);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await provider.signIn(email: 'staff@test.com', password: 'secret123');
    await tester.pumpAndSettle();
    for (final route in [
      AppRoutes.managerUsers,
      AppRoutes.managerUserAdd,
      AppRoutes.managerUserEdit,
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.librarianDashboard,
      );
    }
  });

  testWidgets('details only expose Edit and confirmed Deactivate/Activate', (
    tester,
  ) async {
    final auth = LoginAuth();
    final provider = AuthProvider(
      authRepository: auth,
      userRepository: Profiles(AccountStatus.active),
    );
    addTearDown(provider.dispose);
    addTearDown(auth.events.close);
    final repo = Users([other]);
    addTearDown(repo.dispose);
    await pumpScreen(
      tester,
      const ManagerUserDetailsScreen(user: other),
      repo,
      provider,
    );
    expect(find.text('Edit User'), findsOneWidget);
    expect(find.text('Suspend User'), findsNothing);
    expect(find.text('Delete User'), findsNothing);
    expect(find.text('Remove Access'), findsNothing);
    expect(find.text('Activate User'), findsNothing);
    await tester.tap(find.text('Deactivate User'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate this user?'), findsOneWidget);
    expect(
      find.text(
        'This user will not be able to sign in until the account is activated again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate User'));
    await tester.pumpAndSettle();
    expect(repo.users.single.accountStatus, AccountStatus.inactive);
    expect(find.text('Deactivate User'), findsNothing);
    await tester.tap(find.text('Activate User'));
    await tester.pumpAndSettle();
    expect(find.text('Activate this user?'), findsOneWidget);
    expect(
      find.text('This user will be able to sign in to LibMate again.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Activate User'));
    await tester.pumpAndSettle();
    expect(repo.users.single.accountStatus, AccountStatus.active);
  });

  testWidgets(
    'legacy suspended displays Inactive and Edit has read-only identity without status dropdown',
    (tester) async {
      final auth = LoginAuth();
      final provider = AuthProvider(
        authRepository: auth,
        userRepository: Profiles(AccountStatus.active),
      );
      addTearDown(provider.dispose);
      addTearDown(auth.events.close);
      final legacy = other.copyWith(accountStatus: AccountStatus.suspended);
      final repo = Users([legacy]);
      addTearDown(repo.dispose);
      await pumpScreen(
        tester,
        ManagerUserDetailsScreen(user: legacy),
        repo,
        provider,
      );
      expect(find.text('Suspended'), findsNothing);
      expect(find.text('Inactive'), findsWidgets);
      expect(find.text('Activate User'), findsOneWidget);
      expect(find.text('Deactivate User'), findsNothing);
      await pumpScreen(
        tester,
        ManagerUserFormScreen(user: legacy),
        repo,
        provider,
      );
      expect(find.byType(DropdownButtonFormField<AccountStatus>), findsNothing);
      for (final label in ['Email', 'Firebase UID']) {
        final field = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == label,
          ),
        );
        expect(field.enabled, false);
      }
      await pumpScreen(tester, const ManagerUsersScreen(), repo, provider);
      await tester.tap(find.text('All Status'));
      await tester.pumpAndSettle();
      expect(find.text('Suspended'), findsNothing);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Inactive'), findsWidgets);
    },
  );
  testWidgets('Manager self status actions are hidden and role is locked', (
    tester,
  ) async {
    final auth = LoginAuth();
    final provider = AuthProvider(
      authRepository: auth,
      userRepository: Profiles(AccountStatus.active),
    );
    addTearDown(provider.dispose);
    addTearDown(auth.events.close);
    await provider.signIn(email: 'manager@test.com', password: 'secret123');
    final self = other.copyWith(id: 'manager-uid', role: 'Manager');
    final repo = Users([self]);
    addTearDown(repo.dispose);
    await pumpScreen(
      tester,
      ManagerUserDetailsScreen(user: self),
      repo,
      provider,
    );
    expect(find.text('Deactivate User'), findsNothing);
    expect(find.text('Activate User'), findsNothing);
    await pumpScreen(tester, ManagerUserFormScreen(user: self), repo, provider);
    expect(
      tester
          .widget<DropdownButtonFormField<UserRole>>(
            find.byType(DropdownButtonFormField<UserRole>),
          )
          .onChanged,
      isNull,
    );
  });
}
