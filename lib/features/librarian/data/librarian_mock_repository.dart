import '../../../core/services/image_storage_service.dart';
import '../models/action_result.dart';
import '../models/book_record.dart';
import '../models/borrowing_record.dart';
import '../models/librarian_notification.dart';
import '../models/librarian_settings.dart';
import '../models/member_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import 'librarian_mock_data.dart';
import 'librarian_repository.dart';

/// In-memory sample data for the Librarian module. Nothing is saved: the
/// data resets when the app restarts.
///
/// Used by widget tests and by the explicit demo mode
/// (`--dart-define=LIBMATE_DEMO_DATA=true`); the real app uses
/// LibrarianFirestoreRepository. The rules are shared in LibrarianRepository.
class LibrarianMockRepository extends LibrarianRepository {
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


  @override
  List<BookRecord> get books => List.unmodifiable(_books);
  @override
  List<SeatRecord> get seats => List.unmodifiable(_seats);
  @override
  List<ReservationRecord> get reservations => List.unmodifiable(_reservations);
  @override
  List<LibrarianNotification> get notifications =>
      List.unmodifiable(_notifications);
  @override
  List<BorrowingRecord> get borrowings => List.unmodifiable(_borrowings);
  @override
  List<MemberRecord> get members => List.unmodifiable(_members);
  @override
  LibrarianSettings get settings => _settings;

  @override
  bool get isDemoData => true;

  // ---------------- Reservations ----------------

