import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/librarian/data/librarian_repository.dart';
import '../../features/manager/screens/manager_dashboard_screen.dart';
import '../../features/manager/screens/manager_reservation_screens.dart';
import '../../features/manager/screens/manager_reading_room_screen.dart';
import '../../features/manager/screens/manager_reports_screen.dart';
import '../../features/manager/screens/manager_policies_screen.dart';
import '../../features/manager/screens/manager_users_screen.dart';
import '../../features/manager/screens/manager_notifications_screen.dart';
import '../../features/manager/screens/manager_user_details_screen.dart';
import '../../features/manager/screens/manager_user_form_screen.dart';
import '../../features/manager/screens/manager_report_preview_screen.dart';
import '../../features/manager/screens/manager_export_confirmation_screen.dart';
import '../../features/manager/screens/manager_profile_screen.dart';
import '../../features/manager/data/manager_mock_data.dart';
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
            path: AppRoutes.roleSelection,
            builder: (context, state) =>
                LoginScreen(key: const ValueKey('role-selection'), authProvider: authProvider),
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
          GoRoute(
            path: AppRoutes.managerProfile,
            builder: (context, state) =>
                ManagerProfileScreen(authProvider: authProvider),
          ),
          GoRoute(
            path: AppRoutes.managerReservations,
            builder: (context, state) => const ManagerReservationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerReservationDetails,
            builder: (context, state) => ManagerReservationDetailsScreen(
              reservation: state.extra is ManagerReservation
                  ? state.extra! as ManagerReservation
                  : managerReservations[1],
            ),
          ),
          GoRoute(
            path: AppRoutes.managerConflict,
            builder: (context, state) => const ManagerConflictScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerReassignSeat,
            builder: (context, state) => const ManagerReassignSeatScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerResolved,
            builder: (context, state) => ManagerResolvedScreen(
              newSeat: state.extra is String ? state.extra! as String : 'A08',
            ),
          ),
          GoRoute(
            path: AppRoutes.managerReadingRoom,
            builder: (context, state) => const ManagerReadingRoomScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerReports,
            builder: (context, state) => const ManagerReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerPolicies,
            builder: (context, state) => const ManagerPoliciesScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerUsers,
            builder: (context, state) => const ManagerUsersScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerUserDetails,
            builder: (context, state) => ManagerUserDetailsScreen(
              user: state.extra is ManagerUser
                  ? state.extra! as ManagerUser
                  : managerUsers.first,
            ),
          ),
          GoRoute(
            path: AppRoutes.managerUserAdd,
            builder: (context, state) => const ManagerUserFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerUserEdit,
            builder: (context, state) => ManagerUserFormScreen(
              user: state.extra is ManagerUser
                  ? state.extra! as ManagerUser
                  : managerUsers.first,
            ),
          ),
          GoRoute(
            path: AppRoutes.managerNotifications,
            builder: (context, state) => const ManagerNotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.managerReportPreview,
            builder: (context, state) => ManagerReportPreviewScreen(
              selection: state.extra is ManagerReportSelection
                  ? state.extra! as ManagerReportSelection
                  : ManagerReportSelection(
                      reportType: 'Reservations',
                      startDate: DateTime(2026, 10, 1),
                      endDate: DateTime(2026, 10, 6),
                    ),
            ),
          ),
          GoRoute(
            path: AppRoutes.managerExportConfirmation,
            builder: (context, state) => ManagerExportConfirmationScreen(
              selection: state.extra is ManagerReportSelection
                  ? state.extra! as ManagerReportSelection
                  : ManagerReportSelection(
                      reportType: 'Reservations',
                      startDate: DateTime(2026, 10, 1),
                      endDate: DateTime(2026, 10, 6),
                    ),
            ),
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
      return location == AppRoutes.login ||
              location == AppRoutes.roleSelection ||
              location == AppRoutes.signup
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
