import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../../../core/services/firestore_errors.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../models/notification.dart';
import '../models/action_result.dart';
import '../models/book_record.dart';
import '../models/borrowing_record.dart';
import '../models/librarian_notification.dart';
import '../models/librarian_settings.dart';
import '../models/member_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import 'librarian_repository.dart';

/// Librarian data stored in Cloud Firestore (the real app).
///
/// - Reading: each collection is watched with a snapshot listener. The latest
///   documents are kept in lists, so screens read them like before and
///   rebuild on every change (also changes made by students).
/// - Writing: actions write to Firestore. Changes that must stay consistent
///   (copies, seat slots, loans) run in a transaction that re-reads the
///   documents first. The lists update when Firestore confirms the change,
///   and a failed write returns an ActionResult.failure.
/// - Seat photos are uploaded to Cloudinary; only the URL and public ID are
///   saved here.
class LibrarianFirestoreRepository extends LibrarianRepository {
  LibrarianFirestoreRepository({
    required FirebaseFirestore firestore,
    required ImageStorage imageStorage,
    this.librarianUid = '',
    this.uploadTimeout = const Duration(minutes: 2),
    this.writeTimeout = const Duration(seconds: 30),
  }) : _db = firestore,
       _images = imageStorage {
    _listen();
    _loadDarkMode();
  }

  final FirebaseFirestore _db;
  final ImageStorage _images;

  /// Signed-in librarian, saved as `createdBy` on new books and seats.
  final String librarianUid;

  /// Longest wait for an image upload, so a blocked network does not keep the
  /// Save button loading indefinitely.
  final Duration uploadTimeout;

  /// Longest wait for Firestore to confirm a new book. Offline, Firestore
  /// queues writes and never completes the Future, so this stops the spinner.
  final Duration writeTimeout;

  List<BookRecord> _books = const [];
  List<SeatRecord> _seats = const [];
  List<ReservationRecord> _reservations = const [];
  List<LibrarianNotification> _notifications = const [];
  List<BorrowingRecord> _borrowings = const [];
  List<MemberRecord> _members = const [];
  LibrarianSettings _settings = const LibrarianSettings();

  /// Collections whose first snapshot has not arrived yet.
  final Set<String> _waiting = {};
  String? _loadError;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  List<BookRecord> get books => _books;
  @override
  List<SeatRecord> get seats => _seats;
  @override
  List<ReservationRecord> get reservations => _reservations;
  @override
  List<LibrarianNotification> get notifications => _notifications;
  @override
  List<BorrowingRecord> get borrowings => _borrowings;
  @override
  List<MemberRecord> get members => _members;
  @override
  LibrarianSettings get settings => _settings;

