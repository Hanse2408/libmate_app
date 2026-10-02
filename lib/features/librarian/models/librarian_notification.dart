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
