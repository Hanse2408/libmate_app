import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/manager/screens/manager_dashboard_screen.dart';
import '../../features/student/common/screens/student_home_screen.dart';
import '../../models/user.dart';
import 'app_routes.dart';
import 'librarian_routes.dart';

/// Builds the app's GoRouter and redirects by Firebase auth state + Firestore role.
class AppRouter {
  AppRouter(AuthProvider authProvider)
    : router = GoRouter(
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
            builder: (context, state) => LoginScreen(authProvider: authProvider),
          ),
          GoRoute(
            path: AppRoutes.studentHome,
            builder: (context, state) => const StudentHomeScreen(),
          ),
          LibrarianRoutes.shellRoute(authProvider),
          GoRoute(
            path: AppRoutes.managerDashboard,
            builder: (context, state) => const ManagerDashboardScreen(),
          ),
        ],
      );

  final GoRouter router;

  static String? _redirect(AuthProvider authProvider, GoRouterState state) {
    final location = state.matchedLocation;
    // Firebase user, or the temporary librarian session (see AuthProvider).
    final loggedIn = authProvider.isSignedIn;

    if (!loggedIn) {
      return location == AppRoutes.login ? null : AppRoutes.login;
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
