import 'package:flutter/material.dart';

import '../../../../models/action_result.dart';
import '../../../../models/notification.dart';
import '../../../../models/reservation.dart';
import '../../book_reservation/screens/book_details_screen.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';
import '../../book_reservation/screens/reservation_details_screen.dart';
import '../../book_reservation/screens/reserve_book_screen.dart';
import '../../book_reservation/widgets/reservation_notice.dart';
import '../../common/data/student_library_repository.dart';
import '../../seat_booking/screens/seat_reservation_details_screen.dart';

bool _opening = false;

/// Marks [notification] read and opens its destination. Shared by the
/// Notifications screen and the in-app banner so both behave the same.
Future<void> openStudentNotification(
  BuildContext context,
  StudentLibraryRepository library,
  StudentNotification notification, {
  bool markRead = true,
}) async {
  if (_opening) return;
  _opening = true;
  try {
    Widget destination = MyReservationsScreen(library: library);
    final reservation = library.myReservations
        .where((r) => r.id == notification.reservationId)
        .firstOrNull;
    final book = library.bookById(notification.itemId ?? '');
    if (notification.type == StudentNotificationType.bookAvailable) {
      if (book == null) {
        await showReservationNotice(
          context,
          title: 'Book unavailable',
          message: 'This book is no longer in the catalogue, or is still loading.',
        );
        return;
      }
      destination = book.isAvailable
          ? ReserveBookScreen(library: library, bookId: book.id)
          : BookDetailsScreen(library: library, bookId: book.id);
    } else if (reservation != null) {
      destination = reservation.type == ReservationType.seat
          ? SeatReservationDetailsScreen(library: library, reservation: reservation)
          : ReservationDetailsScreen(library: library, reservationId: reservation.id);
    } else if (book != null) {
      destination = BookDetailsScreen(library: library, bookId: book.id);
    }
    final missing =
        reservation == null && book == null && (notification.reservationId ?? '').isNotEmpty;
    final result = markRead
        ? await library.markNotificationRead(notification.id)
        : const ActionResult.success();
    if (!context.mounted) return;
    if (!result.success) {
      await showReservationNotice(
        context,
        title: 'Could not open notification',
        message: result.message ?? 'Please try again.',
      );
      return;
    }
    if (missing) {
      await showReservationNotice(
        context,
        title: 'Not available',
        message: 'This reservation is no longer available.',
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => destination));
  } finally {
    _opening = false;
  }
}

/// Icon and accent colour for each notification type.
(IconData, Color) studentNotificationStyle(BuildContext context, StudentNotificationType type) {
  final colors = Theme.of(context).colorScheme;
  return switch (type) {
    StudentNotificationType.bookAvailable => (Icons.notifications_active_rounded, colors.primary),
    StudentNotificationType.reservationApproved => (
      Icons.check_circle_rounded,
      colors.primary,
    ),
    StudentNotificationType.reservationRejected => (Icons.cancel_rounded, colors.error),
    StudentNotificationType.reservationCancelled => (
      Icons.event_busy_rounded,
      colors.error,
    ),
    StudentNotificationType.reservationRequested => (
      Icons.hourglass_top_rounded,
      colors.secondary,
    ),
    StudentNotificationType.bookCollected => (Icons.menu_book_rounded, colors.primary),
    StudentNotificationType.bookReturned => (
      Icons.assignment_return_rounded,
      colors.primary,
    ),
    StudentNotificationType.bookReservationUpdated => (Icons.edit_calendar_rounded, colors.primary),
    StudentNotificationType.loanRenewed => (Icons.update_rounded, colors.primary),
    StudentNotificationType.seatBookingConfirmed => (
      Icons.event_seat_rounded,
      colors.primary,
    ),
    StudentNotificationType.seatReservationUpdated => (Icons.edit_calendar_rounded, colors.primary),
  };
}