  @override
  bool get isLoading => _waiting.isNotEmpty;
  @override
  String? get loadError => _loadError;
  @override
  bool get supportsImageUpload => true;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);
  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _col(FirestoreCollections.settings)
          .doc(FirestoreCollections.librarySettingsDoc);

  // ---------------- Live data ----------------

  void _listen() {
    _watchQuery(_col(FirestoreCollections.books), 'books', (docs) {
      _books = [
        for (final d in docs) BookRecord.fromMap(d.id, d.data()),
      ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    });
    _watchQuery(_col(FirestoreCollections.seats), 'seats', (docs) {
      _seats = [for (final d in docs) SeatRecord.fromMap(d.id, d.data())]
        ..sort((a, b) {
          final room = a.readingRoom.compareTo(b.readingRoom);
          return room != 0 ? room : a.seatNumber.compareTo(b.seatNumber);
        });
    });
    _watchQuery(_col(FirestoreCollections.reservations), 'reservations', (
      docs,
    ) {
      _reservations = [
        for (final d in docs) ReservationRecord.fromMap(d.id, d.data()),
      ]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    });
    _watchQuery(_col(FirestoreCollections.borrowings), 'borrowings', (docs) {
      _borrowings = [
        for (final d in docs) BorrowingRecord.fromMap(d.id, d.data()),
      ]..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    });
    _watchQuery(
      _col(FirestoreCollections.users).where('role', isEqualTo: 'student'),
      'members',
      (docs) {
        _members = [
          for (final d in docs) MemberRecord.fromUserMap(d.id, d.data()),
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      },
    );
    _watchQuery(
      _col(FirestoreCollections.notifications)
          .where('audience', isEqualTo: 'librarian'),
      'notifications',
      (docs) {
        _notifications = [
          for (final d in docs) LibrarianNotification.fromMap(d.id, d.data()),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _announceNewNotifications();
      },
    );

    _waiting.add('settings');
    _subscriptions.add(
      _settingsDoc.snapshots().listen((snapshot) {
        _settings = LibrarianSettings.fromMap(snapshot.data() ?? const {});
        _received('settings');
      }, onError: (Object error) => _failed('settings', error)),
    );
  }

  void _watchQuery(
    Query<Map<String, dynamic>> query,
    String name,
    void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)
    onData,
  ) {
    _waiting.add(name);
    _subscriptions.add(
      query.snapshots().listen((snapshot) {
        onData(snapshot.docs);
        _received(name);
      }, onError: (Object error) => _failed(name, error)),
    );
  }

  void _received(String name) {
    _waiting.remove(name);
    notifyListeners();
  }

  void _failed(String name, Object error) {
    _waiting.remove(name);
    final reason = error is FirebaseException
        ? describeFirestoreError(error)
        : 'Unexpected error.';
    _loadError = 'Could not load $name from Firebase. $reason';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  // ---------------- Reservations ----------------

  @override
  Future<ActionResult> approveReservation(String id) async {
    final cached = reservationById(id);
    if (cached == null)
      return const ActionResult.failure('Reservation not found.');
    // Friendly reasons from the loaded data first (includes seat overlaps)...
    final blocker = approvalBlocker(cached);
    if (blocker != null) return ActionResult.failure(blocker);

    // ...then the transaction re-checks the latest copies / seat state.
    final result = await _run(() {
      return _db.runTransaction((tx) async {
        final resRef = _col(FirestoreCollections.reservations).doc(id);
        final reservation = await _readReservation(tx, resRef);
        if (!reservation.isPending) {
          throw ActionRefused(
            'This reservation is already ${reservation.status.label.toLowerCase()}.',
          );
        }

        if (reservation.type == ReservationType.book) {
          final bookRef = _col(FirestoreCollections.books)
              .doc(reservation.itemId);
          final bookSnap = await tx.get(bookRef);
          if (!bookSnap.exists) {
            throw const ActionRefused(
              'This book is no longer in the catalogue.',
            );
          }
          final book = BookRecord.fromMap(bookSnap.id, bookSnap.data()!);
          if (!book.isAvailable) {
            throw ActionRefused(
              'No copies of "${book.title}" are available right now. '
              'The reservation stays pending until a copy is returned.',
            );
          }
          tx.update(bookRef, {
            'availableCopies': book.availableCopies - 1,
            // Also stored for books saved in the earlier format (no counts).
            'totalCopies': book.totalCopies,
            'available':
                book.availableCopies - 1 > 0, // read by Student screens
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final seatRef = _col(FirestoreCollections.seats)
              .doc(reservation.itemId);
          final seatSnap = await tx.get(seatRef);
          if (!seatSnap.exists)
            throw const ActionRefused('This seat no longer exists.');
          final seat = SeatRecord.fromMap(seatSnap.id, seatSnap.data()!);
          final isToday = LibrarianRepository.isSameDay(
            reservation.date,
            DateTime.now(),
          );
          if (seat.status == SeatStatus.maintenance ||
              (isToday && seat.status == SeatStatus.occupied)) {
            throw ActionRefused(
              'Seat ${seat.seatNumber} is ${seat.status.label.toLowerCase()} '
              'and cannot be reserved right now. The reservation stays pending.',
            );
          }
          // The seat map shows today, so only today's booking reserves it now.
          if (isToday) {
            tx.update(seatRef, {
              'status': SeatStatus.reserved.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        tx.update(resRef, {
          'status': ReservationStatus.approved.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _notifyStudent(
          tx,
          recipientUid: reservation.studentUid,
          type: StudentNotificationType.reservationApproved,
          title: 'Reservation Approved',
          message: reservation.type == ReservationType.book
              ? '"${reservation.itemName}" is ready for you to collect from '
                    '${_day(reservation.date)}.'
              : 'Your booking for ${reservation.itemName} on ${_day(reservation.date)}, '
                    '${reservation.timeSlot ?? ''} is confirmed.',
          reservation: reservation,
        );
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.approved,
            'Reservation Approved',
            '${reservation.itemName} — ${reservation.studentName}',
            reservationId: id,
          ),
        );
      });
    });
    if (result.success) await _markReservationNotificationsRead(id);
    return result;
  }

  @override
  Future<ActionResult> rejectReservation(String id, String reason) async {
    final result = await _run(() {
      return _db.runTransaction((tx) async {
        final resRef = _col(FirestoreCollections.reservations).doc(id);
        final reservation = await _readReservation(tx, resRef);
        if (!reservation.isPending) {
          throw ActionRefused(
            'This reservation is already ${reservation.status.label.toLowerCase()}.',
          );
        }
        tx.update(resRef, {
          'status': ReservationStatus.rejected.name,
          'rejectionReason': reason.trim().isEmpty
              ? 'Rejected by librarian.'
              : reason.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Free the seat-hours this booking was holding.
        _deleteSeatSlots(tx, reservation);
        _notifyStudent(
          tx,
          recipientUid: reservation.studentUid,
          type: StudentNotificationType.reservationRejected,
          title: 'Reservation Rejected',
          message:
              'Your reservation for ${reservation.itemName} was rejected: '
              '${reason.trim().isEmpty ? 'Rejected by librarian.' : reason.trim()}',
          reservation: reservation,
        );
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.rejected,
            'Reservation Rejected',
            '${reservation.itemName} — ${reservation.studentName}',
            reservationId: id,
          ),
        );
      });
    });
    if (result.success) await _markReservationNotificationsRead(id);
    return result;
  }

  @override
  Future<ActionResult> markReservationCollected(String id) async {
    final cached = reservationById(id);
    if (cached == null)
      return const ActionResult.failure('Reservation not found.');
    final blocker = collectBlocker(cached);
    if (blocker != null) return ActionResult.failure(blocker);

    return _run(() {
      return _db.runTransaction((tx) async {
        final resRef = _col(FirestoreCollections.reservations).doc(id);
        final reservation = await _readReservation(tx, resRef);
        if (reservation.status != ReservationStatus.approved) {
          throw const ActionRefused(
            'Only approved reservations can be marked as collected.',
          );
        }
        final bookSnap = await tx.get(
          _col(FirestoreCollections.books).doc(reservation.itemId),
        );
        if (!bookSnap.exists) {
          throw const ActionRefused('This book is no longer in the catalogue.');
        }
        final book = BookRecord.fromMap(bookSnap.id, bookSnap.data()!);
        final now = DateTime.now();
        final loan = BorrowingRecord(
          id: '',
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
        );
        // The copy was set aside at approval and is now on loan, so the
        // book's available count does not change.
        tx.set(_col(FirestoreCollections.borrowings).doc(), {
          ...loan.toMap(),
          'memberUid': reservation.studentUid,
          'reservationId': id,
        });
        _notifyStudent(
          tx,
          recipientUid: reservation.studentUid,
          type: StudentNotificationType.bookCollected,
          title: 'Book Collected',
          message:
              '"${book.title}" is now on loan to you. '
              'Please return it by ${_day(loan.dueDate)}.',
          reservation: reservation,
        );
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.bookCollected,
            'Book Collected',
            '"${book.title}" is now on loan to ${reservation.studentName}.',
            reservationId: id,
          ),
        );
        tx.update(resRef, {
          'status': ReservationStatus.completed.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    });
  }

  // ---------------- Books ----------------

  /// A picked [coverImage] is uploaded to Cloudinary first; only its URL and
  /// public ID are saved. If the upload fails nothing is written.
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

    final ref = _col(FirestoreCollections.books)
        .doc(); // new id, nothing written yet
    return _run(() async {
      await _checkIsbnFree(isbn);
      String? coverPublicId;
      if (coverImage != null) {
        final asset = await _upload(coverImage, onUploadProgress);
        coverAsset = asset.secureUrl;
        coverPublicId = asset.publicId;
      }
      final book = BookRecord(
        id: ref.id,
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
        coverPublicId: coverPublicId,
        publisher: publisher.trim(),
        publishedYear: publishedYear,
        pages: pages,
      );
      final batch = _db.batch()
        ..set(ref, {
          ...book.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': librarianUid,
        })
        ..set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.bookAdded,
            'New Book Added',
            '"${book.title}" was added to the catalogue.',
          ),
        );
      await _confirmed(batch.commit());
      await _checkBookSaved(ref, coverAsset);
    });
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
    final error = bookInputError(
      isbn: isbn,
      totalCopies: totalCopies,
      exceptBookId: id,
    );
    if (error != null) return ActionResult.failure(error);

    return _run(() async {
      await _checkIsbnFree(isbn, exceptBookId: id);
      String? newPublicId;
      if (coverImage != null) {
        final asset = await _upload(coverImage, onUploadProgress);
        coverAsset = asset.secureUrl;
        newPublicId = asset.publicId;
      }
      await _db.runTransaction((tx) async {
        final ref = _col(FirestoreCollections.books).doc(id);
        final snap = await tx.get(ref);
        if (!snap.exists) throw const ActionRefused('Book not found.');
        final book = BookRecord.fromMap(id, snap.data()!);
        // Re-checked here because a copy may have been reserved meanwhile.
        if (totalCopies < book.copiesOut) {
          throw ActionRefused(
            '${book.copiesOut} copies are currently reserved or borrowed, '
            'so total copies cannot be less than ${book.copiesOut}.',
          );
        }
        final updated = book.copyWith(
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
          coverPublicId: newPublicId,
          clearCover: coverAsset == null,
          publisher: publisher.trim(),
          publishedYear: publishedYear,
          pages: pages,
        );
        tx.update(ref, updated.toMap());
      });
    });
  }

  @override
  Future<ActionResult> deleteBook(String id) async {
    final book = bookById(id);
    if (book == null) return const ActionResult.failure('Book not found.');
    final blocker = bookDeleteBlocker(id);
    if (blocker != null) return ActionResult.failure(blocker);

    // Cloudinary covers are not deleted from the app (that needs a server
    // secret); unreferenced ones can be removed in the Media Library.
    return _run(() async {
      // Double-check on the server in case the lists are a moment behind.
      final reserved = await _col(FirestoreCollections.reservations)
          .where('itemId', isEqualTo: id)
          .get();
      final hasActive = reserved.docs
          .map((d) => ReservationRecord.fromMap(d.id, d.data()))
          .any((r) => r.type == ReservationType.book && r.isActive);
      if (hasActive) {
        throw const ActionRefused(
          'This book has active reservations, so it cannot be deleted.',
        );
      }
      final loans = await _col(FirestoreCollections.borrowings)
          .where('bookId', isEqualTo: id)
          .get();
      if (loans.docs.any((d) => d.data()['returnedAt'] == null)) {
        throw const ActionRefused(
          'Copies of this book are still on loan, so it cannot be deleted.',
        );
      }
      await _col(FirestoreCollections.books).doc(id).delete();
    });
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
    ImageUpload? image,
    void Function(double progress)? onUploadProgress,
  }) async {
    final error = seatInputError(
      seatNumber: seatNumber,
      readingRoom: readingRoom,
    );
    if (error != null) return ActionResult.failure(error);

    final ref = _col(FirestoreCollections.seats).doc();
    CloudMediaAsset? uploadedAsset;
    final result = await _run(() async {
      await _checkSeatFree(seatNumber, readingRoom);
      if (image != null) {
        uploadedAsset = await _upload(image, onUploadProgress);
      }
      final seat = SeatRecord(
        id: ref.id,
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
        imageUrl: uploadedAsset?.secureUrl,
        imagePublicId: uploadedAsset?.publicId,
      );
      final batch = _db.batch()
        ..set(ref, {
          ...seat.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': librarianUid,
        })
        ..set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.seatUpdate,
            'New Seat Added',
            'Seat ${seat.seatNumber} was added to ${seat.readingRoom}.',
          ),
        );
      await batch.commit();
    });
    return result;
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
    ImageUpload? newImage,
    bool removeImage = false,
    void Function(double progress)? onUploadProgress,
  }) async {
    final seat = seatById(id);
    if (seat == null) return const ActionResult.failure('Seat not found.');
    final error = seatInputError(
      seatNumber: seatNumber,
      readingRoom: readingRoom,
      exceptSeatId: id,
    );
    if (error != null) return ActionResult.failure(error);

    CloudMediaAsset? uploadedAsset;
    final result = await _run(() async {
      await _checkSeatFree(seatNumber, readingRoom, exceptSeatId: id);
      if (newImage != null) {
        uploadedAsset = await _upload(newImage, onUploadProgress);
      }
      final updated = seat.copyWith(
        seatNumber: seatNumber.trim().toUpperCase(),
        zone: zone.trim(),
        readingRoom: readingRoom.trim(),
        type: type,
        hasPowerOutlet: hasPowerOutlet,
        hasReadingLamp: hasReadingLamp,
        isAccessible: isAccessible,
        isNearWindow: isNearWindow,
        note: note.trim(),
        imageUrl: uploadedAsset?.secureUrl,
        imagePublicId: uploadedAsset?.publicId,
        clearImage: removeImage && newImage == null,
        clearLegacyImagePath: newImage != null || removeImage,
      );
      final map = updated.toMap()
        ..remove('status'); // status has its own action
      await _col(FirestoreCollections.seats).doc(id).update(map);
    });
    return result;
  }

  @override
  Future<ActionResult> deleteSeat(String id) async {
    final seat = seatById(id);
    if (seat == null) return const ActionResult.failure('Seat not found.');
    final blocker = seatDeleteBlocker(id);
    if (blocker != null) return ActionResult.failure(blocker);

    final result = await _run(() async {
      final bookings = await _col(FirestoreCollections.reservations)
          .where('itemId', isEqualTo: id)
          .get();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final hasUpcoming = bookings.docs
          .map((d) => ReservationRecord.fromMap(d.id, d.data()))
          .any(
            (r) =>
                r.type == ReservationType.seat &&
                r.isActive &&
                !r.date.isBefore(today),
          );
      if (hasUpcoming) {
        throw const ActionRefused(
          'This seat has upcoming bookings, so it cannot be deleted.',
        );
      }
      await _col(FirestoreCollections.seats).doc(id).delete();
    });
    return result;
  }

  @override
  Future<ActionResult> updateSeatStatus(String seatId, SeatStatus status) {
    return _run(() {
      return _col(FirestoreCollections.seats).doc(seatId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------- Borrowings ----------------

  @override
  Future<ActionResult> markBorrowingReturned(String id) {
    return _run(() {
      return _db.runTransaction((tx) async {
        final loanRef = _col(FirestoreCollections.borrowings).doc(id);
        final loanSnap = await tx.get(loanRef);
        if (!loanSnap.exists) throw const ActionRefused('Loan not found.');
        final loan = BorrowingRecord.fromMap(id, loanSnap.data()!);
        if (loan.isReturned) {
          throw const ActionRefused('This book has already been returned.');
        }
        final bookRef = _col(FirestoreCollections.books).doc(loan.bookId);
        final bookSnap = await tx.get(bookRef);

        tx.update(loanRef, {'returnedAt': FieldValue.serverTimestamp()});
        _notifyStudent(
          tx,
          recipientUid: loanSnap.data()!['memberUid'] as String? ?? '',
          type: StudentNotificationType.bookReturned,
          title: 'Book Returned',
          message: 'Thank you for returning "${loan.bookTitle}".',
          itemId: loan.bookId,
        );
        if (bookSnap.exists) {
          final book = BookRecord.fromMap(bookSnap.id, bookSnap.data()!);
          if (book.availableCopies < book.totalCopies) {
            tx.update(bookRef, {
              'availableCopies': book.availableCopies + 1,
              'totalCopies': book.totalCopies,
              'available': true, // read by Student screens
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.bookReturned,
            'Book Returned',
            '${loan.memberName} returned "${loan.bookTitle}".',
          ),
        );
      });
    });
  }

  @override
  Future<ActionResult> renewBorrowing(String id) async {
    final cached = borrowingById(id);
    if (cached == null) return const ActionResult.failure('Loan not found.');
    final blocker = renewBlocker(cached);
    if (blocker != null) return ActionResult.failure(blocker);

    return _run(() {
      return _db.runTransaction((tx) async {
        final ref = _col(FirestoreCollections.borrowings).doc(id);
        final snap = await tx.get(ref);
        if (!snap.exists) throw const ActionRefused('Loan not found.');
        final loan = BorrowingRecord.fromMap(id, snap.data()!);
        if (loan.isReturned || loan.renewals >= LibrarianSettings.maxRenewals) {
          throw const ActionRefused('This loan can no longer be renewed.');
        }
        final newDue = loan.dueDate.add(
          Duration(days: _settings.loanPeriodDays),
        );
        tx.update(ref, {
          'dueDate': Timestamp.fromDate(newDue),
          'renewals': loan.renewals + 1,
        });
        _notifyStudent(
          tx,
          recipientUid: snap.data()!['memberUid'] as String? ?? '',
          type: StudentNotificationType.loanRenewed,
          title: 'Loan Renewed',
          message: '"${loan.bookTitle}" is now due on ${_day(newDue)}.',
          itemId: loan.bookId,
        );
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          _notification(
            LibrarianNotificationType.loanRenewed,
            'Loan Renewed',
            '"${loan.bookTitle}" for ${loan.memberName} is now due on ${_day(newDue)}.',
          ),
        );
      });
    });
  }

  // ---------------- Members ----------------

  /// Only the `accountStatus` field is written; the role is never changed.
  @override
  Future<ActionResult> updateMemberStatus(
    String id,
    MemberStatus status,
  ) async {
    final member = memberById(id);
    if (member == null || member.uid.isEmpty) {
      return const ActionResult.failure('Member not found.');
    }
    if (member.status == status) {
      return ActionResult.failure(
        'This account is already ${status.label.toLowerCase()}.',
      );
    }
    return _run(() {
      return _col(FirestoreCollections.users).doc(member.uid).update({
        'accountStatus': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------- Settings ----------------

  @override
  Future<ActionResult> updateSettings(LibrarianSettings settings) async {
    final error = settingsError(settings);
    if (error != null) return ActionResult.failure(error);
    return _run(
      () => _settingsDoc.set(settings.toMap(), SetOptions(merge: true)),
    );
  }

  // ---------------- Notifications ----------------

  @override
  Future<void> markNotificationRead(String id) async {
    await _run(() {
      return _col(FirestoreCollections.notifications)
          .doc(id)
          .update({'isRead': true});
    });
  }

  // ---------------- Appearance ----------------

  /// The theme choice is saved per librarian in their own profile,
  /// `users/{uid}.librarianDarkMode`, so it is kept after a restart and on
  /// other devices. (Users may edit their own profile, see firestore.rules.)
  DocumentReference<Map<String, dynamic>>? get _profileDoc =>
      librarianUid.isEmpty
      ? null
      : _col(FirestoreCollections.users).doc(librarianUid);

  bool _disposed = false;
  bool _darkModeChanged = false;

  // ---------------- New notifications (toast) ----------------

  /// Ids of the notifications already seen; null until the first snapshot.
  Set<String>? _seenNotificationIds;

  /// The first snapshot is what already exists, so it only fills
  /// [_seenNotificationIds]. Later snapshots announce the ids not seen
  /// before, i.e. notifications created while the librarian is signed in.
  void _announceNewNotifications() {
    final seen = _seenNotificationIds;
    if (seen == null) {
      _seenNotificationIds = {for (final n in _notifications) n.id};
      return;
    }
    // Oldest first, so the toasts appear in the order they were created.
    for (final n in _notifications.reversed) {
      if (seen.add(n.id)) announceNotification(n);
    }
  }

  Future<void> _loadDarkMode() async {
    final doc = _profileDoc;
    if (doc == null) return;
    try {
      final snapshot = await doc.get();
      // Signed out meanwhile, or the librarian already switched the mode
      // (their choice wins over the value read before it was saved).
      if (_disposed || _darkModeChanged) return;
      applyDarkMode(snapshot.data()?['librarianDarkMode'] == true);
    } catch (_) {
      // Not loaded (e.g. offline): keep the light theme.
    }
  }

  @override
  Future<ActionResult> setDarkMode(bool on) async {
    _darkModeChanged = true;
    final previous = darkMode;
    applyDarkMode(on); // switch immediately
    final doc = _profileDoc;
    if (doc == null) return const ActionResult.success();
    final result = await _run(() => doc.update({'librarianDarkMode': on}));
    if (!result.success) applyDarkMode(previous);
    return result;
  }

  @override
  Future<void> markAllNotificationsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    await _run(() {
      final batch = _db.batch();
      for (final n in unread) {
        batch.update(_col(FirestoreCollections.notifications).doc(n.id), {
          'isRead': true,
        });
      }
      return batch.commit();
    });
  }

  // ---------------- Helpers ----------------

  /// Runs a write and turns errors into an ActionResult, so a failed save is
  /// never reported as a success.
  Future<ActionResult> _run(Future<void> Function() action) async {
    try {
      await action();
      return const ActionResult.success();
    } on ActionRefused catch (e) {
      return ActionResult.failure(e.message);
    } on ImageStorageException catch (e) {
      return ActionResult.failure(e.message);
    } on FirebaseException catch (e) {
      return ActionResult.failure(describeFirestoreError(e));
    } catch (_) {
      return const ActionResult.failure(
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<ReservationRecord> _readReservation(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snap = await tx.get(ref);
    if (!snap.exists) throw const ActionRefused('Reservation not found.');
    return ReservationRecord.fromMap(snap.id, snap.data()!);
  }

  void _deleteSeatSlots(Transaction tx, ReservationRecord reservation) {
    final start = reservation.startHour;
    final end = reservation.endHour;
    if (reservation.type != ReservationType.seat ||
        start == null ||
        end == null)
      return;
    for (final slotId in SeatSlots.ids(
      reservation.itemId,
      reservation.date,
      start,
      end,
    )) {
      tx.delete(_col(FirestoreCollections.seatSlots).doc(slotId));
    }
  }

  Future<void> _checkIsbnFree(String isbn, {String? exceptBookId}) async {
    final same = await _col(FirestoreCollections.books)
        .where('isbnKey', isEqualTo: BookRecord.isbnKeyOf(isbn))
        .get();
    if (same.docs.any((d) => d.id != exceptBookId)) {
      throw ActionRefused(
        exceptBookId == null
            ? 'A book with this ISBN already exists.'
            : 'Another book already uses this ISBN.',
      );
    }
  }

  Future<void> _checkSeatFree(
    String seatNumber,
    String readingRoom, {
    String? exceptSeatId,
  }) async {
    final same = await _col(FirestoreCollections.seats)
        .where(
          'seatKey',
          isEqualTo: SeatRecord.seatKeyOf(seatNumber, readingRoom),
        )
        .get();
    if (same.docs.any((d) => d.id != exceptSeatId)) {
      throw ActionRefused(
        'Seat ${seatNumber.trim().toUpperCase()} already exists in ${readingRoom.trim()}.',
      );
    }
  }

  /// Uploads with a time limit, so the form never waits forever.
  Future<CloudMediaAsset> _upload(
    ImageUpload image,
    void Function(double progress)? onProgress,
  ) {
    return _images
        .upload(image, onProgress: onProgress)
        .timeout(
          uploadTimeout,
          onTimeout: () => throw ImageStorageException(
            'The image upload did not finish within ${uploadTimeout.inSeconds} '
            'seconds. Check your internet connection and try again.',
          ),
        );
  }

  /// Waits for Firestore to confirm a write, but not forever. If it times out
  /// the write may still be queued, so the message says to check first.
  Future<void> _confirmed(Future<void> write) async {
    try {
      await write.timeout(writeTimeout);
    } on TimeoutException {
      throw ActionRefused(
        'Firebase did not confirm the save within ${writeTimeout.inSeconds} '
        'seconds (you may be offline). It is not confirmed as saved; if the '
        'connection returns it may still appear in Book Management, so check '
        'there before adding it again.',
      );
    }
  }

  /// Reads the new book back from the server: a success message is only
  /// shown when the document really exists with the chosen cover.
  Future<void> _checkBookSaved(
    DocumentReference<Map<String, dynamic>> ref,
    String? coverAsset,
  ) async {
    final snapshot = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(writeTimeout);
    final data = snapshot.data();
    if (data == null) {
      throw const ActionRefused(
        'Firebase did not return the saved book. Check Book Management before trying again.',
      );
    }
    if (data['coverAsset'] != (coverAsset ?? '')) {
      throw const ActionRefused(
        'The book was saved but its cover is missing. Edit the book to choose the cover again.',
      );
    }
  }

  /// Once a request is decided, its "new request" alerts are no longer unread.
  Future<void> _markReservationNotificationsRead(String reservationId) async {
    final unread = _notifications
        .where((n) => n.reservationId == reservationId && !n.isRead)
        .toList();
    if (unread.isEmpty) return;
    await _run(() {
      final batch = _db.batch();
      for (final n in unread) {
        batch.update(_col(FirestoreCollections.notifications).doc(n.id), {
          'isRead': true,
        });
      }
      return batch.commit();
    });
  }

  /// Tells the student about a change to their reservation or loan, in the
  /// same transaction as the change (so it is only sent if the change is
  /// saved). Skipped for records without a student uid (e.g. old data).
  void _notifyStudent(
    Transaction tx, {
    required String recipientUid,
    required StudentNotificationType type,
    required String title,
    required String message,
    ReservationRecord? reservation,
    String? itemId,
  }) {
    if (recipientUid.isEmpty) return;
    tx.set(
      _col(FirestoreCollections.notifications).doc(),
      StudentNotification.create(
        recipientUid: recipientUid,
        type: type,
        title: title,
        message: message,
        reservationId: reservation?.id,
        itemId: reservation?.itemId ?? itemId,
      ),
    );
  }

  /// e.g. "7 Oct 2026"
  static String _day(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// A librarian action, saved as already read so it does not raise the badge.
  Map<String, dynamic> _notification(
    LibrarianNotificationType type,
    String title,
    String message, {
    String? reservationId,
  }) {
    return LibrarianNotification(
      id: '',
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      reservationId: reservationId,
      isRead: true,
    ).toMap();
  }
}
