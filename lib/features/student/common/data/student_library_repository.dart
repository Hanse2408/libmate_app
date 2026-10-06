import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/services/firestore_errors.dart';
import '../../../../models/action_result.dart';
import '../../../../models/book.dart';
import '../../../../models/notification.dart';
import '../../../../core/services/ebook_downloader.dart';
import '../../../../core/services/ebook_service.dart';
import '../../../../repositories/ebook_repository.dart';
import '../../ebooks/providers/student_ebook_provider.dart';
import '../../../../models/reservation.dart';
import '../../../../models/seat.dart';
import '../../../librarian/models/librarian_notification.dart';
import '../../../librarian/models/librarian_settings.dart';

/// Who is using the Student screens (from the signed-in Firebase user and
/// their `users/{uid}` profile).
class StudentIdentity {
  const StudentIdentity({
    required this.uid,
    required this.studentId,
    required this.name,
    required this.email,
  });

  /// Firebase Auth uid, saved on reservations for the security rules.
  final String uid;

  /// University student ID shown to librarians (falls back to the uid).
  final String studentId;

  final String name;

  final String email;
}

/// Library data for the Student screens, read from the same Firestore
/// collections the Librarian writes to, so a book or seat a librarian adds
/// appears here straight away (snapshot listeners, no rebuild needed).
///
/// A student can read the catalogue, the seats and the settings, but only
/// their own reservations (see firestore.rules). Creating a reservation runs
/// in a transaction that re-checks the book / seat, so two students cannot
/// take the same seat-hour (see SeatSlots).
class StudentLibraryRepository extends ChangeNotifier {
  StudentLibraryRepository({
    required FirebaseFirestore firestore,
    required this.student,
    this.onSignOut,
    this._createEbooks,
  }) : _db = firestore {
    _listen();
  }

  final FirebaseFirestore _db;
  final StudentIdentity student;

  /// The app's existing sign-out (AuthProvider.signOut), set by the router.
  final Future<void> Function()? onSignOut;

  final StudentEbookProvider Function()? _createEbooks;
  StudentEbookProvider? _ebooks;

  /// E-books (published, from the shared `ebooks` collection) and PDF
  /// downloads. Created the first time an e-book screen is opened.
  StudentEbookProvider get ebooks =>
      _ebooks ??= (_createEbooks ?? _defaultEbooks)();

  StudentEbookProvider _defaultEbooks() {
    return StudentEbookProvider(
      EbookRepository(
        service: EbookService(
          firestore: _db,
          files: CloudinaryEbookFileStorage(),
        ),
        downloader: createEbookDownloader(),
      ),
    );
  }

  bool _disposed = false;
  List<StudentNotification> _notifications = const [];

  List<BookRecord> _books = const [];
  List<SeatRecord> _seats = const [];
  List<ReservationRecord> _myReservations = const [];
  LibrarianSettings _settings = const LibrarianSettings();
  final Set<String> _waiting = {};
  String? _loadError;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<BookRecord> get books => _books;

  List<SeatRecord> get seats => _seats;

  /// This student's reservations, newest first.
  List<ReservationRecord> get myReservations => _myReservations;

  LibrarianSettings get settings => _settings;

  /// This student's notifications, newest first.
  List<StudentNotification> get notifications => _notifications;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  bool get isLoading => _waiting.isNotEmpty;

