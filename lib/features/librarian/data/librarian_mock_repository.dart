import 'package:flutter/foundation.dart';

import '../models/action_result.dart';
import '../models/book_record.dart';
import '../models/librarian_notification.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import 'librarian_mock_data.dart';

/// In-memory data source for the Librarian module (no Firebase yet).
///
/// It is the single source of truth for every Librarian screen and the only
/// place where data changes. All business rules live here (e.g. a book with
/// no copies cannot be approved), never in the UI. It notifies listeners after
/// each change, the same way a Firestore stream would push updates later.
/// Write methods return Futures so screens will not need to change when this
/// is replaced by a Firestore-backed repository.
class LibrarianMockRepository extends ChangeNotifier {
  // List.of makes editable copies (the sample lists are constant).
  LibrarianMockRepository()
    : _books = List.of(LibrarianMockData.books()),
      _seats = List.of(LibrarianMockData.seats()),
      _reservations = List.of(LibrarianMockData.reservations()),
      _notifications = List.of(LibrarianMockData.notifications());

  /// Standard loan period for an approved book reservation.
  static const int loanPeriodDays = 14;

  final List<BookRecord> _books;
  final List<SeatRecord> _seats;
  final List<ReservationRecord> _reservations;
  final List<LibrarianNotification> _notifications;

  List<BookRecord> get books => List.unmodifiable(_books);
  List<SeatRecord> get seats => List.unmodifiable(_seats);
  List<ReservationRecord> get reservations => List.unmodifiable(_reservations);
  List<LibrarianNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  // ---------------- Lookups ----------------

  ReservationRecord? reservationById(String id) =>
      _firstWhereOrNull(_reservations, (r) => r.id == id);

  BookRecord? bookById(String id) => _firstWhereOrNull(_books, (b) => b.id == id);

  SeatRecord? seatById(String id) => _firstWhereOrNull(_seats, (s) => s.id == id);

  /// The approved booking currently holding a seat (today or later), if any.
  ReservationRecord? activeReservationForSeat(String seatId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = _reservations
        .where(
          (r) =>
              r.type == ReservationType.seat &&
              r.itemId == seatId &&
              r.status == ReservationStatus.approved &&
              !r.date.isBefore(today),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return active.isEmpty ? null : active.first;
  }

  bool isbnExists(String isbn, {String? exceptBookId}) {
    final key = _isbnKey(isbn);
    return _books.any((b) => b.id != exceptBookId && _isbnKey(b.isbn) == key);
  }

  bool seatNumberExists(String seatNumber, String readingRoom) {
    return _seats.any(
      (s) =>
          s.seatNumber.toUpperCase() == seatNumber.trim().toUpperCase() &&
          s.readingRoom.toLowerCase() == readingRoom.trim().toLowerCase(),
    );
  }

  // ---------------- Reservations ----------------

  /// Why [reservation] cannot be approved right now, or null if it can.
  /// Used by approveReservation, the details screen and the dashboard.
  String? approvalBlocker(ReservationRecord reservation) {
    if (!reservation.isPending) {
      return 'This reservation is already ${reservation.status.label.toLowerCase()}.';
    }
    if (reservation.type == ReservationType.book) {
      final book = bookById(reservation.itemId);
      if (book == null) return 'This book is no longer in the catalogue.';
      if (!book.isAvailable) {
        return 'No copies of "${book.title}" are available right now. '
            'The reservation stays pending until a copy is returned.';
      }
    } else {
      final seat = seatById(reservation.itemId);
      if (seat == null) return 'This seat no longer exists.';
      if (seat.status != SeatStatus.available) {
        return 'Seat ${seat.seatNumber} is ${seat.status.label.toLowerCase()} '
            'and cannot be reserved right now. The reservation stays pending.';
      }
    }
    return null;
  }

  /// Approves a pending reservation and reserves the book copy or seat.
  /// Refused (and nothing changes) if [approvalBlocker] returns a reason.
  Future<ActionResult> approveReservation(String id) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) return const ActionResult.failure('Reservation not found.');
    final reservation = _reservations[index];

    final blocker = approvalBlocker(reservation);
    if (blocker != null) return ActionResult.failure(blocker);

    if (reservation.type == ReservationType.book) {
      final bookIndex = _books.indexWhere((b) => b.id == reservation.itemId);
      final book = _books[bookIndex];
      _books[bookIndex] = book.copyWith(availableCopies: book.availableCopies - 1);
    } else {
      _setSeatStatus(reservation.itemId, SeatStatus.reserved);
    }

