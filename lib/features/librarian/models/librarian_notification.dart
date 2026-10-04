import 'package:cloud_firestore/cloud_firestore.dart';

/// Groups used by the filter chips on the Notifications screen.
enum NotificationCategory { reservations, books, seats }

enum LibrarianNotificationType {
  newRequest(NotificationCategory.reservations),
  awaitingApproval(NotificationCategory.reservations),
  approved(NotificationCategory.reservations),
  rejected(NotificationCategory.reservations),
  cancelled(NotificationCategory.reservations),
  bookReturned(NotificationCategory.books),
  dueReminder(NotificationCategory.books),
  bookAdded(NotificationCategory.books),
  seatUpdate(NotificationCategory.seats);

  const LibrarianNotificationType(this.category);
  final NotificationCategory category;
}

/// An in-app notification shown to the Librarian.
/// Named LibrarianNotification to avoid clashing with Flutter's Notification.
class LibrarianNotification {
  const LibrarianNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.reservationId,
    this.isRead = false,
  });

  final String id;
  final LibrarianNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;

  /// Set when tapping the notification should open a reservation.
  final String? reservationId;
  final bool isRead;

  /// Reads a `notifications/{id}` document (audience "librarian").
  factory LibrarianNotification.fromMap(String id, Map<String, dynamic> map) {
    var type = LibrarianNotificationType.newRequest;
    for (final value in LibrarianNotificationType.values) {
      if (value.name == map['type']) type = value;
    }
    return LibrarianNotification(
      id: id,
      type: type,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reservationId: map['reservationId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'audience': 'librarian',
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'reservationId': reservationId,
      'isRead': isRead,
    };
  }

  LibrarianNotification copyWith({bool? isRead}) {
    return LibrarianNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      reservationId: reservationId,
      isRead: isRead ?? this.isRead,
    );
  }
}
