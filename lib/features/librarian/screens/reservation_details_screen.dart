import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import 'book_reservation_details_screen.dart';
import 'seat_reservation_details_screen.dart';

/// Route target for /librarian/reservations/:id. Looks the reservation up
/// and shows the Book or Seat details screen; rebuilds after approve/reject.
class ReservationDetailsScreen extends StatelessWidget {
  const ReservationDetailsScreen({
    super.key,
    required this.reservationId,
    this.backTo,
  });

  final String reservationId;

  /// Where the back button goes, e.g. Notifications. Null = previous page.
  final String? backTo;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final reservation = repository.reservationById(reservationId);
        final onBack = backTo == null ? null : () => context.go(backTo!);

        if (reservation == null) {
          return LibrarianPage(
            children: [
              LibrarianPageHeader(title: 'Reservation', onBack: onBack),
              const LibrarianEmptyState(
                icon: Icons.search_off,
                title: 'Reservation not found',
                message: 'It may have been removed.',
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.go(LibrarianRoutes.reservations),
                  child: const Text('Back to Reservations'),
                ),
              ),
            ],
          );
        }

        final blocker = repository.approvalBlocker(reservation);
        if (reservation.type == ReservationType.book) {
          return BookReservationDetailsScreen(
            reservation: reservation,
            book: repository.bookById(reservation.itemId),
            blocker: reservation.isPending ? blocker : null,
            onBack: onBack,
          );
        }
        return SeatReservationDetailsScreen(
          reservation: reservation,
          seat: repository.seatById(reservation.itemId),
          blocker: reservation.isPending ? blocker : null,
          onBack: onBack,
        );
      },
    );
  }
}
