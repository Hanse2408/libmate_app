import 'package:cloud_firestore/cloud_firestore.dart';

/// What a student notification is about.
enum StudentNotificationType {
  reservationRequested,
  reservationApproved,
  reservationRejected,
  reservationCancelled,
  bookReservationUpdated,
  bookCollected,
  bookReturned,
  loanRenewed,
  bookAvailable,
  seatBookingConfirmed,
  seatReservationUpdated;

  static StudentNotificationType fromName(Object? name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return reservationRequested;
  }
}

/// A notification for one student, stored in the shared `notifications`
/// collection with `audience: "student"` and the student's Firebase Auth uid
/// in `recipientUid`. Students can only read their own (see firestore.rules);
/// librarian alerts in the same collection use `audience: "librarian"`.
class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.recipientUid,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.reservationId,
    this.itemId,
    this.isRead = false,
  });

  final String id;
  final String recipientUid;
  final StudentNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;

  /// The reservation (and book / seat) the notification is about, if any.
  final String? reservationId;
  final String? itemId;
  final bool isRead;

  factory StudentNotification.fromMap(String id, Map<String, dynamic> map) {
    return StudentNotification(
      id: id,
      recipientUid: map['recipientUid'] as String? ?? '',
      type: StudentNotificationType.fromName(map['type']),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      // A just-written serverTimestamp is null until the server confirms it.
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reservationId: map['reservationId'] as String?,
      itemId: map['itemId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'audience': 'student',
      'recipientUid': recipientUid,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'reservationId': reservationId,
      'itemId': itemId,
      'isRead': isRead,
    };
  }

  /// A new, unread notification for [recipientUid], ready to write.
  static Map<String, dynamic> create({
    required String recipientUid,
    required StudentNotificationType type,
    required String title,
    required String message,
    String? reservationId,
    String? itemId,
  }) {
    return StudentNotification(
      id: '',
      recipientUid: recipientUid,
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      reservationId: reservationId,
      itemId: itemId,
    ).toMap();
  }
}
