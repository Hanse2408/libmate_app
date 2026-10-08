import 'package:flutter/material.dart';

import '../models/reservation_record.dart';
import '../theme/librarian_theme.dart';
import 'librarian_message_banner.dart';

/// Coloured banner at the top of the reservation details screens explaining
/// the current state, e.g. "Reservation Pending — awaiting your approval".
/// [blocker] is the repository's reason why a pending request cannot be
/// approved yet (no copies / seat unavailable), or null.
class ReservationStatusBanner extends StatelessWidget {
  const ReservationStatusBanner({
    super.key,
    required this.reservation,
    this.blocker,
  });

  final ReservationRecord reservation;
  final String? blocker;

  @override
  Widget build(BuildContext context) {
    final (title, message, color, icon) = switch (reservation.status) {
      ReservationStatus.pending when blocker != null => (
        'Cannot Be Approved Yet',
        blocker!,
        LibrarianColors.unavailable,
        Icons.warning_amber_rounded,
      ),
      ReservationStatus.pending => (
        'Reservation Pending',
        'This reservation is awaiting your approval. Please review the '
            'reservation details and approve or reject the request.',
        LibrarianColors.unavailable,
        Icons.warning_amber_rounded,
      ),
      ReservationStatus.approved => (
        reservation.type == ReservationType.book
            ? 'Ready for Pickup'
            : 'Reservation Approved',
        reservation.type == ReservationType.book
            ? 'The book is held for the student to collect.'
            : 'The seat is reserved for the student.',
        LibrarianColors.available,
        Icons.check_circle_outline,
      ),
      ReservationStatus.collected => (
        'Book Collected',
        'The student has collected the book. Mark it as returned when the '
            'book comes back to the library.',
        LibrarianColors.primary,
        Icons.auto_stories_outlined,
      ),
      ReservationStatus.returned => (
        'Book Returned',
        'The student has returned the book. This reservation is complete.',
        LibrarianColors.secondaryText,
        Icons.assignment_turned_in_outlined,
      ),
      ReservationStatus.rejected => (
        'Reservation Rejected',
        'Reason: ${reservation.rejectionReason ?? 'Not specified.'}',
        LibrarianColors.unavailable,
        Icons.block,
      ),
      ReservationStatus.completed => (
        'Reservation Completed',
        'This reservation has been completed.',
        LibrarianColors.primary,
        Icons.task_alt,
      ),
      ReservationStatus.cancelled => (
        'Reservation Cancelled',
        'The student cancelled this reservation.',
        LibrarianColors.secondaryText,
        Icons.event_busy,
      ),
    };

    return LibrarianMessageBanner(
      title: title,
      message: message,
      color: color,
      icon: icon,
    );
  }
}
