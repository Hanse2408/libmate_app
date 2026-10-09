import '../../../../models/book_reservation_validation.dart';
import '../../../../models/student_loan.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/services/firestore_errors.dart';
import '../../../../models/action_result.dart';
import '../../../../models/book.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../models/notification.dart';
import '../../../../core/services/ebook_downloader.dart';
import '../../../../core/services/ebook_service.dart';
import '../../../../repositories/ebook_repository.dart';
import '../../ebooks/providers/student_ebook_provider.dart';
import '../../../../models/reservation.dart';
import '../../../../models/reservation_loan_progress.dart';
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
    this.phone = '',
    this.photoUrl,
  });

  /// Firebase Auth uid, saved on reservations for the security rules.
  final String uid;

  /// University student ID shown to librarians (falls back to the uid).
  final String studentId;

  final String name;

  final String email;
  final String phone;
  final String? photoUrl;
}

/// Library data for the Student screens, read from the same Firestore
/// collections the Librarian writes to, so a book or seat a librarian adds
/// appears here straight away (snapshot listeners, no rebuild needed).
///
/// A student can read the catalogue, the seats and the settings, but only
/// their own reservations (see firestore.rules). Creating a reservation runs
/// in a transaction that re-checks the book / seat, so two students cannot
/// take the same seat-hour (see SeatSlots).
class StudentLibraryRepository extends ChangeNotifier
    with WidgetsBindingObserver {
  StudentLibraryRepository({
    required FirebaseFirestore firestore,
    required StudentIdentity student,
    this.onSignOut,
    this.profileImages,
    this.lifecycleBinding,
    this._createEbooks,
  }) : _db = firestore,
       _student = student {
    lifecycleBinding?.addObserver(this);
    _listen();
  }

  final FirebaseFirestore _db;
  final ImageStorage? profileImages;
  final WidgetsBinding? lifecycleBinding;
  StudentIdentity _student;
  StudentIdentity get student => _student;

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

  Map<String, dynamic> _availabilityWatches = {};
  List<StudentNotification> _availabilityNotifications = const [];
  final Set<String> _checkingAvailability = {};
  bool _alertsActive = true;

  bool isWatchingAvailability(String bookId) =>
      _availabilityWatches.containsKey(bookId);

  /// Updates only personal contact fields; account identity stays unchanged.
  Future<ActionResult> updateProfile({
    required String name,
    required String phone,
    ImageUpload? photo,
    bool removePhoto = false,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.length < 2 || cleanName.length > 80) {
      return const ActionResult.failure(
        'Please enter a name between 2 and 80 characters.',
      );
    }
    final digits = cleanPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isNotEmpty &&
        (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(cleanPhone) ||
            digits.length < 7 ||
            digits.length > 15)) {
      return const ActionResult.failure('Please enter a valid phone number.');
    }
    if (photo != null && removePhoto) {
      return const ActionResult.failure(
        'Choose a new photo or remove the existing photo.',
      );
    }
    if (photo != null) {
      final (_, error) = ImageUpload.validate(
        bytes: photo.bytes,
        fileName: photo.fileName,
        mimeType: photo.contentType,
      );
      if (error != null) return ActionResult.failure(error);
    }
    return _run(() async {
      final updates = <String, dynamic>{
        'name': cleanName,
        'phone': cleanPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (photo != null) {
        try {
          final asset = await (profileImages ?? CloudinaryImageStorage())
              .upload(photo)
              .timeout(const Duration(seconds: 60));
          updates['photoUrl'] = asset.secureUrl;
          updates['photoPublicId'] = asset.publicId;
        } on ImageStorageException catch (error) {
          throw ActionRefused(error.message);
        } on TimeoutException {
          throw const ActionRefused(
            'The photo upload timed out. Please try again.',
          );
        }
      } else if (removePhoto) {
        updates['photoUrl'] = FieldValue.delete();
        updates['photoPublicId'] = FieldValue.delete();
      }
      await _col(FirestoreCollections.users).doc(student.uid).update(updates);
      return null;
    });
  }

  /// Saved in the student's profile; no Cloud Functions or new rules needed.
  Future<ActionResult> setAvailabilityWatch(String bookId, bool enabled) async {
    try {
      final profile = _col(FirestoreCollections.users).doc(student.uid);
      final token = _db.collection('notifications').doc().id;
      await _db.runTransaction((tx) async {
        final user = await tx.get(profile);
        final book = await tx.get(_col(FirestoreCollections.books).doc(bookId));
        if (enabled) {
          if (!book.exists)
            throw StateError('This book is no longer in the catalogue.');
          if (BookRecord.fromMap(book.id, book.data()!).isAvailable) {
            throw StateError('This book is available now. You can reserve it.');
          }
        }
        final watches = Map<String, dynamic>.from(
          user.data()?['bookAvailabilityWatches'] as Map? ?? {},
        );
        if (enabled) {
          watches.putIfAbsent(bookId, () => token);
        } else {
          watches.remove(bookId);
        }
        tx.update(profile, {
          FieldPath(['bookAvailabilityWatches', bookId]): enabled
              ? watches[bookId]
              : FieldValue.delete(),
        });
      });
      return const ActionResult.success();
    } on StateError catch (error) {
      return ActionResult.failure(error.message.toString());
    } catch (_) {
      return const ActionResult.failure(
        'Could not update your alert. Please try again.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAvailabilityAlerts();
    }
  }

  void _checkAvailabilityAlerts() {
    if (!_alertsActive || _disposed) return;
    for (final entry in _availabilityWatches.entries) {
      if (bookById(entry.key)?.isAvailable != true ||
          !_checkingAvailability.add(entry.key)) {
        continue;
      }
      unawaited(_saveAvailabilityAlert(entry.key, entry.value));
    }
  }

  Future<void> _saveAvailabilityAlert(String bookId, dynamic token) async {
    try {
      final profile = _col(FirestoreCollections.users).doc(student.uid);
      await _db.runTransaction((tx) async {
        final user = await tx.get(profile);
        final book = await tx.get(_col(FirestoreCollections.books).doc(bookId));
        final watches = Map<String, dynamic>.from(
          user.data()?['bookAvailabilityWatches'] as Map? ?? {},
        );
        if (!_alertsActive ||
            _disposed ||
            watches[bookId] != token ||
            !book.exists ||
            !BookRecord.fromMap(book.id, book.data()!).isAvailable) {
          return;
        }
        final alerts = Map<String, dynamic>.from(
          user.data()?['bookAvailabilityNotifications'] as Map? ?? {},
        );
        alerts.putIfAbsent(
          token as String,
          () => StudentNotification.create(
            recipientUid: student.uid,
            type: StudentNotificationType.bookAvailable,
            title: 'Your next read is available!',
            message:
                '${book.data()!['title']} has an available copy. Tap to reserve it before it is taken.',
            itemId: bookId,
          ),
        );
        watches.remove(bookId);
        // Both writes commit together. Other devices cannot deliver twice.
        tx.update(profile, {
          FieldPath(['bookAvailabilityWatches', bookId]): FieldValue.delete(),
          FieldPath(['bookAvailabilityNotifications', token]): alerts[token],
        });
      });
    } catch (error) {
      debugPrint('Availability alert will be checked again on resume: $error');
    } finally {
      _checkingAvailability.remove(bookId);
    }
  }

  Set<String> _favoriteBookIds = {};
  Set<String> _favoriteEbookIds = {};

  bool isFavorite(String id, {bool ebook = false}) =>
      (ebook ? _favoriteEbookIds : _favoriteBookIds).contains(id);

  List<String> get catalogueCategories {
    final categories =
        _books
            .map((book) => book.category)
            .where((category) => category != 'eBooks')
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categories, 'eBooks'];
  }

  bool _disposed = false;
  List<StudentNotification> _notifications = const [];
  Set<String> _dismissedNotificationIds = {};

  // New-notification events for the in-app banner. The first snapshot is the
  // baseline; ids already seen never fire again.
  final StreamController<StudentNotification> _newNotifications =
      StreamController<StudentNotification>.broadcast();
  final Set<String> _seenNotificationIds = {};
  bool _notificationsBaselined = false;
  final Set<String> _seenAvailabilityNotificationIds = {};
  bool _availabilityNotificationsBaselined = false;

  /// Notifications that arrive after the initial load (unread, recent only).
  Stream<StudentNotification> get newNotifications => _newNotifications.stream;

  List<BookRecord> _books = const [];
  List<SeatRecord> _seats = const [];
  Map<String, ReservationLoanProgress> _reservationLoans = {};
  List<StudentLoan> _myLoans = const [];
  List<StudentLoan> get borrowedBooks =>
      List.unmodifiable(_myLoans.where((loan) => !loan.isReturned));

  ReservationLoanProgress? loanProgressForReservation(String reservationId) =>
      _reservationLoans[reservationId];
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
  List<StudentNotification> get notifications =>
      [..._notifications, ..._availabilityNotifications]
          .where(
            (notification) =>
                !_dismissedNotificationIds.contains(notification.id),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

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
    _waiting.add('favourites');
    _subscriptions.add(
      _col(FirestoreCollections.users)
          .doc(student.uid)
          .snapshots()
          .listen((snapshot) {
            final data = snapshot.data() ?? const <String, dynamic>{};
            _student = StudentIdentity(
              uid: student.uid,
              studentId: data['studentId'] as String? ?? student.studentId,
              name: data['name'] as String? ?? student.name,
              email: data['email'] as String? ?? student.email,
              phone: data['phone'] as String? ?? '',
              photoUrl: data['photoUrl'] as String?,
            );
            _dismissedNotificationIds = Set<String>.from(
              data['dismissedNotificationIds'] as List? ?? const [],
            );
            _availabilityWatches = Map<String, dynamic>.from(
              data['bookAvailabilityWatches'] as Map? ?? {},
            );
            final alerts = Map<String, dynamic>.from(
              data['bookAvailabilityNotifications'] as Map? ?? {},
            );
            _availabilityNotifications = [
              for (final entry in alerts.entries)
                StudentNotification.fromMap(
                  'availability_${entry.key}',
                  Map<String, dynamic>.from(entry.value as Map),
                ),
            ];
            for (final n in _availabilityNotifications) {
              final isNew = _seenAvailabilityNotificationIds.add(n.id);
              if (isNew && _availabilityNotificationsBaselined && !n.isRead &&
                  !_dismissedNotificationIds.contains(n.id)) {
                _newNotifications.add(n);
              }
            }
            _availabilityNotificationsBaselined = true;
            _checkAvailabilityAlerts();
            _favoriteBookIds = Set<String>.from(
              data['favoriteBookIds'] as List? ?? const [],
            );
            _favoriteEbookIds = Set<String>.from(
              data['favoriteEbookIds'] as List? ?? const [],
            );
            _received('favourites');
          }, onError: (Object error) => _failed('favourites', error)),
    );
    _watch(_col(FirestoreCollections.books), 'books', (docs) {
      _books = [
        for (final d in docs) BookRecord.fromMap(d.id, d.data()),
      ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      _checkAvailabilityAlerts();
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
        for (final n in _notifications) {
          final isNew = _seenNotificationIds.add(n.id);
          final recent =
              DateTime.now().difference(n.createdAt) <
              const Duration(minutes: 5);
          if (isNew && _notificationsBaselined && !n.isRead && recent) {
            _newNotifications.add(n);
          }
        }
        _notificationsBaselined = true;
      },
    );

    // Read only this student's loans, linked by reservation ID, never book ID.
    _watch(
      _col(FirestoreCollections.borrowings)
          .where('memberUid', isEqualTo: student.uid),
      'loanProgress',
      (docs) {
        _myLoans =
            [for (final doc in docs) StudentLoan.fromMap(doc.id, doc.data())]
              ..sort(
                (a, b) => (a.dueDate ?? DateTime(9999)).compareTo(
                  b.dueDate ?? DateTime(9999),
                ),
              );
        final loans = <String, ReservationLoanProgress>{};
        for (final doc in docs) {
          final data = doc.data();
          final reservationId = data['reservationId'];
          if (reservationId is! String || reservationId.isEmpty) continue;
          final loan = ReservationLoanProgress.fromMap(data);
          final previous = loans[reservationId];
          if (previous == null || loan.issuedAt.isAfter(previous.issuedAt)) {
            loans[reservationId] = loan;
          }
        }
        _reservationLoans = loans;
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
    _alertsActive = false;
    lifecycleBinding?.removeObserver(this);
    _stopListening();
    _newNotifications.close();
    _ebooks?.dispose();
    super.dispose();
  }

  /// Logs the student out with the app's existing AuthProvider. Listeners
  /// stop first, so no "permission denied" errors appear while signing out.
  /// The router then sends the user to the Login screen.
  Future<void> signOut() async {
    // Push-token cleanup needs the signed-in user, so it runs first and can
    // never block logout.
    try {
      await beforeSignOut?.call().timeout(const Duration(seconds: 5));
    } catch (_) {}
    _alertsActive = false;
    _stopListening();
    await onSignOut?.call();
  }

  /// Optional cleanup run just before sign-out (removes this device's push token).
  Future<void> Function()? beforeSignOut;

  /// Adds this device's push token to users/{uid}.fcmTokens (no duplicates;
  /// other user fields are untouched).
  Future<void> addFcmToken(String token) =>
      _col(FirestoreCollections.users).doc(student.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

  /// Removes only the given device token from users/{uid}.fcmTokens.
  Future<void> removeFcmToken(String token) =>
      _col(FirestoreCollections.users).doc(student.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

  /// Deletes the given notifications of this student. Ids that are not this
  /// student's own are ignored. Book-availability alerts live in the student's
  /// profile, so they are hidden there instead of deleted.
  Future<ActionResult> deleteNotifications(Set<String> ids) async {
    final own = notifications.where((n) => ids.contains(n.id)).toList();
    if (own.isEmpty) return const ActionResult.success();
    return _run(() async {
      final batch = _db.batch();
      final hidden = <String>[];
      for (final n in own) {
        if (n.id.startsWith('availability_')) {
          hidden.add(n.id);
        } else {
          batch.delete(_col(FirestoreCollections.notifications).doc(n.id));
        }
      }
      if (hidden.isNotEmpty) {
        batch.update(_col(FirestoreCollections.users).doc(student.uid), {
          'dismissedNotificationIds': FieldValue.arrayUnion(hidden),
        });
      }
      await batch.commit();
      return null;
    });
  }

  /// Hide an opened notification persistently, without requiring delete rules.
  /// Mark it read in the same batch so the badge stays accurate on every device.
  Future<ActionResult> dismissNotification(String id) async {
    if (_dismissedNotificationIds.contains(id))
      return const ActionResult.success();
    final notification = notifications.where((n) => n.id == id).firstOrNull;
    if (notification == null)
      return const ActionResult.failure('Notification not found.');
    return _run(() async {
      final batch = _db.batch();
      final profile = _col(FirestoreCollections.users).doc(student.uid);
      final profileUpdates = <String, dynamic>{
        'dismissedNotificationIds': FieldValue.arrayUnion([id]),
      };
      if (notification.type == StudentNotificationType.bookAvailable &&
          id.startsWith('availability_')) {
        profileUpdates['bookAvailabilityNotifications.${id.substring('availability_'.length)}.isRead'] =
            true;
      } else if (!notification.isRead) {
        batch.update(_col(FirestoreCollections.notifications).doc(id), {
          'isRead': true,
        });
      }
      batch.update(profile, profileUpdates);
      await batch.commit();
      return null;
    });
  }

  /// Marks one of this student's notifications as read (already read: no-op).
  Future<ActionResult> markNotificationRead(String id) async {
    final notification = notifications.where((n) => n.id == id).firstOrNull;
    if (notification == null)
      return const ActionResult.failure('Notification not found.');
    if (notification.isRead) return const ActionResult.success();
    return _run(() async {
      if (notification.type == StudentNotificationType.bookAvailable &&
          id.startsWith('availability_')) {
        await _col(FirestoreCollections.users).doc(student.uid).update({
          'bookAvailabilityNotifications.${id.substring('availability_'.length)}.isRead':
              true,
        });
      } else {
        await _col(FirestoreCollections.notifications)
            .doc(id)
            .update({'isRead': true});
      }
      return null;
    });
  }

  /// Marks all of this student's unread notifications as read.
  Future<ActionResult> markAllNotificationsRead() async {
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return const ActionResult.success();
    return _run(() async {
      final batch = _db.batch();
      for (final n in unread) {
        if (n.type == StudentNotificationType.bookAvailable &&
            n.id.startsWith('availability_')) {
          batch.update(_col(FirestoreCollections.users).doc(student.uid), {
            'bookAvailabilityNotifications.${n.id.substring('availability_'.length)}.isRead':
                true,
          });
        } else {
          batch.update(_col(FirestoreCollections.notifications).doc(n.id), {
            'isRead': true,
          });
        }
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

  /// Atomic per-user favourites: separate IDs for physical and digital books.
  Future<ActionResult> setFavorite(
    String id, {
    required bool favorite,
    bool ebook = false,
  }) {
    return _run(() async {
      await _col(FirestoreCollections.users).doc(student.uid).update({
        ebook ? 'favoriteEbookIds' : 'favoriteBookIds': favorite
            ? FieldValue.arrayUnion([id])
            : FieldValue.arrayRemove([id]),
      });
      return null;
    });
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
    final fieldError = BookReservationValidation.error(
      pickupDate: pickupDate,
      loanPeriodDays: loanPeriodDays,
      pickupLocation: pickupLocation,
    );
    if (fieldError != null) return ActionResult.failure(fieldError);
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
    String? notes,
  }) {
    final fieldError = BookReservationValidation.error(
      pickupDate: pickupDate,
      loanPeriodDays: loanPeriodDays,
      pickupLocation: pickupLocation,
    );
    if (fieldError != null)
      return Future.value(ActionResult.failure(fieldError));
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

        if (reservation.status == ReservationStatus.approved) {
          throw const ActionRefused(
            'Approved book reservations cannot be modified.',
          );
        }
        if (!reservation.isPending) {
          throw const ActionRefused(
            'Only pending book reservations can be modified.',
          );
        }

        tx.update(ref, {
          'date': Timestamp.fromDate(pickupDate),
          'pickupLocation': pickupLocation,
          'loanPeriodDays': loanPeriodDays,
          if (notes != null) 'notes': notes.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          StudentNotification.create(
            recipientUid: student.uid,
            type: StudentNotificationType.bookReservationUpdated,
            title: 'Reservation Updated',
            message: 'Your reservation for ${reservation.itemName} has been updated.',
            reservationId: reservation.id,
            itemId: reservation.itemId,
          ),
        );
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

        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          StudentNotification.create(
            recipientUid: student.uid,
            type: StudentNotificationType.seatBookingConfirmed,
            title: 'Seat Booking Confirmed',
            message:
                'Seat ${latest.seatNumber} has been reserved for $slotLabel.',
            reservationId: ref.id,
            itemId: latest.id,
          ),
        );
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

        tx.set(
          _col(FirestoreCollections.notifications).doc(),
          StudentNotification.create(
            recipientUid: student.uid,
            type: StudentNotificationType.seatReservationUpdated,
            title: 'Reservation Updated',
            message:
                'Your reservation is now Seat ${latest.seatNumber} for '
                '${ReservationRecord.slotLabel(startHour, endHour)}.',
            reservationId: reservationId,
            itemId: latest.id,
          ),
        );
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
            'Approved book reservations cannot be cancelled.',
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
