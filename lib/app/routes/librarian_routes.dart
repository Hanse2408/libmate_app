import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/librarian/models/reservation_record.dart';
import '../../features/librarian/providers/reservation_filter.dart';
import '../../features/librarian/screens/add_book_screen.dart';
import '../../features/librarian/screens/add_seat_screen.dart';
import '../../features/librarian/screens/book_management_screen.dart';
import '../../features/librarian/screens/booking_confirmation_screen.dart';
import '../../features/librarian/screens/librarian_dashboard_screen.dart';
import '../../features/librarian/screens/librarian_notifications_screen.dart';
import '../../features/librarian/screens/librarian_shell.dart';
import '../../features/librarian/screens/reservation_details_screen.dart';
import '../../features/librarian/screens/reservation_management_screen.dart';
import '../../features/librarian/screens/seat_management_screen.dart';
import 'app_routes.dart';

/// Librarian route paths and the route tree for the Librarian area.
///
/// All Librarian pages are nested under `/librarian` inside one ShellRoute,
/// so they share the same LibrarianShell (theme, shared state, bottom nav).
/// Nesting also gives natural back navigation, e.g. Add Book -> Books ->
/// Dashboard.
///
/// Optional query parameters:
/// - reservations: `status` (e.g. pending) and `date` (e.g. today) filters.
/// - reservation details: `from`, the page the back button returns to.
/// Seats / Books accept a success message through GoRouter's `extra`.
class LibrarianRoutes {
  const LibrarianRoutes._();

  static const String dashboard = AppRoutes.librarianDashboard; // /librarian
  static const String reservations = '$dashboard/reservations';
  static const String seats = '$dashboard/seats';
  static const String addSeat = '$seats/add';
  static const String books = '$dashboard/books';
  static const String addBook = '$books/add';
  static const String notifications = '$dashboard/notifications';

  static String reservationDetails(String id) => '$reservations/$id';
  static String reservationConfirmation(String id) =>
      '$reservations/$id/confirmation';
  static String editBook(String id) => '$books/$id/edit';

  /// Reservations list opened with filters, e.g. from the Dashboard.
  static String reservationsFiltered({
    ReservationStatus? status,
    ReservationDateFilter? date,
  }) {
    return Uri(
      path: reservations,
      queryParameters: {
        if (status != null) 'status': status.name,
        if (date != null) 'date': date.name,
      },
    ).toString();
  }

  static ShellRoute shellRoute(AuthProvider authProvider) {
    return ShellRoute(
      builder: (context, state, child) => LibrarianShell(
        authProvider: authProvider,
        currentPath: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: dashboard,
          builder: (context, state) => const LibrarianDashboardScreen(),
          routes: [
            GoRoute(
              path: 'reservations',
              builder: (context, state) {
                final query = state.uri.queryParameters;
                return ReservationManagementScreen(
                  // A new key resets the filters when the link's query changes.
                  key: ValueKey(state.uri.query),
                  initialStatus: _byName(ReservationStatus.values, query['status']),
                  initialDate:
                      _byName(ReservationDateFilter.values, query['date']) ??
                      ReservationDateFilter.all,
                );
              },
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final from = state.uri.queryParameters['from'];
                    return ReservationDetailsScreen(
                      reservationId: state.pathParameters['id']!,
                      // Only allow going back to Librarian pages.
                      backTo: (from != null && from.startsWith(dashboard))
                          ? from
                          : null,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'confirmation',
                      builder: (context, state) => BookingConfirmationScreen(
                        reservationId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'seats',
              builder: (context, state) =>
                  SeatManagementScreen(message: state.extra as String?),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddSeatScreen(),
                ),
              ],
            ),
            GoRoute(
              path: 'books',
              builder: (context, state) =>
                  BookManagementScreen(message: state.extra as String?),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddBookScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) =>
                      AddBookScreen(bookId: state.pathParameters['id']),
                ),
              ],
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const LibrarianNotificationsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  /// Enum value from its name, or null if missing / unknown.
  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
