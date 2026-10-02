import '../data/librarian_mock_repository.dart';
import '../models/borrowing_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';

/// The numbers shown on the Librarian Dashboard, calculated from the
/// repository. It is rebuilt every time the repository changes, so the
/// dashboard always matches the other Librarian screens.
class LibrarianDashboardSummary {
  const LibrarianDashboardSummary({
    required this.pendingCount,
    required this.conflictCount,
    required this.todayCount,
    required this.yesterdayCount,
    required this.todaysReservations,
    required this.availableSeats,
    required this.reservedSeats,
    required this.occupiedSeats,
    required this.maintenanceSeats,
    required this.outOfStockBooks,
    required this.unreadNotifications,
    required this.overdueLoans,
  });

  factory LibrarianDashboardSummary.fromRepository(
    LibrarianMockRepository repository, {
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Rejected and cancelled bookings no longer take up a book or seat.
    final active = repository.reservations.where(
      (r) =>
          r.status != ReservationStatus.rejected &&
          r.status != ReservationStatus.cancelled,
    );
    final todays = active.where((r) => _dateOnly(r.date) == today).toList()
      ..sort((a, b) => (a.timeSlot ?? '').compareTo(b.timeSlot ?? ''));
    final pending = repository.reservations.where((r) => r.isPending);

    int seatsWith(SeatStatus status) =>
        repository.seats.where((seat) => seat.status == status).length;

    return LibrarianDashboardSummary(
      pendingCount: pending.length,
      conflictCount: pending
          .where((r) => repository.approvalBlocker(r) != null)
          .length,
      todayCount: todays.length,
      yesterdayCount: active
          .where((r) => _dateOnly(r.date) == yesterday)
          .length,
      todaysReservations: todays,
      availableSeats: seatsWith(SeatStatus.available),
      reservedSeats: seatsWith(SeatStatus.reserved),
      occupiedSeats: seatsWith(SeatStatus.occupied),
      maintenanceSeats: seatsWith(SeatStatus.maintenance),
      outOfStockBooks: repository.books.where((b) => !b.isAvailable).length,
      unreadNotifications: repository.unreadNotificationCount,
      overdueLoans: repository.borrowings
          .where((loan) => loan.status == BorrowingStatus.overdue)
          .length,
    );
  }

  final int pendingCount;

  /// Pending requests that cannot be approved as-is: the book has no copies
  /// left, or the seat is not currently available.
  final int conflictCount;

  final int todayCount;
  final int yesterdayCount;
  final List<ReservationRecord> todaysReservations;

  final int availableSeats;
  final int reservedSeats;
  final int occupiedSeats;
  final int maintenanceSeats;

  final int outOfStockBooks;
  final int unreadNotifications;

  /// Borrowed books past their due date.
  final int overdueLoans;

  int get todayChange => todayCount - yesterdayCount;

  /// Seats that students can use (maintenance seats are left out).
  int get usableSeats => availableSeats + reservedSeats + occupiedSeats;

  /// Share of usable seats that are reserved or occupied, from 0.0 to 1.0.
  double get occupancyRate {
    if (usableSeats == 0) return 0;
    return (reservedSeats + occupiedSeats) / usableSeats;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
