import 'package:flutter/foundation.dart';

import '../models/action_result.dart';
import '../models/book_record.dart';
import '../models/borrowing_record.dart';
import '../models/librarian_notification.dart';
import '../models/librarian_settings.dart';
import '../models/member_record.dart';
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
      _notifications = List.of(LibrarianMockData.notifications()),
      _borrowings = List.of(LibrarianMockData.borrowings()),
      _members = List.of(LibrarianMockData.members());

  final List<BookRecord> _books;
  final List<SeatRecord> _seats;
  final List<ReservationRecord> _reservations;
  final List<LibrarianNotification> _notifications;
  final List<BorrowingRecord> _borrowings;
  final List<MemberRecord> _members;
  LibrarianSettings _settings = const LibrarianSettings();

  List<BookRecord> get books => List.unmodifiable(_books);
  List<SeatRecord> get seats => List.unmodifiable(_seats);
  List<ReservationRecord> get reservations => List.unmodifiable(_reservations);
  List<LibrarianNotification> get notifications =>
      List.unmodifiable(_notifications);

  List<BorrowingRecord> get borrowings => List.unmodifiable(_borrowings);
  List<MemberRecord> get members => List.unmodifiable(_members);
  LibrarianSettings get settings => _settings;

  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  // ---------------- Lookups ----------------

  ReservationRecord? reservationById(String id) =>
      _firstWhereOrNull(_reservations, (r) => r.id == id);

  BookRecord? bookById(String id) => _firstWhereOrNull(_books, (b) => b.id == id);

  SeatRecord? seatById(String id) => _firstWhereOrNull(_seats, (s) => s.id == id);

  BorrowingRecord? borrowingById(String id) =>
      _firstWhereOrNull(_borrowings, (b) => b.id == id);

  MemberRecord? memberById(String id) =>
      _firstWhereOrNull(_members, (m) => m.id == id);

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

  // ---------------- Borrowings (circulation) ----------------

  /// Why [loan] cannot be renewed right now, or null if it can.
  /// Used by renewBorrowing and to enable/explain the Renew button.
  String? renewBlocker(BorrowingRecord loan) {
    final status = loan.status;
    if (status == BorrowingStatus.returned) {
      return 'This book has already been returned.';
    }
    if (status == BorrowingStatus.overdue) {
      return 'Overdue loans cannot be renewed. Please return the book first.';
    }
    if (loan.renewals >= LibrarianSettings.maxRenewals) {
      return 'This loan has already been renewed ${LibrarianSettings.maxRenewals} times.';
    }
    final waiting = _reservations.any(
      (r) =>
          r.type == ReservationType.book &&
          r.itemId == loan.bookId &&
          r.isPending,
    );
    if (waiting) {
      return 'Another student has reserved this book, so it cannot be renewed.';
    }
    return null;
  }

  /// Marks a loan as returned and puts the copy back on the shelf.
  /// A returned loan cannot be returned again.
  Future<ActionResult> markBorrowingReturned(String id) async {
    final index = _borrowings.indexWhere((b) => b.id == id);
    if (index == -1) return const ActionResult.failure('Loan not found.');
    final loan = _borrowings[index];
    if (loan.isReturned) {
      return const ActionResult.failure('This book has already been returned.');
    }

    _borrowings[index] = loan.copyWith(returnedAt: DateTime.now());
    final bookIndex = _books.indexWhere((b) => b.id == loan.bookId);
    if (bookIndex != -1) {
      final book = _books[bookIndex];
      if (book.availableCopies < book.totalCopies) {
        _books[bookIndex] = book.copyWith(availableCopies: book.availableCopies + 1);
      }
    }
    _addNotification(
      type: LibrarianNotificationType.bookReturned,
      title: 'Book Returned',
      message: '${loan.memberName} returned "${loan.bookTitle}".',
    );
    notifyListeners();
    return const ActionResult.success();
  }

  /// Extends the due date by the default loan period (see Settings).
  /// Refused if [renewBlocker] returns a reason.
  Future<ActionResult> renewBorrowing(String id) async {
    final index = _borrowings.indexWhere((b) => b.id == id);
    if (index == -1) return const ActionResult.failure('Loan not found.');
    final loan = _borrowings[index];

    final blocker = renewBlocker(loan);
    if (blocker != null) return ActionResult.failure(blocker);

    _borrowings[index] = loan.copyWith(
      dueDate: loan.dueDate.add(Duration(days: _settings.loanPeriodDays)),
      renewals: loan.renewals + 1,
    );
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Members ----------------

  List<BorrowingRecord> borrowingsForMember(String memberId) =>
      _borrowings.where((b) => b.memberId == memberId).toList();

  List<ReservationRecord> reservationsForMember(String memberId) =>
      _reservations.where((r) => r.studentId == memberId).toList();

  /// Books the member has now (not yet returned).
  int currentLoanCount(String memberId) =>
      _borrowings.where((b) => b.memberId == memberId && !b.isReturned).length;

  int overdueLoanCount(String memberId) => _borrowings
      .where((b) => b.memberId == memberId && b.status == BorrowingStatus.overdue)
      .length;

  /// Pending or approved reservations.
  int activeReservationCount(String memberId) => _reservations
      .where(
        (r) =>
            r.studentId == memberId &&
            (r.isPending || r.status == ReservationStatus.approved),
      )
      .length;

  Future<ActionResult> updateMemberStatus(String id, MemberStatus status) async {
    final index = _members.indexWhere((m) => m.id == id);
    if (index == -1) return const ActionResult.failure('Member not found.');
    if (_members[index].status == status) {
      return ActionResult.failure('This account is already ${status.label.toLowerCase()}.');
    }
    _members[index] = _members[index].copyWith(status: status);
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Settings ----------------

  /// Saves new settings after checking the values make sense.
  Future<ActionResult> updateSettings(LibrarianSettings settings) async {
    if (settings.openingHour >= settings.closingHour) {
      return const ActionResult.failure('Closing time must be after opening time.');
    }
    if (settings.maxBorrowLimit < 1 || settings.maxBorrowLimit > 20) {
      return const ActionResult.failure('Borrowing limit must be between 1 and 20 books.');
    }
    if (settings.loanPeriodDays < 1 || settings.loanPeriodDays > 60) {
      return const ActionResult.failure('Borrowing period must be between 1 and 60 days.');
    }
    if (settings.seatBookingHours < 1 || settings.seatBookingHours > 8) {
      return const ActionResult.failure('Seat booking duration must be between 1 and 8 hours.');
    }
    _settings = settings;
    notifyListeners();
    return const ActionResult.success();
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
