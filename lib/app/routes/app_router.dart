import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/librarian/data/librarian_repository.dart';
import '../../features/manager/data/manager_firestore_repository.dart';
import '../../features/manager/data/manager_mock_data.dart';
import '../../features/manager/data/manager_repository.dart';
import '../../features/manager/providers/manager_scope.dart';
import '../../features/manager/screens/manager_dashboard_screen.dart';
import '../../features/onboarding/screens/get_started_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
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
import '../../features/student/common/data/student_library_repository.dart';
import '../../features/student/common/screens/student_home_screen.dart';
import '../../models/user.dart';
import '../../core/services/push_messaging_client.dart';
import '../startup/app_startup.dart';
import 'app_routes.dart';
import 'librarian_routes.dart';

/// Builds the app's GoRouter and redirects by Firebase auth state + Firestore role.
///
/// Librarian and Student screens read the same Firestore data. Tests can pass
/// [createLibrarianRepository] / [createStudentLibrary] to use other data.
///
/// With [startup] (the app passes one), every route waits on the splash
/// until start-up is done (see AppStartup); the normal redirects follow.
class AppRouter {
  AppRouter(
    AuthProvider authProvider, {
    AppStartup? startup,
    LibrarianRepository Function()? createLibrarianRepository,
    ManagerRepository Function()? createManagerRepository,
    StudentLibraryRepository Function()? createStudentLibrary,
  }) {
    _createManagerRepository =
        createManagerRepository ?? () => ManagerMockRepository.instance;
    // Signing out drops the cached Manager repository (and stops its
    // Firestore listeners); the next Manager sign-in builds a fresh one.
    // This keeps Manager-only listeners from ever starting before an
    // authenticated Manager session exists.
    authProvider.addListener(() {
      if (authProvider.user == null) _disposeManagerRepository();
    });
    router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: startup == null
          ? authProvider
          : Listenable.merge([authProvider, startup]),
      redirect: (context, state) {
        if (startup != null && !startup.isReady) {
          return state.matchedLocation == AppRoutes.splash
              ? null
              : AppRoutes.splash;
        }
        return _redirect(authProvider, state, withStartup: startup != null);
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(animate: false),
        ),
        GoRoute(
          path: AppRoutes.getStarted,
          builder: (context, state) => const GetStartedScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => LoginScreen(authProvider: authProvider),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => SignupScreen(authProvider: authProvider),
        ),
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (context, state) => StudentHomeScreen(
            createLibrary: createStudentLibrary ?? () => _firestoreStudentLibrary(authProvider),
            // Real push only for the live app (not tests, not web).
            createPushClient: createStudentLibrary == null && !kIsWeb
                ? FirebaseMessagingClient.new
                : null,
          ),
        ),
        LibrarianRoutes.shellRoute(
          authProvider,
          createRepository: createLibrarianRepository,
        ),
        GoRoute(
          path: AppRoutes.managerDashboard,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerDashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerProfile,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: ManagerProfileScreen(authProvider: authProvider),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerReservations,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerReservationsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerReservationDetails,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: ManagerReservationDetailsScreen(
              reservationId: state.extra is ManagerReservation
                  ? (state.extra! as ManagerReservation).id
                  : state.extra is String ? state.extra! as String : state.uri.queryParameters['id'],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerConflict,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerConflictScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerReassignSeat,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerReassignSeatScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerResolved,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerResolvedScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerReadingRoom,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerReadingRoomScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerReports,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerReportsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerPolicies,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerPoliciesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerUsers,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerUsersScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerUserDetails,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: ManagerUserDetailsScreen(
              user: state.extra is ManagerUser
                  ? state.extra! as ManagerUser
                  : managerUsers.first,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerUserAdd,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerUserFormScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerUserEdit,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: ManagerUserFormScreen(
              user: state.extra is ManagerUser
                  ? state.extra! as ManagerUser
                  : managerUsers.first,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerNotifications,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: const ManagerNotificationsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerReportPreview,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: ManagerReportPreviewScreen(
              selection: state.extra is ManagerReportSelection
                  ? state.extra! as ManagerReportSelection
                  : ManagerReportSelection(
                      reportType: 'Reservations',
                      startDate: DateTime(2026, 10, 1),
                      endDate: DateTime(2026, 10, 6),
                    ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.managerExportConfirmation,
          builder: (context, state) => ManagerScope(
            repository: _managerRepositoryFor(authProvider),
            authProvider: authProvider,
            child: ManagerExportConfirmationScreen(
              selection: state.extra is ManagerReportSelection
                  ? state.extra! as ManagerReportSelection
                  : ManagerReportSelection(
                      reportType: 'Reservations',
                      startDate: DateTime(2026, 10, 1),
                      endDate: DateTime(2026, 10, 6),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  late final ManagerRepository Function() _createManagerRepository;
  ManagerRepository? _managerRepositoryInstance;
  late final GoRouter router;

  /// Lazily creates (and caches) the Manager repository on first use, i.e.
  /// only when a Manager route actually builds - which the redirect only
  /// allows for an authenticated Manager. See [_disposeManagerRepository].
  ManagerRepository _managerRepositoryFor(AuthProvider authProvider) {
    return _managerRepositoryInstance ??= _createManagerRepository();
  }

  /// Stops the live Firestore listeners on sign-out. The shared mock/demo
  /// singleton is left alone - it is reused across the app's lifetime (and
  /// by tests), so it must never be disposed.
  void _disposeManagerRepository() {
    final repository = _managerRepositoryInstance;
    if (repository == null) return;
    _managerRepositoryInstance = null;
    if (repository is ManagerFirestoreRepository) {
      repository.dispose();
    }
  }

  /// Student data for the signed-in student (only built on the Student home,
  /// i.e. after sign-in with the student role).
  static StudentLibraryRepository _firestoreStudentLibrary(AuthProvider authProvider) {
    final user = authProvider.user!;
    final profile = authProvider.profile;
    final studentId = profile?.studentId?.trim() ?? '';
    return StudentLibraryRepository(
      lifecycleBinding: WidgetsBinding.instance,
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

  static ManagerRepository firestoreManagerRepository(AuthProvider authProvider) {
    final user = authProvider.user;
    return ManagerFirestoreRepository(
      firestore: FirebaseFirestore.instance,
      managerUid: user?.uid ?? authProvider.profile?.uid ?? '',
    );
  }

  static String? _redirect(
    AuthProvider authProvider,
    GoRouterState state, {
    bool withStartup = false,
  }) {
    final location = state.matchedLocation;
    final loggedIn = authProvider.user != null;

    if (!loggedIn) {
      // App start-up: Splash -> Get Started -> (button) Login.
      if (withStartup && location == AppRoutes.splash) {
        return AppRoutes.getStarted;
      }
      return location == AppRoutes.getStarted ||
              location == AppRoutes.login ||
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
