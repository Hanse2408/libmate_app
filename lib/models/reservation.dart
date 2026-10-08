import 'reservation_display_reference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationType {
  book('Book', 'Book'),
  seat('Seat', 'Reading Room');

  const ReservationType(this.label, this.cardLabel);
  final String label;

  /// Text after the item name on reservation cards, e.g. "Seat A01 · Reading Room".
  final String cardLabel;
}

/// Book reservations move Requested (`pending`) -> Ready for Pickup
/// (`approved`) -> Collected (`collected`) -> Returned (`returned`); only a
/// librarian changes it after the request. Seat bookings are `approved` at
/// once. `completed` is the older value for a collected book (read as
/// [collected], see ReservationRecord.fromMap).
enum ReservationStatus {
  pending('Pending'),
  approved('Approved'),
  collected('Collected'),
  returned('Returned'),
  rejected('Rejected'),
  completed('Completed'),
  cancelled('Cancelled');

  const ReservationStatus(this.label);
  final String label;
}

/// A student's book or seat reservation, stored in Firestore at
/// `reservations/{id}`. [itemId]/[itemName] point to a book or a seat
/// depending on [type].
///
/// [studentUid] is the Firebase Auth uid (used by the security rules);
/// [studentId] is the university student ID shown on screens.
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
    this.studentUid = '',
    this.timeSlot,
    this.note,
    this.rejectionReason,
    this.pickupLocation,
    this.loanPeriodDays,
    this.collectedAt,
    this.returnedAt,
  });

  final String id;

  String get displayReference => ReservationDisplayReference.forId(id);
  final ReservationType type;
  final ReservationStatus status;
  final String studentUid;
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

  /// Book reservations only: where and for how long the student wants it.
  final String? pickupLocation;
  final int? loanPeriodDays;

  /// Book reservations: when the librarian marked it Collected / Returned.
  final DateTime? collectedAt;
  final DateTime? returnedAt;

  /// The student has the book (marked Collected by the librarian).
  bool get isCollected => status == ReservationStatus.collected;

  bool get isReturned => status == ReservationStatus.returned;

  bool get isPending => status == ReservationStatus.pending;

  /// Pending or approved: still holds a book copy request or a seat slot.
  bool get isActive =>
      status == ReservationStatus.pending || status == ReservationStatus.approved;

  /// Seat bookings: the booked time has already passed. A seat booking with
  /// no readable time ends with its day.
  bool get hasEnded {
    final end = endHour;
    final endsAt = end == null
        ? DateTime(date.year, date.month, date.day + 1)
        : DateTime(date.year, date.month, date.day, end);
    return !endsAt.isAfter(DateTime.now());
  }

  /// A confirmed seat booking that has not ended can still be modified.
  bool get canModifySeat =>
      type == ReservationType.seat &&
      status == ReservationStatus.approved &&
      !hasEnded;

  /// Seat bookings: first hour of the slot, e.g. 13 for "13:00 - 15:00".
  int? get startHour => _hourAt(0);

  /// Seat bookings: hour the slot ends, e.g. 15 for "13:00 - 15:00".
  int? get endHour => _hourAt(1);

  int? _hourAt(int part) {
    final parts = timeSlot?.split('-');
    if (parts == null || parts.length < 2) return null;
    return int.tryParse(parts[part].trim().split(':').first);
  }

  /// True if this seat booking shares at least one hour with [other]'s
  /// booking of the same seat on the same day.
  bool overlaps(ReservationRecord other) {
    if (type != ReservationType.seat || other.type != ReservationType.seat) return false;
    if (itemId != other.itemId || !_sameDay(date, other.date)) return false;
    final (s1, e1, s2, e2) = (startHour, endHour, other.startHour, other.endHour);
    if (s1 == null || e1 == null || s2 == null || e2 == null) return false;
    return s1 < e2 && s2 < e1;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "13:00 - 15:00" from whole hours.
  static String slotLabel(int startHour, int endHour) {
    String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
    return '${hh(startHour)} - ${hh(endHour)}';
  }

  factory ReservationRecord.fromMap(String id, Map<String, dynamic> map) {
    final type = _byName(ReservationType.values, map['type'], ReservationType.book);
    var status = _byName(ReservationStatus.values, map['status'], ReservationStatus.pending);
    // Book reservations collected before the Collected status existed were
    // saved as `completed`.
    if (type == ReservationType.book && status == ReservationStatus.completed) {
      status = ReservationStatus.collected;
    }
    return ReservationRecord(
      id: id,
      type: type,
      status: status,
      studentUid: map['studentUid'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentEmail: map['studentEmail'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      // A just-written serverTimestamp is null until the server confirms it.
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: map['timeSlot'] as String?,
      note: (map['notes'] ?? map['note']) as String?,
      rejectionReason: map['rejectionReason'] as String?,
      pickupLocation: map['pickupLocation'] as String?,
      loanPeriodDays: (map['loanPeriodDays'] as num?)?.toInt(),
      collectedAt: (map['collectedAt'] as Timestamp?)?.toDate(),
      returnedAt: (map['returnedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'status': status.name,
      'studentUid': studentUid,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'itemId': itemId,
      'itemName': itemName,
      'requestedAt': FieldValue.serverTimestamp(),
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'timeSlot': timeSlot,
      'note': note,
      'rejectionReason': rejectionReason,
      'pickupLocation': pickupLocation,
      'loanPeriodDays': loanPeriodDays,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ReservationRecord copyWith({
    ReservationStatus? status,
    String? rejectionReason,
    DateTime? collectedAt,
    DateTime? returnedAt,
  }) {
    return ReservationRecord(
      id: id,
      type: type,
      status: status ?? this.status,
      studentUid: studentUid,
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
      pickupLocation: pickupLocation,
      loanPeriodDays: loanPeriodDays,
      collectedAt: collectedAt ?? this.collectedAt,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }
}

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
