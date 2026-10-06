import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/librarian/data/librarian_repository.dart';
import '../../features/manager/screens/manager_dashboard_screen.dart';
import '../../features/student/common/data/student_library_repository.dart';
import '../../features/student/common/screens/student_home_screen.dart';
import '../../models/user.dart';
import 'app_routes.dart';
import 'librarian_routes.dart';

/// Builds the app's GoRouter and redirects by Firebase auth state + Firestore role.
///
/// Librarian and Student screens read the same Firestore data. Tests can pass
/// [createLibrarianRepository] / [createStudentLibrary] to use other data.
class AppRouter {
  AppRouter(
    AuthProvider authProvider, {
    LibrarianRepository Function()? createLibrarianRepository,
    StudentLibraryRepository Function()? createStudentLibrary,
  }) : router = GoRouter(
        initialLocation: AppRoutes.splash,
        refreshListenable: authProvider,
        redirect: (context, state) => _redirect(authProvider, state),
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const _AuthResolvingScreen(),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) =>
                LoginScreen(authProvider: authProvider),
          ),
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) =>
                SignupScreen(authProvider: authProvider),
          ),
          GoRoute(
            path: AppRoutes.studentHome,
            builder: (context, state) => StudentHomeScreen(
              createLibrary:
                  createStudentLibrary ?? () => _firestoreStudentLibrary(authProvider),
            ),
          ),
          // All Librarian pages: dashboard, reservations, books, seats,
          // notifications, borrowing, members, reports and settings.
          LibrarianRoutes.shellRoute(
            authProvider,
            createRepository: createLibrarianRepository,
          ),
          GoRoute(
            path: AppRoutes.managerDashboard,
            builder: (context, state) => const ManagerDashboardScreen(),
          ),
        ],
      );

  final GoRouter router;

  /// Student data for the signed-in student (only built on the Student home,
  /// i.e. after sign-in with the student role).
  static StudentLibraryRepository _firestoreStudentLibrary(AuthProvider authProvider) {
    final user = authProvider.user!;
    final profile = authProvider.profile;
    final studentId = profile?.studentId?.trim() ?? '';
    return StudentLibraryRepository(
      firestore: FirebaseFirestore.instance,
      // Logout reuses the existing AuthProvider; the redirect then shows Login.
      onSignOut: authProvider.signOut,
      student: StudentIdentity(
        uid: user.uid,
        studentId: studentId.isEmpty ? user.uid : studentId,
        name: profile?.name ?? '',
        email: profile?.email ?? user.email ?? '',
      ),
    );
  }

  static String? _redirect(AuthProvider authProvider, GoRouterState state) {
    final location = state.matchedLocation;
    final loggedIn = authProvider.user != null;

    if (!loggedIn) {
      return location == AppRoutes.login || location == AppRoutes.signup
          ? null
          : AppRoutes.login;
    }

    // Signed in but the Firestore profile/role hasn't resolved yet.
    if (authProvider.isProfileLoading) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final profile = authProvider.profile;
    if (profile == null) {
      // Missing/invalid profile: no role to route by, send back to login.
      return location == AppRoutes.login ? null : AppRoutes.login;
    }

    final destination = switch (profile.role) {
      UserRole.student => AppRoutes.studentHome,
      UserRole.librarian => AppRoutes.librarianDashboard,
      UserRole.manager => AppRoutes.managerDashboard,
    };

    // Allow the role's home and its sub-pages (e.g. /librarian/books).
    final isInOwnArea =
        location == destination || location.startsWith('$destination/');
    return isInOwnArea ? null : destination;
  }
}

class _AuthResolvingScreen extends StatelessWidget {
  const _AuthResolvingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
