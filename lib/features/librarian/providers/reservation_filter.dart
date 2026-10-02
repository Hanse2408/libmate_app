import '../models/reservation_record.dart';

enum ReservationDateFilter {
  all('All'),
  today('Today'),
  upcoming('Upcoming'),
  past('Past');

  const ReservationDateFilter(this.label);
  final String label;
}

/// Search text + filters chosen on the Reservation Management screen.
/// A null [type] or [status] means "All".
class ReservationFilter {
  const ReservationFilter({
    this.query = '',
    this.type,
    this.status,
    this.date = ReservationDateFilter.all,
  });

  final String query;
  final ReservationType? type;
  final ReservationStatus? status;
  final ReservationDateFilter date;

  /// Matching reservations: pending first (they need action), then by date
  /// and time.
  List<ReservationRecord> apply(
    List<ReservationRecord> reservations, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);

    return reservations.where((r) => _matches(r, today)).toList()..sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return (a.timeSlot ?? '').compareTo(b.timeSlot ?? '');
    });
  }

  bool _matches(ReservationRecord r, DateTime today) {
    if (type != null && r.type != type) return false;
    if (status != null && r.status != status) return false;

    final day = DateTime(r.date.year, r.date.month, r.date.day);
    final dateOk = switch (date) {
      ReservationDateFilter.all => true,
      ReservationDateFilter.today => day == today,
      ReservationDateFilter.upcoming => day.isAfter(today),
      ReservationDateFilter.past => day.isBefore(today),
    };
    if (!dateOk) return false;

    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return [
      r.id,
      r.studentName,
      r.studentId,
      r.itemName,
    ].any((field) => field.toLowerCase().contains(text));
  }
}
