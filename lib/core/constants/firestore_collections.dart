/// Names of the Cloud Firestore collections used by LibMate.
///
/// Every screen reads and writes the same collections, so a book or seat
/// a librarian adds is the one students see. See firestore.rules for who
/// may read or write each collection.
class FirestoreCollections {
  const FirestoreCollections._();

  /// User profiles and roles, `users/{uid}` (created at sign-up).
  static const String users = 'users';

  /// Library catalogue, `books/{autoId}`.
  static const String books = 'books';

  /// Reading-room seats, `seats/{autoId}`.
  static const String seats = 'seats';

  /// Book and seat reservations, `reservations/{autoId}`.
  static const String reservations = 'reservations';

  /// One document per booked seat-hour, `seatSlots/{seatId}_{yyyyMMdd}_{HH}`.
  static const String seatSlots = 'seatSlots';

  /// Book loans, `borrowings/{autoId}`.
  static const String borrowings = 'borrowings';

  /// In-app notifications, `notifications/{autoId}` (audience "librarian").
  static const String notifications = 'notifications';

  /// Digital books with a PDF, `ebooks/{autoId}` (separate from `books`).
  static const String ebooks = 'ebooks';

  /// Library-wide settings, the single document `settings/library`.
  static const String settings = 'settings';
  static const String librarySettingsDoc = 'library';
}

/// Firebase Storage folders for uploaded images.
class StorageFolders {
  const StorageFolders._();

  /// `seat_images/{seatId}/{timestamp}.{ext}`
  static const String seatImages = 'seat_images';

  /// `ebooks/{ebookId}/{timestamp}.pdf`
  static const String ebooks = 'ebooks';
}
