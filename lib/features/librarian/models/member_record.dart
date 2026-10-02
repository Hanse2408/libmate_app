enum MemberStatus {
  active('Active'),
  suspended('Suspended');

  const MemberStatus(this.label);
  final String label;
}

/// A library member (student) as the Librarian sees them. Local model used
/// with mock data until it is read from the shared `users` collection.
///
/// Borrowed-book and reservation counts are not stored here; the repository
/// calculates them from the loans and reservations so they never go stale.
class MemberRecord {
  const MemberRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.programme,
    required this.memberSince,
    this.status = MemberStatus.active,
  });

  /// Student ID, e.g. "IT23004512" (same as ReservationRecord.studentId).
  final String id;
  final String name;
  final String email;
  final String phone;
  final String programme;
  final DateTime memberSince;
  final MemberStatus status;

  bool get isActive => status == MemberStatus.active;

  MemberRecord copyWith({MemberStatus? status}) {
    return MemberRecord(
      id: id,
      name: name,
      email: email,
      phone: phone,
      programme: programme,
      memberSince: memberSince,
      status: status ?? this.status,
    );
  }
}
