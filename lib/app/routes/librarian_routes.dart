import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/librarian/data/librarian_data_source.dart';
import '../../features/librarian/data/librarian_repository.dart';
import '../../features/librarian/providers/ebook_provider.dart';
import '../../features/librarian/models/borrowing_record.dart';
import '../../features/librarian/models/reservation_record.dart';
import '../../features/librarian/providers/reservation_filter.dart';
import '../../features/librarian/screens/add_book_screen.dart';
import '../../features/librarian/screens/add_seat_screen.dart';
import '../../features/librarian/screens/book_management_screen.dart';
import '../../features/librarian/screens/booking_confirmation_screen.dart';
import '../../features/librarian/screens/borrowing_details_screen.dart';
import '../../features/librarian/screens/borrowing_management_screen.dart';
import '../../features/librarian/screens/ebook_form_screen.dart';
import '../../features/librarian/screens/ebook_management_screen.dart';
import '../../features/librarian/screens/librarian_dashboard_screen.dart';
import '../../features/librarian/screens/librarian_notifications_screen.dart';
import '../../features/librarian/screens/librarian_settings_screen.dart';
import '../../features/librarian/screens/librarian_shell.dart';
import '../../features/librarian/screens/member_details_screen.dart';
import '../../features/librarian/screens/member_management_screen.dart';
import '../../features/librarian/screens/reports_screen.dart';
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
/// - borrowings: `status` (e.g. overdue) tab.
/// - reservation / borrowing details: `from`, the page Back returns to.
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
  static const String borrowings = '$dashboard/borrowings';
  static const String members = '$dashboard/members';
  static const String reports = '$dashboard/reports';
  static const String settings = '$dashboard/settings';

  static String reservationDetails(String id) => '$reservations/$id';
  static String reservationConfirmation(String id) =>
      '$reservations/$id/confirmation';
  static String editBook(String id) => '$books/$id/edit';
  static String editSeat(String id) => '$seats/$id/edit';

  /// E-books live under Books, so the Books tab stays selected.
  static const String ebooks = '$books/ebooks';
  static const String addEbook = '$ebooks/add';
  static String editEbook(String id) => '$ebooks/$id/edit';
  static String borrowingDetails(String id) => '$borrowings/$id';
  static String memberDetails(String id) => '$members/$id';

  /// Borrowing list opened on a status tab, e.g. from the Dashboard.
  static String borrowingsFiltered(BorrowingStatus status) =>
      Uri(path: borrowings, queryParameters: {'status': status.name}).toString();

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

  /// [createRepository] chooses the data source; by default Firebase (or
  /// demo data when started with LIBMATE_DEMO_DATA, see LibrarianDataSource).
  /// Tests pass an in-memory repository.
  static ShellRoute shellRoute(
    AuthProvider authProvider, {
    LibrarianRepository Function()? createRepository,
    EbookProvider Function()? createEbooks,
  }) {
    return ShellRoute(
      builder: (context, state, child) => LibrarianShell(
        authProvider: authProvider,
        createRepository:
            createRepository ?? () => LibrarianDataSource.create(authProvider),
        createEbooks: createEbooks ?? () => LibrarianDataSource.createEbooks(authProvider),
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
                  builder: (context, state) => ReservationDetailsScreen(
                    reservationId: state.pathParameters['id']!,
                    backTo: _backTo(state),
                  ),
                  routes: [
                    GoRoute(
                      path: 'confirmation',
                      builder: (context, state) => BookingConfirmationScreen(
                        reservationId: state.pathParameters['id']!,
                        decision: state.extra is ReservationStatus
                            ? state.extra! as ReservationStatus
                            : null,
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
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) =>
                      AddSeatScreen(seatId: state.pathParameters['id']),
                ),
              ],
            ),
            GoRoute(
              path: 'books',
              builder: (context, state) =>
                  BookManagementScreen(message: state.extra as String?),
              routes: [
                // Before ':id/edit', so "ebooks" is never read as a book id.
                GoRoute(
                  path: 'ebooks',
                  builder: (context, state) =>
                      EbookManagementScreen(message: state.extra as String?),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const EbookFormScreen(),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (context, state) =>
                          EbookFormScreen(ebookId: state.pathParameters['id']),
                    ),
                  ],
                ),
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
            GoRoute(
              path: 'borrowings',
              builder: (context, state) => BorrowingManagementScreen(
                key: ValueKey(state.uri.query),
                initialStatus: _byName(
                  BorrowingStatus.values,
                  state.uri.queryParameters['status'],
                ),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => BorrowingDetailsScreen(
                    loanId: state.pathParameters['id']!,
                    backTo: _backTo(state),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'members',
              builder: (context, state) => const MemberManagementScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      MemberDetailsScreen(memberId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: 'reports',
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const LibrarianSettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  /// The `from` query parameter, only if it is a Librarian page.
  static String? _backTo(GoRouterState state) {
    final from = state.uri.queryParameters['from'];
    return (from != null && from.startsWith(dashboard)) ? from : null;
  }

  /// Enum value from its name, or null if missing / unknown.
  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