  @override
  Future<ActionResult> approveReservation(String id) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1)
      return const ActionResult.failure('Reservation not found.');
    final reservation = _reservations[index];

    final blocker = approvalBlocker(reservation);
    if (blocker != null) return ActionResult.failure(blocker);

    if (reservation.type == ReservationType.book) {
      final bookIndex = _books.indexWhere((b) => b.id == reservation.itemId);
      final book = _books[bookIndex];
      _books[bookIndex] = book.copyWith(
        availableCopies: book.availableCopies - 1,
      );
    } else if (LibrarianRepository.isSameDay(
      reservation.date,
      DateTime.now(),
    )) {
      // The seat map shows today, so only a booking for today reserves it now.
      _setSeatStatus(reservation.itemId, SeatStatus.reserved);
    }

    _reservations[index] = reservation.copyWith(
      status: ReservationStatus.approved,
    );
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

  /// Already decided reservations are refused, so a reservation cannot be
  /// rejected twice.
  @override
  Future<ActionResult> rejectReservation(String id, String reason) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1)
      return const ActionResult.failure('Reservation not found.');
    final reservation = _reservations[index];
    if (!reservation.isPending) {
      return ActionResult.failure(
        'This reservation is already ${reservation.status.label.toLowerCase()}.',
      );
    }

    _reservations[index] = reservation.copyWith(
      status: ReservationStatus.rejected,
      rejectionReason: reason.trim().isEmpty
          ? 'Rejected by librarian.'
          : reason.trim(),
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

  @override
  Future<ActionResult> markReservationCollected(String id) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1)
      return const ActionResult.failure('Reservation not found.');
    final reservation = _reservations[index];
    final blocker = collectBlocker(reservation);
    if (blocker != null) return ActionResult.failure(blocker);

    final book = bookById(reservation.itemId)!;
    final now = DateTime.now();
    _borrowings.insert(
      0,
      BorrowingRecord(
        id: 'LN-${3001 + _borrowings.length}',
        memberId: reservation.studentId,
        memberName: reservation.studentName,
        bookId: book.id,
        bookTitle: book.title,
        isbn: book.isbn,
        issuedAt: now,
        dueDate: now.add(
          Duration(
            days: reservation.loanPeriodDays ?? _settings.loanPeriodDays,
          ),
        ),
      ),
    );
    // The copy was set aside at approval and is now on loan, so the
    // available count does not change.
    _reservations[index] = reservation.copyWith(
      status: ReservationStatus.collected,
      collectedAt: now,
    );
    _addNotification(
      type: LibrarianNotificationType.bookCollected,
      title: 'Book Collected',
      message: '"${book.title}" is now on loan to ${reservation.studentName}.',
      reservationId: id,
    );
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Books ----------------

  @override
  Future<ActionResult> addBook({
    required String title,
    required String author,
    required String isbn,
    required String category,
    required String language,
    required String shelfLocation,
    required int totalCopies,
    String description = '',
    String? coverAsset,
    ImageUpload? coverImage,
    void Function(double progress)? onUploadProgress,
    String publisher = '',
    int publishedYear = 0,
    int pages = 0,
  }) async {
    final error = bookInputError(isbn: isbn, totalCopies: totalCopies);
    if (error != null) return ActionResult.failure(error);

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
        coverAsset: coverAsset,
        publisher: publisher.trim(),
        publishedYear: publishedYear,
        pages: pages,
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

  @override
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
    String? coverAsset,
    ImageUpload? coverImage,
    void Function(double progress)? onUploadProgress,
    String publisher = '',
    int publishedYear = 0,
    int pages = 0,
  }) async {
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return const ActionResult.failure('Book not found.');
    final error = bookInputError(
      isbn: isbn,
      totalCopies: totalCopies,
      exceptBookId: id,
    );
    if (error != null) return ActionResult.failure(error);

    final book = _books[index];
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
      coverAsset: coverAsset,
      clearCover: coverAsset == null,
      publisher: publisher.trim(),
      publishedYear: publishedYear,
      pages: pages,
    );
    notifyListeners();
    return const ActionResult.success();
  }

  @override
  Future<ActionResult> deleteBook(String id) async {
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return const ActionResult.failure('Book not found.');
    final blocker = bookDeleteBlocker(id);
    if (blocker != null) return ActionResult.failure(blocker);
    _books.removeAt(index);
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Seats ----------------

  @override
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
    final error = seatInputError(
      seatNumber: seatNumber,
      readingRoom: readingRoom,
    );
    if (error != null) return ActionResult.failure(error);

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
    _addNotification(
      type: LibrarianNotificationType.seatUpdate,
      title: 'New Seat Added',
      message:
          'Seat ${seatNumber.trim().toUpperCase()} was added to ${readingRoom.trim()}.',
    );
    notifyListeners();
    return const ActionResult.success();
  }

  @override
  Future<ActionResult> updateSeat({
    required String id,
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
    final index = _seats.indexWhere((s) => s.id == id);
    if (index == -1) return const ActionResult.failure('Seat not found.');
    final error = seatInputError(
      seatNumber: seatNumber,
      readingRoom: readingRoom,
      exceptSeatId: id,
    );
    if (error != null) return ActionResult.failure(error);

    _seats[index] = _seats[index].copyWith(
      seatNumber: seatNumber.trim().toUpperCase(),
      zone: zone.trim(),
      readingRoom: readingRoom.trim(),
      type: type,
      hasPowerOutlet: hasPowerOutlet,
      hasReadingLamp: hasReadingLamp,
      isAccessible: isAccessible,
      isNearWindow: isNearWindow,
      note: note.trim(),
    );
    notifyListeners();
    return const ActionResult.success();
  }

  @override
  Future<ActionResult> deleteSeat(String id) async {
    final index = _seats.indexWhere((s) => s.id == id);
    if (index == -1) return const ActionResult.failure('Seat not found.');
    final blocker = seatDeleteBlocker(id);
    if (blocker != null) return ActionResult.failure(blocker);
    _seats.removeAt(index);
    notifyListeners();
    return const ActionResult.success();
  }

  @override
  Future<ActionResult> updateSeatStatus(
    String seatId,
    SeatStatus status,
  ) async {
    if (seatById(seatId) == null)
      return const ActionResult.failure('Seat not found.');
    _setSeatStatus(seatId, status);
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Borrowings (circulation) ----------------

  /// A returned loan cannot be returned again.
  @override
  Future<ActionResult> markReservationReturned(String id) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) {
      return const ActionResult.failure('Reservation not found.');
    }
    final reservation = _reservations[index];
    final blocker = returnBlocker(reservation);
    if (blocker != null) return ActionResult.failure(blocker);

    // The loan made when it was collected (demo loans keep no link, so
    // match the member and book).
    final loanIndex = _borrowings.indexWhere(
      (b) =>
          !b.isReturned &&
          b.memberId == reservation.studentId &&
          b.bookId == reservation.itemId,
    );
    if (loanIndex != -1) {
      return markBorrowingReturned(_borrowings[loanIndex].id);
    }
    _reservations[index] = reservation.copyWith(
      status: ReservationStatus.returned,
      returnedAt: DateTime.now(),
    );
    notifyListeners();
    return const ActionResult.success();
  }

  @override
  Future<ActionResult> markBorrowingReturned(String id) async {
    final index = _borrowings.indexWhere((b) => b.id == id);
    if (index == -1) return const ActionResult.failure('Loan not found.');
    final loan = _borrowings[index];
    if (loan.isReturned) {
      return const ActionResult.failure('This book has already been returned.');
    }

    final now = DateTime.now();
    _borrowings[index] = loan.copyWith(returnedAt: now);
    // The reservation this loan came from is Returned too.
    final resIndex = _reservations.indexWhere(
      (r) =>
          r.isCollected &&
          r.studentId == loan.memberId &&
          r.itemId == loan.bookId,
    );
    if (resIndex != -1) {
      _reservations[resIndex] = _reservations[resIndex].copyWith(
        status: ReservationStatus.returned,
        returnedAt: now,
      );
    }
    final bookIndex = _books.indexWhere((b) => b.id == loan.bookId);
    if (bookIndex != -1) {
      final book = _books[bookIndex];
      if (book.availableCopies < book.totalCopies) {
        _books[bookIndex] = book.copyWith(
          availableCopies: book.availableCopies + 1,
        );
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

  /// Refused if [renewBlocker] returns a reason.
  @override
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
    _addNotification(
      type: LibrarianNotificationType.loanRenewed,
      title: 'Loan Renewed',
      message: '"${loan.bookTitle}" for ${loan.memberName} was renewed.',
    );
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Members ----------------

  @override
  Future<ActionResult> updateMemberStatus(
    String id,
    MemberStatus status,
  ) async {
    return const ActionResult.failure(
      'Only Managers can activate or deactivate users.',
    );
  }

  // ---------------- Settings ----------------

  @override
  Future<ActionResult> updateSettings(LibrarianSettings settings) async {
    final error = settingsError(settings);
    if (error != null) return ActionResult.failure(error);
    _settings = settings;
    notifyListeners();
    return const ActionResult.success();
  }

  // ---------------- Notifications ----------------

  @override
  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  /// Demo data: remembered until the app restarts.
  @override
  Future<ActionResult> setDarkMode(bool on) async {
    applyDarkMode(on);
    return const ActionResult.success();
  }

  @override
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
  /// librarian's own actions do not increase the unread badge; it still
  /// shows the top banner, like every new Librarian notification.
  void _addNotification({
    required LibrarianNotificationType type,
    required String title,
    required String message,
    String? reservationId,
  }) {
    final notification = LibrarianNotification(
      id: _nextId('N', _notifications.length),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      reservationId: reservationId,
      isRead: true,
    );
    _notifications.insert(0, notification);
    announceNotification(notification);
  }

  /// Builds ids such as B010 or S019.
  String _nextId(String prefix, int currentCount) {
    return '$prefix${(currentCount + 1).toString().padLeft(3, '0')}';
  }
}
