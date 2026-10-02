enum ReservationType {
  book('Book', 'Book'),
  seat('Seat', 'Reading Room');

  const ReservationType(this.label, this.cardLabel);
  final String label;

  /// Text after the item name on reservation cards, e.g. "Seat A01 · Reading Room".
  final String cardLabel;
}

enum ReservationStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  completed('Completed'),
  cancelled('Cancelled');

  const ReservationStatus(this.label);
  final String label;
}

/// A student's book or seat reservation that the Librarian reviews.
/// Local model used with mock data until the shared Reservation model is
/// integrated. [itemId]/[itemName] point to a book or a seat depending on [type].
class ReservationRecord {
  const ReservationRecord({
    required this.id,
    required this.type,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.itemId,
    required this.itemName,
    required this.requestedAt,
    required this.date,
    this.timeSlot,
    this.note,
    this.rejectionReason,
  });

  final String id;
  final ReservationType type;
  final ReservationStatus status;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String itemId;
  final String itemName;
  final DateTime requestedAt;

  /// Pickup date for books, booking date for seats.
  final DateTime date;

  /// Seat booking slot, e.g. "09:00 - 11:00", or book pickup time, e.g. "09:30".
  final String? timeSlot;
  final String? note;
  final String? rejectionReason;

  bool get isPending => status == ReservationStatus.pending;

  ReservationRecord copyWith({
    ReservationStatus? status,
    String? rejectionReason,
  }) {
    return ReservationRecord(
      id: id,
      type: type,
      status: status ?? this.status,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      itemId: itemId,
      itemName: itemName,
      requestedAt: requestedAt,
      date: date,
      timeSlot: timeSlot,
      note: note,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