  String? get loadError => _loadError;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);

  BookRecord? bookById(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  SeatRecord? seatById(String id) {
    for (final seat in _seats) {
      if (seat.id == id) return seat;
    }
    return null;
  }

  /// The student's pending or approved reservation of [bookId], if any.
  ReservationRecord? activeReservationForBook(String bookId) {
    for (final r in _myReservations) {
      if (r.type == ReservationType.book && r.itemId == bookId && r.isActive) {
        return r;
      }
    }
    return null;
  }

  // ---------------- Live data ----------------

  void _listen() {
    _watch(_col(FirestoreCollections.books), 'books', (docs) {
      _books = [
        for (final d in docs) BookRecord.fromMap(d.id, d.data()),
      ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    });

    _watch(_col(FirestoreCollections.seats), 'seats', (docs) {
      _seats = [for (final d in docs) SeatRecord.fromMap(d.id, d.data())]
        ..sort((a, b) {
          final room = a.readingRoom.compareTo(b.readingRoom);
          return room != 0 ? room : a.seatNumber.compareTo(b.seatNumber);
        });
    });

    _watch(
      _col(FirestoreCollections.reservations)
          .where('studentUid', isEqualTo: student.uid),
      'reservations',
      (docs) {
        _myReservations = [
          for (final d in docs) ReservationRecord.fromMap(d.id, d.data()),
        ]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      },
    );

    // Only this student's notifications (the rules refuse anyone else's).
    _watch(
      _col(FirestoreCollections.notifications)
          .where('recipientUid', isEqualTo: student.uid),
      'notifications',
      (docs) {
        _notifications = [
          for (final d in docs) StudentNotification.fromMap(d.id, d.data()),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    );

    _waiting.add('settings');
    _subscriptions.add(
      _col(FirestoreCollections.settings)
          .doc(FirestoreCollections.librarySettingsDoc)
          .snapshots()
          .listen((snapshot) {
            _settings = LibrarianSettings.fromMap(snapshot.data() ?? const {});
            _received('settings');
          }, onError: (Object error) => _failed('settings', error)),
    );
  }

  void _watch(
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
    if (_disposed) return;
    _waiting.remove(name);
    notifyListeners();
  }

  void _failed(String name, Object error) {
    // After sign-out the listeners may report "permission denied"; ignore.
    if (_disposed) return;
    _waiting.remove(name);

    final reason = error is FirebaseException
        ? describeFirestoreError(error)
        : '';

    _loadError = 'Could not load $name. $reason'.trim();

    notifyListeners();
  }

  /// Seat-hours already booked on [day] (by anyone), as slot ids. Students
  /// see only which seat and hour is taken, not who booked it.
  Stream<Set<String>> bookedSlotIds(DateTime day) {
    final date = Timestamp.fromDate(DateTime(day.year, day.month, day.day));

    return _col(FirestoreCollections.seatSlots)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) => {for (final d in snapshot.docs) d.id});
  }

  void _stopListening() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopListening();
    _ebooks?.dispose();
    super.dispose();
  }

  /// Logs the student out with the app's existing AuthProvider. Listeners
  /// stop first, so no "permission denied" errors appear while signing out.
  /// The router then sends the user to the Login screen.
  Future<void> signOut() async {
    _stopListening();
    await onSignOut?.call();
  }

  /// Marks one of this student's notifications as read (already read: no-op).
  Future<ActionResult> markNotificationRead(String id) async {
    final notification = _notifications.where((n) => n.id == id).firstOrNull;
    if (notification == null)
      return const ActionResult.failure('Notification not found.');
    if (notification.isRead) return const ActionResult.success();
    return _run(() async {
      await _col(FirestoreCollections.notifications)
          .doc(id)
          .update({'isRead': true});
      return null;
    });
  }

  /// Marks all of this student's unread notifications as read.
  Future<ActionResult> markAllNotificationsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return const ActionResult.success();
    return _run(() async {
      final batch = _db.batch();
      for (final n in unread) {
        batch.update(_col(FirestoreCollections.notifications).doc(n.id), {
          'isRead': true,
        });
      }
      await batch.commit();
      return null;
    });
  }

  // ---------------- Rules ----------------

  /// Why this student cannot reserve [book] now, or null if they can.
  String? bookReservationBlocker(BookRecord book) {
    if (activeReservationForBook(book.id) != null) {
      return 'You already have an active reservation for this book.';
    }

    if (!book.isAvailable) {
      return 'No copies are available right now.';
    }

    return null;
  }

  /// Why [seat] cannot be booked from [startHour] to [endHour] on [date],
  /// or null. [bookedSlots] are the slot ids already taken that day.
  /// When modifying a booking, [ignoreReservationId] is that booking, so it
  /// does not clash with the student's own seat bookings.
  String? seatBookingBlocker(
    SeatRecord seat,
    DateTime date,
    int startHour,
    int endHour, {
    Set<String> bookedSlots = const {},
    String? ignoreReservationId,
  }) {
    final s = _settings;

    if (endHour <= startHour) {
      return 'Choose an end time after the start time.';
    }

    if (endHour - startHour > s.seatBookingHours) {
      return 'A seat can be booked for at most ${s.seatBookingHours} hours.';
    }

    if (startHour < s.openingHour || endHour > s.closingHour) {
      return 'The library is open ${_hh(s.openingHour)} – ${_hh(s.closingHour)}.';
    }

    final now = DateTime.now();

    final start = DateTime(date.year, date.month, date.day, startHour);

    if (start.isBefore(DateTime(now.year, now.month, now.day, now.hour))) {
      return 'This time has already passed.';
    }

    if (seat.status == SeatStatus.maintenance) {
      return 'Seat ${seat.seatNumber} is under maintenance.';
    }

    if (_isToday(date) && seat.status == SeatStatus.occupied) {
      return 'Seat ${seat.seatNumber} is occupied right now.';
    }

    final wanted = SeatSlots.ids(seat.id, date, startHour, endHour);

    if (wanted.any(bookedSlots.contains)) {
      return 'Seat ${seat.seatNumber} is already booked at this time.';
    }
    if (hasSeatBookingAt(
      date,
      startHour,
      endHour,
      ignoreReservationId: ignoreReservationId,
    )) {
      return 'You already have a seat booked at this time.';
    }
    return null;
  }

  /// A student can only sit in one seat at a time: true if they already have
  /// an active seat booking overlapping [startHour]–[endHour] on [date].
  bool hasSeatBookingAt(
    DateTime date,
    int startHour,
    int endHour, {
    String? ignoreReservationId,
  }) {
    return _myReservations.any(
      (r) =>
          r.id != ignoreReservationId &&
          r.type == ReservationType.seat &&
          r.isActive &&
          _sameDay(r.date, date) &&
          (r.startHour ?? 0) < endHour &&
          startHour < (r.endHour ?? 0),
    );
  }

  // ---------------- Actions ----------------

  /// Sends a book reservation request (status pending until a librarian
  /// approves it, which sets a copy aside).
  Future<ActionResult> reserveBook({
    required BookRecord book,
    required DateTime pickupDate,
    required int loanPeriodDays,
    required String pickupLocation,
  }) async {
    final blocker = bookReservationBlocker(book);

    if (blocker != null) {
      return ActionResult.failure(blocker);
    }

    return _run(() async {
      await _checkNoActiveBookReservation(book.id);

      String? createdReservationId;

      await _db.runTransaction((tx) async {
        await _checkAccountActive(tx);

        final bookSnap = await tx.get(
          _col(FirestoreCollections.books).doc(book.id),
        );

        if (!bookSnap.exists) {
          throw const ActionRefused('This book is no longer in the catalogue.');
        }

        final latest = BookRecord.fromMap(book.id, bookSnap.data()!);

        if (!latest.isAvailable) {
          throw const ActionRefused('No copies are available right now.');
        }

        final ref = _col(FirestoreCollections.reservations).doc();

        // Store the ID of the reservation just created.
        createdReservationId = ref.id;

        tx.set(
          ref,
          ReservationRecord(
            id: ref.id,
            type: ReservationType.book,
            status: ReservationStatus.pending,
            studentUid: student.uid,
            studentId: student.studentId,
            studentName: student.name,
            studentEmail: student.email,
            itemId: latest.id,
            itemName: latest.title,
            requestedAt: DateTime.now(),
            date: pickupDate,
            pickupLocation: pickupLocation,
            loanPeriodDays: loanPeriodDays,
          ).toMap(),
        );

        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          _newRequest('${student.name} requested "${latest.title}".', ref.id),
        );
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          StudentNotification.create(
            recipientUid: student.uid,
            type: StudentNotificationType.reservationRequested,
            title: 'Reservation Requested',
            message:
                'Your request for "${latest.title}" was sent. '
                'You will be notified when a librarian approves it.',
            reservationId: ref.id,
            itemId: latest.id,
          ),
        );
      });

      // Return the ID of the reservation that was just created.
      return createdReservationId;
    });
  }

  /// Updates the student's own active book reservation.
  Future<ActionResult> updateBookReservation({
    required String reservationId,
    required DateTime pickupDate,
    required String pickupLocation,
    required int loanPeriodDays,
    required String notes,
  }) {
    return _run(() async {
      await _db.runTransaction((tx) async {
        final ref = _col(FirestoreCollections.reservations).doc(reservationId);

        final snap = await tx.get(ref);

        if (!snap.exists) {
          throw const ActionRefused('Reservation not found.');
        }

        final reservation = ReservationRecord.fromMap(
          reservationId,
          snap.data()!,
        );

        if (reservation.studentUid != student.uid) {
          throw const ActionRefused('This is not your reservation.');
        }

        if (reservation.type != ReservationType.book) {
          throw const ActionRefused(
            'Only book reservations can be modified here.',
          );
        }

        if (!reservation.isActive) {
          throw const ActionRefused('This reservation is no longer active.');
        }

        tx.update(ref, {
          'date': Timestamp.fromDate(pickupDate),
          'pickupLocation': pickupLocation,
          'loanPeriodDays': loanPeriodDays,
          'notes': notes.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return null;
    });
  }

  /// Books [seat] for [startHour]–[endHour] on [date]. Seat bookings need no
  /// librarian approval: the reservation is confirmed (approved) at once and
  /// the seat-hours are claimed in the same transaction, so an overlapping
  /// booking by another student is refused. The result carries the new
  /// reservation's ID.
  Future<ActionResult> bookSeat({
    required SeatRecord seat,
    required DateTime date,
    required int startHour,
    required int endHour,
  }) async {
    final blocker = seatBookingBlocker(seat, date, startHour, endHour);

    if (blocker != null) {
      return ActionResult.failure(blocker);
    }

    final day = DateTime(date.year, date.month, date.day);

    final slotLabel = ReservationRecord.slotLabel(startHour, endHour);

    return _run(() async {
      await _checkNoSeatClash(date, startHour, endHour);

      String? createdReservationId;
      await _db.runTransaction((tx) async {
        await _checkAccountActive(tx);

        final seatSnap = await tx.get(
          _col(FirestoreCollections.seats).doc(seat.id),
        );

        if (!seatSnap.exists) {
          throw const ActionRefused('This seat no longer exists.');
        }

        final latest = SeatRecord.fromMap(seat.id, seatSnap.data()!);

        if (latest.status == SeatStatus.maintenance ||
            (_isToday(day) && latest.status == SeatStatus.occupied)) {
          throw ActionRefused(
            'Seat ${latest.seatNumber} is '
            '${latest.status.label.toLowerCase()}.',
          );
        }

        final slotRefs = [
          for (final id in SeatSlots.ids(seat.id, day, startHour, endHour))
            _col(FirestoreCollections.seatSlots).doc(id),
        ];

        for (final slotRef in slotRefs) {
          if ((await tx.get(slotRef)).exists) {
            throw ActionRefused(
              'Sorry, seat ${latest.seatNumber} was just booked by someone else '
              'for this time. Please choose another seat or time.',
            );
          }
        }

        final ref = _col(FirestoreCollections.reservations).doc();

        createdReservationId = ref.id;

        tx.set(
          ref,
          ReservationRecord(
            id: ref.id,
            type: ReservationType.seat,
            status: ReservationStatus.approved,
            studentUid: student.uid,
            studentId: student.studentId,
            studentName: student.name,
            studentEmail: student.email,
            itemId: latest.id,
            itemName: 'Seat ${latest.seatNumber}',
            requestedAt: DateTime.now(),
            date: day,
            timeSlot: slotLabel,
          ).toMap(),
        );

        for (var i = 0; i < slotRefs.length; i++) {
          tx.set(slotRefs[i], {
            'seatId': latest.id,
            'date': Timestamp.fromDate(day),
            'hour': startHour + i,
            'reservationId': ref.id,
            'studentUid': student.uid,
          });
        }
      });

      return createdReservationId;
    });
  }

  /// Moves the student's confirmed seat booking [reservationId] to [seat] and
  /// the new date and hours. The SAME reservation is updated (same ID, still
  /// approved): no new reservation is created.
  ///
  /// One transaction re-checks the booking, claims the new seatSlots and
  /// releases the old ones that are no longer needed, so no other student
  /// can slip in between. Slots the booking already holds are kept as they
  /// are and never count as a clash.
  Future<ActionResult> modifySeatReservation({
    required String reservationId,
    required SeatRecord seat,
    required DateTime date,
    required int startHour,
    required int endHour,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final blocker = seatBookingBlocker(
      seat,
      day,
      startHour,
      endHour,
      ignoreReservationId: reservationId,
    );
    if (blocker != null) return ActionResult.failure(blocker);

    return _run(() async {
      await _checkNoSeatClash(
        day,
        startHour,
        endHour,
        ignoreReservationId: reservationId,
      );

      await _db.runTransaction((tx) async {
        await _checkAccountActive(tx);

        final ref = _col(FirestoreCollections.reservations).doc(reservationId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw const ActionRefused('Reservation not found.');
        }
        final current = ReservationRecord.fromMap(reservationId, snap.data()!);

        if (current.studentUid != student.uid) {
          throw const ActionRefused('This is not your reservation.');
        }
        if (current.type != ReservationType.seat) {
          throw const ActionRefused(
            'Only seat reservations can be modified here.',
          );
        }
        if (current.status != ReservationStatus.approved) {
          throw ActionRefused(
            'This reservation is ${current.status.label.toLowerCase()} and cannot be modified.',
          );
        }
        if (current.hasEnded) {
          throw const ActionRefused('This seat booking has already ended.');
        }

        final seatSnap = await tx.get(
          _col(FirestoreCollections.seats).doc(seat.id),
        );
        if (!seatSnap.exists) {
          throw const ActionRefused('This seat no longer exists.');
        }
        final latest = SeatRecord.fromMap(seat.id, seatSnap.data()!);
        if (latest.status == SeatStatus.maintenance ||
            (_isToday(day) && latest.status == SeatStatus.occupied)) {
          throw ActionRefused(
            'Seat ${latest.seatNumber} is ${latest.status.label.toLowerCase()}.',
          );
        }

        final oldIds = {
          if (current.startHour != null && current.endHour != null)
            ...SeatSlots.ids(
              current.itemId,
              current.date,
              current.startHour!,
              current.endHour!,
            ),
        };
        final newIds = SeatSlots.ids(latest.id, day, startHour, endHour);
        final toClaim = newIds.where((id) => !oldIds.contains(id)).toList();
        final toRelease = oldIds.where((id) => !newIds.contains(id)).toList();

        if (toClaim.isEmpty &&
            toRelease.isEmpty &&
            latest.id == current.itemId) {
          return; // nothing changed
        }

        // All reads come before any write.
        final claimRefs = [
          for (final id in toClaim)
            _col(FirestoreCollections.seatSlots).doc(id),
        ];
        for (final slotRef in claimRefs) {
          if ((await tx.get(slotRef)).exists) {
            throw ActionRefused(
              'Sorry, seat ${latest.seatNumber} was just booked by someone else '
              'for this time. Please choose another seat or time.',
            );
          }
        }

        tx.update(ref, {
          'itemId': latest.id,
          'itemName': 'Seat ${latest.seatNumber}',
          'date': Timestamp.fromDate(day),
          'timeSlot': ReservationRecord.slotLabel(startHour, endHour),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        for (final slotRef in claimRefs) {
          final hour = int.parse(slotRef.id.substring(slotRef.id.length - 2));
          tx.set(slotRef, {
            'seatId': latest.id,
            'date': Timestamp.fromDate(day),
            'hour': hour,
            'reservationId': reservationId,
            'studentUid': student.uid,
          });
        }
        for (final id in toRelease) {
          tx.delete(_col(FirestoreCollections.seatSlots).doc(id));
        }
      });

      return reservationId;
    });
  }

  /// Cancels the student's own pending reservation or seat booking. An
  /// approved book (a copy already set aside) is cancelled at the desk.
  Future<ActionResult> cancelReservation(String id) {
    return _run(() async {
      await _db.runTransaction((tx) async {
        final ref = _col(FirestoreCollections.reservations).doc(id);

        final snap = await tx.get(ref);

        if (!snap.exists) {
          throw const ActionRefused('Reservation not found.');
        }

        final reservation = ReservationRecord.fromMap(id, snap.data()!);

        if (reservation.studentUid != student.uid) {
          throw const ActionRefused('This is not your reservation.');
        }

        if (!reservation.isActive) {
          throw ActionRefused(
            'This reservation is already '
            '${reservation.status.label.toLowerCase()}.',
          );
        }

        if (reservation.type == ReservationType.seat && reservation.hasEnded) {
          throw const ActionRefused('This seat booking has already ended.');
        }

        if (reservation.type == ReservationType.book &&
            reservation.status == ReservationStatus.approved) {
          throw const ActionRefused(
            'A copy is already set aside for you. Please ask the librarian '
            'at the desk to cancel this reservation.',
          );
        }

        tx.update(ref, {
          'status': ReservationStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final start = reservation.startHour;
        final end = reservation.endHour;

        if (reservation.type == ReservationType.seat &&
            start != null &&
            end != null) {
          // Frees the seat-hours for other students.
          for (final slotId in SeatSlots.ids(
            reservation.itemId,
            reservation.date,
            start,
            end,
          )) {
            tx.delete(_col(FirestoreCollections.seatSlots).doc(slotId));
          }
        }

        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          LibrarianNotification(
            id: '',
            type: LibrarianNotificationType.cancelled,
            title: 'Reservation Cancelled',
            message: '${student.name} cancelled ${reservation.itemName}.',
            createdAt: DateTime.now(),
            reservationId: id,
          ).toMap(),
        );
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          StudentNotification.create(
            recipientUid: student.uid,
            type: StudentNotificationType.reservationCancelled,
            title: 'Reservation Cancelled',
            message:
                'You cancelled your reservation for ${reservation.itemName}.',
            reservationId: id,
            itemId: reservation.itemId,
          ),
        );
      });

      // Cancellation does not need to return a reservation ID.
      return null;
    });
  }

  // ---------------- Helpers ----------------

  Future<ActionResult> _run(Future<String?> Function() action) async {
    try {
      final reservationId = await action();

      return ActionResult.success(reservationId: reservationId);
    } on ActionRefused catch (e) {
      return ActionResult.failure(e.message);
    } on FirebaseException catch (e) {
      return ActionResult.failure(describeFirestoreError(e));
    } catch (_) {
      return const ActionResult.failure(
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Suspended members cannot make new reservations.
  Future<void> _checkAccountActive(Transaction tx) async {
    final user = await tx.get(
      _col(FirestoreCollections.users).doc(student.uid),
    );

    if (user.data()?['accountStatus'] == 'suspended') {
      throw const ActionRefused(
        'Your library account is suspended. Please contact the library.',
      );
    }
  }

  /// Server check (the local list may be a moment behind).
  Future<void> _checkNoActiveBookReservation(String bookId) async {
    final mine = await _col(FirestoreCollections.reservations)
        .where('studentUid', isEqualTo: student.uid)
        .get();

    final duplicate = mine.docs
        .map((d) => ReservationRecord.fromMap(d.id, d.data()))
        .any(
          (r) =>
              r.type == ReservationType.book &&
              r.itemId == bookId &&
              r.isActive,
        );

    if (duplicate) {
      throw const ActionRefused(
        'You already have an active reservation for this book.',
      );
    }
  }

  /// Server check that the student has no other active seat booking at this
  /// time (the local list may be a moment behind).
  Future<void> _checkNoSeatClash(
    DateTime day,
    int startHour,
    int endHour, {
    String? ignoreReservationId,
  }) async {
    final mine = await _col(FirestoreCollections.reservations)
        .where('studentUid', isEqualTo: student.uid)
        .get();
    final clash = mine.docs
        .map((d) => ReservationRecord.fromMap(d.id, d.data()))
        .any(
          (r) =>
              r.id != ignoreReservationId &&
              r.type == ReservationType.seat &&
              r.isActive &&
              _sameDay(r.date, day) &&
              (r.startHour ?? 0) < endHour &&
              startHour < (r.endHour ?? 0),
        );
    if (clash) {
      throw const ActionRefused('You already have a seat booked at this time.');
    }
  }

  Map<String, dynamic> _newRequest(String message, String reservationId) {
    return LibrarianNotification(
      id: '',
      type: LibrarianNotificationType.newRequest,
      title: 'New Reservation Request',
      message: message,
      createdAt: DateTime.now(),
      reservationId: reservationId,
    ).toMap();
  }

  static bool _isToday(DateTime date) => _sameDay(date, DateTime.now());

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _hh(int hour) => '${hour.toString().padLeft(2, '0')}:00';
}
