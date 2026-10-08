import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/image_storage_service.dart';
import '../models/action_result.dart';
import '../models/book_record.dart';
import '../models/borrowing_record.dart';
import '../models/librarian_notification.dart';
import '../models/librarian_settings.dart';
import '../models/member_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';

/// The Librarian module's single source of truth.
///
/// Every Librarian screen reads data and calls actions through this class
/// (via LibrarianScope) and rebuilds when it notifies listeners. The business
/// rules that only need the current data (e.g. "a book with no copies cannot
/// be approved") live here, so both implementations follow the same rules:
///
/// - LibrarianFirestoreRepository: the real app. Data is kept in Cloud
///   Firestore, shared with the Student screens and survives restarts.
/// - LibrarianMockRepository: in-memory sample data, used by widget tests and
///   by the explicit demo mode (`--dart-define=LIBMATE_DEMO_DATA=true`).
///
/// Actions return an [ActionResult]; a failure carries the reason to show,
/// so screens never report success for a write that did not happen.
abstract class LibrarianRepository extends ChangeNotifier {
  List<BookRecord> get books;
  List<SeatRecord> get seats;
  List<ReservationRecord> get reservations;
  List<LibrarianNotification> get notifications;
  List<BorrowingRecord> get borrowings;
  List<MemberRecord> get members;
  LibrarianSettings get settings;

  /// True until the first data has arrived from the database.
  bool get isLoading => false;

  /// Why data could not be loaded (e.g. missing Firestore permission).
  String? get loadError => null;

  /// True for the in-memory sample data, which is not saved anywhere.
  bool get isDemoData => false;

  /// Whether book covers / seat photos can be uploaded by this repository.
  bool get supportsImageUpload => false;

  final StreamController<LibrarianNotification> _incoming =
      StreamController<LibrarianNotification>.broadcast();

  /// Every Librarian notification (`audience: "librarian"`) as it arrives
  /// in real time, for the top banner (LibrarianToastController): all types,
  /// from students and from librarians, read or unread. Only those already
  /// there when the data first loaded are skipped.
  Stream<LibrarianNotification> get incomingNotifications => _incoming.stream;

  /// Publishes a newly arrived notification (see [incomingNotifications]).
  @protected
  void announceNotification(LibrarianNotification notification) {
    if (!_incoming.isClosed) _incoming.add(notification);
  }

  @override
  void dispose() {
    _incoming.close();
    super.dispose();
  }

  bool _darkMode = false;

  /// The Librarian screens use the dark theme (Settings > Dark Mode).
  bool get darkMode => _darkMode;

  /// Updates the theme choice in memory and rebuilds the Librarian screens.
  @protected
  void applyDarkMode(bool on) {
    if (on == _darkMode) return;
    _darkMode = on;
    notifyListeners();
  }

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  // ---------------- Lookups ----------------

  ReservationRecord? reservationById(String id) =>
      _firstWhereOrNull(reservations, (r) => r.id == id);

  BookRecord? bookById(String id) =>
      _firstWhereOrNull(books, (b) => b.id == id);

  SeatRecord? seatById(String id) =>
      _firstWhereOrNull(seats, (s) => s.id == id);

  BorrowingRecord? borrowingById(String id) =>
      _firstWhereOrNull(borrowings, (b) => b.id == id);

  MemberRecord? memberById(String id) =>
      _firstWhereOrNull(members, (m) => m.id == id);

  /// How the seat map shows [seat]: Maintenance / Occupied as the librarian
  /// set them; otherwise Reserved (yellow) while a confirmed booking for it
  /// has not ended yet, else Available. Seat bookings are confirmed as soon
  /// as a student makes them, so the seat turns yellow straight away (from
  /// the live `reservations` data) and back to Available after the booking.
  SeatStatus seatMapStatus(SeatRecord seat, {DateTime? now}) {
    if (seat.status != SeatStatus.available) return seat.status;
    return hasUpcomingBooking(seat.id, now: now) ? SeatStatus.reserved : SeatStatus.available;
  }

  /// All seats with the status the seat map shows (see [seatMapStatus]).
  List<SeatRecord> get seatsAsShown => [
    for (final seat in seats) seat.copyWith(status: seatMapStatus(seat)),
  ];

  /// True if the seat has a confirmed booking whose time has not ended.
  bool hasUpcomingBooking(String seatId, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    return reservations.any((r) {
      if (r.type != ReservationType.seat ||
          r.itemId != seatId ||
          r.status != ReservationStatus.approved) {
        return false;
      }
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      if (day.isAfter(today)) return true;
      if (day.isBefore(today)) return false;
      return (r.endHour ?? 24) > clock.hour; // today: until its end hour
    });
  }