    _reservations[index] = reservation.copyWith(status: ReservationStatus.approved);
    _markReservationNotificationsRead(id);
    _addNotification(
      type: LibrarianNotificationType.approved,
      title: 'Reservation Approved',
      message: '${reservation.itemName} — ${reservation.studentName}',
      reservationId: id,
    );
    notifyListeners();
    return const ActionResult.success();
  }

  /// Rejects a pending reservation. Already decided reservations are refused,
  /// so a reservation cannot be rejected twice.
  Future<ActionResult> rejectReservation(String id, String reason) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) return const ActionResult.failure('Reservation not found.');
    final reservation = _reservations[index];
    if (!reservation.isPending) {
      return ActionResult.failure(
        'This reservation is already ${reservation.status.label.toLowerCase()}.',
      );
    }

    _reservations[index] = reservation.copyWith(
      status: ReservationStatus.rejected,
      rejectionReason: reason.trim().isEmpty ? 'Rejected by librarian.' : reason.trim(),
    );
    _markReservationNotificationsRead(id);
    _addNotification(
      type: LibrarianNotificationType.rejected,
      title: 'Reservation Rejected',
      message: '${reservation.itemName} — ${reservation.studentName}',
      reservationId: id,
    );
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Books ----------------

  Future<ActionResult> addBook({
    required String title,
    required String author,
    required String isbn,
    required String category,
    required String language,
    required String shelfLocation,
    required int totalCopies,
    String description = '',
  }) async {
    if (isbnExists(isbn)) {
      return const ActionResult.failure('A book with this ISBN already exists.');
    }
    if (totalCopies < 1) {
      return const ActionResult.failure('Total copies must be at least 1.');
    }

    _books.insert(
      0,
      BookRecord(
        id: _nextId('B', _books.length),
        title: title.trim(),
        author: author.trim(),
        isbn: isbn.trim(),
        category: category.trim(),
        language: language.trim(),
        shelfLocation: shelfLocation.trim().toUpperCase(),
        totalCopies: totalCopies,
        availableCopies: totalCopies,
        description: description.trim(),
      ),
    );
    _addNotification(
      type: LibrarianNotificationType.bookAdded,
      title: 'New Book Added',
      message: '"${title.trim()}" was added to the catalogue.',
    );
    notifyListeners();
    return const ActionResult.success();
  }

  /// Updates a book. Changing [totalCopies] also changes the available copies
  /// by the same amount; it cannot drop below the copies currently out.
  Future<ActionResult> updateBook({
    required String id,
    required String title,
    required String author,
    required String isbn,
    required String category,
    required String language,
    required String shelfLocation,
    required int totalCopies,
    String description = '',
  }) async {
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return const ActionResult.failure('Book not found.');
    final book = _books[index];

    if (isbnExists(isbn, exceptBookId: id)) {
      return const ActionResult.failure('Another book already uses this ISBN.');
    }
    if (totalCopies < book.copiesOut) {
      return ActionResult.failure(
        '${book.copiesOut} copies are currently reserved or borrowed, '
        'so total copies cannot be less than ${book.copiesOut}.',
      );
    }

    _books[index] = book.copyWith(
      title: title.trim(),
      author: author.trim(),
      isbn: isbn.trim(),
      category: category.trim(),
      language: language.trim(),
      shelfLocation: shelfLocation.trim().toUpperCase(),
      totalCopies: totalCopies,
      availableCopies: totalCopies - book.copiesOut,
      description: description.trim(),
    );
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Seats ----------------

  Future<ActionResult> addSeat({
    required String seatNumber,
    required String zone,
    required String readingRoom,
    required SeatType type,
    bool hasPowerOutlet = false,
    bool hasReadingLamp = false,
    bool isAccessible = false,
    bool isNearWindow = false,
    String note = '',
  }) async {
    if (seatNumberExists(seatNumber, readingRoom)) {
      return ActionResult.failure(
        'Seat ${seatNumber.trim().toUpperCase()} already exists in ${readingRoom.trim()}.',
      );
    }

    _seats.add(
      SeatRecord(
        id: _nextId('S', _seats.length),
        seatNumber: seatNumber.trim().toUpperCase(),
        zone: zone.trim(),
        readingRoom: readingRoom.trim(),
        type: type,
        status: SeatStatus.available,
        hasPowerOutlet: hasPowerOutlet,
        hasReadingLamp: hasReadingLamp,
        isAccessible: isAccessible,
        isNearWindow: isNearWindow,
        note: note.trim(),
      ),
    );
    notifyListeners();
    return const ActionResult.success();
  }

  Future<void> updateSeatStatus(String seatId, SeatStatus status) async {
    _setSeatStatus(seatId, status);
    notifyListeners();
  }

  // ---------------- Notifications ----------------

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  // ---------------- Helpers ----------------

  void _setSeatStatus(String seatId, SeatStatus status) {
    final index = _seats.indexWhere((s) => s.id == seatId);
    if (index != -1) _seats[index] = _seats[index].copyWith(status: status);
  }

  /// Once a request is decided, its "new request" alerts are no longer unread.
  void _markReservationNotificationsRead(String reservationId) {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].reservationId == reservationId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  /// Records an action the librarian just took. It is already read, so the
  /// librarian's own actions do not increase the unread badge.
  void _addNotification({
    required LibrarianNotificationType type,
    required String title,
    required String message,
    String? reservationId,
  }) {
    _notifications.insert(
      0,
      LibrarianNotification(
        id: _nextId('N', _notifications.length),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        reservationId: reservationId,
        isRead: true,
      ),
    );
  }

  /// Builds ids such as B010 or S019.
  String _nextId(String prefix, int currentCount) {
    return '$prefix${(currentCount + 1).toString().padLeft(3, '0')}';
  }

  /// ISBNs are compared without hyphens or spaces.
  static String _isbnKey(String isbn) =>
      isbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

  static T? _firstWhereOrNull<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}
