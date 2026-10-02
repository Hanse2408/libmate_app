import '../data/librarian_mock_repository.dart';
import '../models/borrowing_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import '../utils/librarian_formatters.dart';

enum ReportPeriod {
  weekly('Weekly', 7),
  monthly('Monthly', 28);

  const ReportPeriod(this.label, this.days);
  final String label;

  /// Length of the period ending today (a month is shown as 4 weeks).
  final int days;
}

/// A label and a count, used for every bar list on the Reports screen.
typedef ReportEntry = ({String label, int count});

/// All numbers on the Reports & Analytics screen, calculated from the
/// repository for the chosen [period] (ending today). Current-state values
/// (copies, open loans, seat occupancy) are not limited to the period.
class LibrarianReport {
  const LibrarianReport._({
    required this.period,
    required this.start,
    required this.end,
    required this.totalTitles,
    required this.totalCopies,
    required this.loansOut,
    required this.activeLoans,
    required this.dueTodayLoans,
    required this.overdueLoans,
    required this.returnedInPeriod,
    required this.reservationsInPeriod,
    required this.reservationStatus,
    required this.occupancyRate,
    required this.seatStatus,
    required this.mostBorrowed,
    required this.mostReserved,
    required this.activity,
    required this.bookingPeriods,
  });

  factory LibrarianReport.fromRepository(
    LibrarianMockRepository repository,
    ReportPeriod period, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final end = DateTime(clock.year, clock.month, clock.day);
    final start = end.subtract(Duration(days: period.days - 1));
    bool inPeriod(DateTime value) {
      final day = DateTime(value.year, value.month, value.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }

    final books = repository.books;
    final loans = repository.borrowings;
    final reservations = repository.reservations
        .where((r) => inPeriod(r.requestedAt))
        .toList();
    final seats = repository.seats;

    int loansWith(BorrowingStatus status) =>
        loans.where((l) => l.status == status).length;
    int seatsWith(SeatStatus status) =>
        seats.where((s) => s.status == status).length;

    final usableSeats = seats.where((s) => s.status != SeatStatus.maintenance).length;
    final busySeats = seatsWith(SeatStatus.reserved) + seatsWith(SeatStatus.occupied);

    return LibrarianReport._(
      period: period,
      start: start,
      end: end,
      totalTitles: books.length,
      totalCopies: books.fold(0, (sum, b) => sum + b.totalCopies),
      loansOut: loans.where((l) => !l.isReturned).length,
      activeLoans: loansWith(BorrowingStatus.active),
      dueTodayLoans: loansWith(BorrowingStatus.dueToday),
      overdueLoans: loansWith(BorrowingStatus.overdue),
      returnedInPeriod: loans
          .where((l) => l.isReturned && inPeriod(l.returnedAt!))
          .length,
      reservationsInPeriod: reservations.length,
      reservationStatus: [
        for (final status in ReservationStatus.values)
          (
            label: status.label,
            count: reservations.where((r) => r.status == status).length,
          ),
      ],
      occupancyRate: usableSeats == 0 ? 0 : busySeats / usableSeats,
      seatStatus: [
        for (final status in SeatStatus.values)
          (label: status.label, count: seatsWith(status)),
      ],
      mostBorrowed: _top(
        loans.where((l) => inPeriod(l.issuedAt)).map((l) => l.bookTitle),
      ),
      mostReserved: _top(
        reservations
            .where((r) => r.type == ReservationType.book)
            .map((r) => r.itemName),
      ),
      activity: _activity(reservations, period, start),
      bookingPeriods: _bookingPeriods(
        reservations.where((r) => r.type == ReservationType.seat),
      ),
    );
  }

  final ReportPeriod period;
  final DateTime start;
  final DateTime end;

  final int totalTitles;
  final int totalCopies;

  /// Loans not yet returned (active + due today + overdue).
  final int loansOut;
  final int activeLoans;
  final int dueTodayLoans;
  final int overdueLoans;
  final int returnedInPeriod;

  final int reservationsInPeriod;
  final List<ReportEntry> reservationStatus;

  /// Reserved or occupied seats out of seats in use (0.0 - 1.0).
  final double occupancyRate;
  final List<ReportEntry> seatStatus;

  final List<ReportEntry> mostBorrowed;
  final List<ReportEntry> mostReserved;

  /// Reservations per day (weekly) or per week (monthly).
  final List<ReportEntry> activity;

  /// Seat bookings by time of day.
  final List<ReportEntry> bookingPeriods;

  String get rangeLabel =>
      '${LibrarianFormatters.date(start)} – ${LibrarianFormatters.date(end)}';

  int countFor(List<ReportEntry> entries, String label) =>
      entries.firstWhere((e) => e.label == label, orElse: () => (label: label, count: 0)).count;

  /// The 5 most frequent titles, highest first.
  static List<ReportEntry> _top(Iterable<String> titles) {
    final counts = <String, int>{};
    for (final title in titles) {
      counts[title] = (counts[title] ?? 0) + 1;
    }
    final entries = [
      for (final e in counts.entries) (label: e.key, count: e.value),
    ]..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.label.compareTo(b.label);
      });
    return entries.take(5).toList();
  }

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static List<ReportEntry> _activity(
    List<ReservationRecord> reservations,
    ReportPeriod period,
    DateTime start,
  ) {
    // One bar per day for a week, one bar per week for a month.
    final bucketDays = period == ReportPeriod.weekly ? 1 : 7;
    final entries = <ReportEntry>[];
    for (var i = 0; i < period.days ~/ bucketDays; i++) {
      final from = start.add(Duration(days: i * bucketDays));
      final to = from.add(Duration(days: bucketDays));
      final count = reservations.where((r) {
        final day = DateTime(r.requestedAt.year, r.requestedAt.month, r.requestedAt.day);
        return !day.isBefore(from) && day.isBefore(to);
      }).length;
      final label = period == ReportPeriod.weekly
          ? _weekdays[from.weekday - 1]
          : LibrarianFormatters.date(from).split(' ').take(2).join(' '); // "26 Sep"
      entries.add((label: label, count: count));
    }
    return entries;
  }

  /// Morning (before 12:00), Afternoon (12:00-16:00), Evening (16:00+).
  static List<ReportEntry> _bookingPeriods(Iterable<ReservationRecord> seatBookings) {
    var morning = 0, afternoon = 0, evening = 0;
    for (final booking in seatBookings) {
      final hour = int.tryParse(booking.timeSlot?.split(':').first.trim() ?? '');
      if (hour == null) continue;
      if (hour < 12) {
        morning++;
      } else if (hour < 16) {
        afternoon++;
      } else {
        evening++;
      }
    }
    return [
      (label: 'Morning', count: morning),
      (label: 'Afternoon', count: afternoon),
      (label: 'Evening', count: evening),
    ];
  }
}
