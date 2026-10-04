import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberStatus {
  active('Active'),
  suspended('Suspended');

  const MemberStatus(this.label);
  final String label;
}

/// A library member (student) as the Librarian sees them, read from the
/// shared `users` collection (documents with role "student").
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
    this.uid = '',
  });

  /// Builds a member from a `users/{uid}` document. Suspension is stored in
  /// the `accountStatus` field; the role is never changed here.
  factory MemberRecord.fromUserMap(String uid, Map<String, dynamic> map) {
    final studentId = (map['studentId'] as String?)?.trim() ?? '';
    return MemberRecord(
      uid: uid,
      id: studentId.isEmpty ? uid : studentId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      programme: map['programme'] as String? ?? '',
      memberSince: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['accountStatus'] == MemberStatus.suspended.name
          ? MemberStatus.suspended
          : MemberStatus.active,
    );
  }

  /// Firebase Auth uid (the `users` document id); empty for demo data.
  final String uid;

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
      uid: uid,
    );
  }
}