  /// The approved booking holding a seat (today or later), if any.
  ReservationRecord? activeReservationForSeat(String seatId) {
    final today = _today();
    final active =
        reservations
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
    final key = BookRecord.isbnKeyOf(isbn);
    return books.any(
      (b) => b.id != exceptBookId && BookRecord.isbnKeyOf(b.isbn) == key,
    );
  }

  bool seatNumberExists(
    String seatNumber,
    String readingRoom, {
    String? exceptSeatId,
  }) {
    final key = SeatRecord.seatKeyOf(seatNumber, readingRoom);
    return seats.any(
      (s) =>
          s.id != exceptSeatId &&
          SeatRecord.seatKeyOf(s.seatNumber, s.readingRoom) == key,
    );
  }

  // ---------------- Rules ----------------

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
      return null;
    }

    final seat = seatById(reservation.itemId);
    if (seat == null) return 'This seat no longer exists.';
    // Maintenance blocks every date. "Occupied" (e.g. a walk-in) is the
    // seat's state right now, so it only blocks bookings for today. Other
    // bookings are checked by time below (and by seat slots in Firestore).
    final blockedNow =
        isSameDay(reservation.date, DateTime.now()) &&
        seat.status == SeatStatus.occupied;
    if (seat.status == SeatStatus.maintenance || blockedNow) {
      return 'Seat ${seat.seatNumber} is ${seat.status.label.toLowerCase()} '
          'and cannot be reserved right now. The reservation stays pending.';
    }
    final clash = reservations.any(
      (r) =>
          r.id != reservation.id &&
          r.status == ReservationStatus.approved &&
          r.overlaps(reservation),
    );
    if (clash) {
      return 'Seat ${seat.seatNumber} is already booked for an overlapping '
          'time on that day.';
    }
    return null;
  }

  /// Why an approved book reservation cannot be handed over yet, or null.
  String? collectBlocker(ReservationRecord reservation) {
    if (reservation.type != ReservationType.book) {
      return 'Only book reservations are collected.';
    }
    if (reservation.status != ReservationStatus.approved) {
      return 'Only approved reservations can be marked as collected.';
    }
    if (bookById(reservation.itemId) == null) {
      return 'This book is no longer in the catalogue.';
    }
    if (currentLoanCount(reservation.studentId) >= settings.maxBorrowLimit) {
      return '${reservation.studentName} already has ${settings.maxBorrowLimit} '
          'books on loan (the borrowing limit).';
    }
    return null;
  }

  /// Why a book reservation cannot be marked as returned, or null if it can
  /// (only Collected -> Returned is allowed).
  String? returnBlocker(ReservationRecord reservation) {
    if (reservation.type != ReservationType.book) {
      return 'Only book reservations are returned.';
    }
    if (reservation.isReturned) return 'This book has already been returned.';
    if (!reservation.isCollected) {
      return 'Only collected books can be marked as returned.';
    }
    return null;
  }

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
    final waiting = reservations.any(
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

  /// Why a book cannot be deleted, or null if it can: deleting it would
  /// break a pending/approved reservation or a loan that is not returned.
  String? bookDeleteBlocker(String bookId) {
    final reserved = reservations
        .where(
          (r) =>
              r.type == ReservationType.book &&
              r.itemId == bookId &&
              r.isActive,
        )
        .length;
    if (reserved > 0) {
      return 'This book has $reserved active reservation${reserved == 1 ? '' : 's'}. '
          'Approve, reject or complete ${reserved == 1 ? 'it' : 'them'} first.';
    }
    final onLoan = borrowings
        .where((b) => b.bookId == bookId && !b.isReturned)
        .length;
    if (onLoan > 0) {
      return '$onLoan cop${onLoan == 1 ? 'y is' : 'ies are'} still on loan. '
          'Mark ${onLoan == 1 ? 'it' : 'them'} as returned first.';
    }
    return null;
  }

  /// Why a seat cannot be deleted, or null: it has a pending or approved
  /// booking for today or later.
  String? seatDeleteBlocker(String seatId) {
    final today = _today();
    final upcoming = reservations
        .where(
          (r) =>
              r.type == ReservationType.seat &&
              r.itemId == seatId &&
              r.isActive &&
              !r.date.isBefore(today),
        )
        .length;
    if (upcoming == 0) return null;
    return 'This seat has $upcoming upcoming booking${upcoming == 1 ? '' : 's'}. '
        'Reject or complete ${upcoming == 1 ? 'it' : 'them'} before deleting the seat.';
  }

  /// Checks a new/edited book before saving, or returns the reason it is refused.
  String? bookInputError({
    required String isbn,
    required int totalCopies,
    String? exceptBookId,
  }) {
    if (isbnExists(isbn, exceptBookId: exceptBookId)) {
      return exceptBookId == null
          ? 'A book with this ISBN already exists.'
          : 'Another book already uses this ISBN.';
    }
    if (totalCopies < 1) return 'Total copies must be at least 1.';
    if (exceptBookId != null) {
      final book = bookById(exceptBookId);
      if (book == null) return 'Book not found.';
      if (totalCopies < book.copiesOut) {
        return '${book.copiesOut} copies are currently reserved or borrowed, '
            'so total copies cannot be less than ${book.copiesOut}.';
      }
    }
    return null;
  }

  /// Checks a new/edited seat before saving.
  String? seatInputError({
    required String seatNumber,
    required String readingRoom,
    String? exceptSeatId,
  }) {
    if (seatNumberExists(seatNumber, readingRoom, exceptSeatId: exceptSeatId)) {
      return 'Seat ${seatNumber.trim().toUpperCase()} already exists in ${readingRoom.trim()}.';
    }
    return null;
  }

  /// Checks settings make sense before saving.
  String? settingsError(LibrarianSettings settings) {
    if (settings.openingHour >= settings.closingHour) {
      return 'Closing time must be after opening time.';
    }
    if (settings.maxBorrowLimit < 1 || settings.maxBorrowLimit > 20) {
      return 'Borrowing limit must be between 1 and 20 books.';
    }
    if (settings.dailyFineRate < 0 || settings.dailyFineRate > 1000) {
      return 'Daily overdue fine must be between Rs. 0 and Rs. 1000.';
    }
    if (settings.loanPeriodDays < 1 || settings.loanPeriodDays > 60) {
      return 'Borrowing period must be between 1 and 60 days.';
    }
    if (settings.seatBookingHours < 1 || settings.seatBookingHours > 8) {
      return 'Seat booking duration must be between 1 and 8 hours.';
    }
    return null;
  }

  // ---------------- Members ----------------

  List<BorrowingRecord> borrowingsForMember(String memberId) =>
      borrowings.where((b) => b.memberId == memberId).toList();

  List<ReservationRecord> reservationsForMember(String memberId) =>
      reservations.where((r) => r.studentId == memberId).toList();

  /// Books the member has now (not yet returned).
  int currentLoanCount(String memberId) =>
      borrowings.where((b) => b.memberId == memberId && !b.isReturned).length;

  int overdueLoanCount(String memberId) => borrowings
      .where(
        (b) => b.memberId == memberId && b.status == BorrowingStatus.overdue,
      )
      .length;

  /// Pending or approved reservations.
  int activeReservationCount(String memberId) =>
      reservations.where((r) => r.studentId == memberId && r.isActive).length;

  // ---------------- Actions ----------------

  /// Approves a pending reservation and sets aside the book copy or seat.
  /// Refused (and nothing changes) if [approvalBlocker] returns a reason.
  Future<ActionResult> approveReservation(String id);

  /// Rejects a pending reservation (and frees its seat slots).
  Future<ActionResult> rejectReservation(String id, String reason);

  /// The student collected an approved book (Ready for Pickup -> Collected):
  /// the reservation becomes `collected` and a loan (borrowing) is created.
  /// Refused if [collectBlocker] gives a reason.
  Future<ActionResult> markReservationCollected(String id);

  /// The student returned a collected book (Collected -> Returned): the
  /// reservation becomes `returned`, its loan is closed and the copy is back
  /// on the shelf. Refused if [returnBlocker] gives a reason.
  Future<ActionResult> markReservationReturned(String id);

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
  });

  /// Updates a book. Changing [totalCopies] also changes the available copies
  /// by the same amount; it cannot drop below the copies currently out.
  /// [coverAsset] is the book's cover after the edit (null = no cover).
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
  });

  /// Deletes a book; refused if [bookDeleteBlocker] gives a reason.
  Future<ActionResult> deleteBook(String id);

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
    ImageUpload? image,
    void Function(double progress)? onUploadProgress,
  });

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
    ImageUpload? newImage,
    bool removeImage = false,
    void Function(double progress)? onUploadProgress,
  });

  /// Deletes a seat; refused if [seatDeleteBlocker] gives a reason.
  Future<ActionResult> deleteSeat(String id);

  Future<ActionResult> updateSeatStatus(String seatId, SeatStatus status);

  /// Marks a loan as returned and puts the copy back on the shelf.
  Future<ActionResult> markBorrowingReturned(String id);

  /// Extends the due date by the default loan period (see Settings).
  Future<ActionResult> renewBorrowing(String id);

  Future<ActionResult> updateMemberStatus(String id, MemberStatus status);

  /// Saves new settings after checking them with [settingsError].
  Future<ActionResult> updateSettings(LibrarianSettings settings);

  Future<void> markNotificationRead(String id);

  Future<void> markAllNotificationsRead();

  /// Switches the Librarian screens to dark (or light) mode and remembers the
  /// choice for this librarian. The switch happens at once; if saving fails
  /// the previous mode is restored and the reason returned.
  Future<ActionResult> setDarkMode(bool on);

  // ---------------- Helpers ----------------

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static T? _firstWhereOrNull<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}
