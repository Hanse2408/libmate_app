import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/student/book_reservation/screens/book_details_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';
import 'package:libmate_app/models/book.dart';
import 'package:libmate_app/models/notification.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/seat.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'library_test_support.dart';

/// The full Librarian <-> Student flow on one (fake) Firestore database:
/// books and seats, reservations, approval / rejection, copies and the
/// student's notifications.
void main() {
  late FakeFirebaseFirestore db;
  late FakeImageStorage storage;
  late LibrarianFirestoreRepository librarian;
  late StudentLibraryRepository student;

  setUp(() async {
    db = await seededFirestore();
    storage = FakeImageStorage();
    librarian = librarianRepo(db, storage);
    student = studentRepo(db);
    // No settle() here: under testWidgets the fake clock would never let it
    // finish. The helpers below wait for Firestore themselves.
  });

  tearDown(() {
    librarian.dispose();
    student.dispose();
  });

  Future<BookRecord> addBook({int copies = 10}) async {
    final result = await librarian.addBook(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'SE-01',
      totalCopies: copies,
      coverAsset: 'assets/images/books/book1.jpg',
    );
    expect(result.success, isTrue, reason: result.message);
    await settle();
    return librarian.books.single;
  }

  Future<SeatRecord> addSeat() async {
    final result = await librarian.addSeat(
      seatNumber: 'A01',
      zone: 'Row A',
      readingRoom: 'Reading Room A',
      type: SeatType.quietZone,
    );
    expect(result.success, isTrue, reason: result.message);
    await settle();
    return librarian.seats.single;
  }

  Future<ReservationRecord> reserve(
    StudentLibraryRepository who,
    BookRecord book,
  ) async {
    final result = await who.reserveBook(
      book: who.bookById(book.id)!,
      pickupDate: tomorrow(),
      loanPeriodDays: 14,
      pickupLocation: 'Main Desk',
    );
    expect(result.success, isTrue, reason: result.message);
    await settle();
    return librarian.reservations.firstWhere(
      (r) => r.studentUid == who.student.uid,
    );
  }

  Future<int> copiesInFirestore(String bookId) async =>
      (await db.collection('books').doc(bookId).get())
              .data()!['availableCopies']
          as int;

  group('Books', () {
    test(
      'a book the librarian adds is shown to students with its details',
      () async {
        final book = await addBook();
        final seen = student.bookById(book.id)!;
        expect(seen.title, 'Clean Code');
        expect(seen.author, 'Robert C. Martin');
        expect(seen.coverAsset, 'assets/images/books/book1.jpg');
        expect(seen.category, 'Software Engineering');
        expect(seen.availableCopies, 10);
      },
    );

    test(
      'a request does not use a copy; approval takes exactly one (10 -> 9)',
      () async {
        final book = await addBook();
        final request = await reserve(student, book);

        // The librarian sees the request; no copy is used yet.
        expect(request.status, ReservationStatus.pending);
        expect(request.itemId, book.id);
        expect(await copiesInFirestore(book.id), 10);

        expect(
          (await librarian.approveReservation(request.id)).success,
          isTrue,
        );
        await settle();
        expect(await copiesInFirestore(book.id), 9);
        expect(student.bookById(book.id)!.availableCopies, 9);
        expect(student.bookById(book.id)!.totalCopies, 10); // total unchanged
        expect(
          student.myReservations.single.status,
          ReservationStatus.approved,
        );
      },
    );

    test(
      'rejection: the student sees the status and reason, copies unchanged',
      () async {
        final book = await addBook();
        final request = await reserve(student, book);

        expect(
          (await librarian.rejectReservation(
            request.id,
            'Reserved for exams',
          )).success,
          isTrue,
        );
        await settle();
        final seen = student.myReservations.single;
        expect(seen.status, ReservationStatus.rejected);
        expect(seen.rejectionReason, 'Reserved for exams');
        expect(await copiesInFirestore(book.id), 10);
      },
    );

    test(
      'with 0 copies: no new reservation and approval never goes negative',
      () async {
        final book = await addBook(copies: 1);
        final first = await reserve(student, book);
        final other = studentRepo(db, uid: otherStudentUid);
        addTearDown(other.dispose);
        await settle();
        final second = await reserve(other, book);

        expect((await librarian.approveReservation(first.id)).success, isTrue);
        await settle();
        expect(await copiesInFirestore(book.id), 0);
        expect(student.bookById(book.id)!.isAvailable, isFalse);

        // The second request cannot be approved: there is no copy left.
        final refused = await librarian.approveReservation(second.id);
        expect(refused.success, isFalse);
        expect(refused.message, contains('No copies'));
        expect(await copiesInFirestore(book.id), 0);

        // And nobody can create a new reservation for it.
        final third = studentRepo(db, uid: 'student-3');
        addTearDown(third.dispose);
        await settle();
        expect(
          third.bookReservationBlocker(third.bookById(book.id)!),
          contains('No copies'),
        );
        final blocked = await third.reserveBook(
          book: third.bookById(book.id)!,
          pickupDate: tomorrow(),
          loanPeriodDays: 14,
          pickupLocation: 'Desk',
        );
        expect(blocked.success, isFalse);
      },
    );

    test(
      'last copy: the transaction refuses a second approval on its own',
      () async {
        // The second desk skips the on-screen check, as if its list still
        // showed "1 available": only the transaction's server read can stop it.
        // (On real Firestore two simultaneous transactions conflict and the
        // second is retried with the new value; the fake cannot simulate that.)
        final book = await addBook(copies: 1);
        final first = await reserve(student, book);
        final other = studentRepo(db, uid: otherStudentUid);
        addTearDown(other.dispose);
        await settle();
        final second = await reserve(other, book);

        final secondDesk = _StaleListLibrarian(db, storage);
        addTearDown(secondDesk.dispose);
        await settle();

        expect((await librarian.approveReservation(first.id)).success, isTrue);
        final late = await secondDesk.approveReservation(second.id);
        expect(late.success, isFalse);
        expect(late.message, contains('No copies'));

        await settle();
        expect(await copiesInFirestore(book.id), 0); // never -1
        expect(
          librarian.reservations.where(
            (r) => r.status == ReservationStatus.approved,
          ),
          hasLength(1),
        );
      },
    );

    test('a returned book puts the copy back; total stays the same', () async {
      final book = await addBook(copies: 2);
      final request = await reserve(student, book);
      await librarian.approveReservation(request.id);
      await settle();
      await librarian.markReservationCollected(request.id);
      await settle();
      expect(await copiesInFirestore(book.id), 1);

      await librarian.markBorrowingReturned(librarian.borrowings.single.id);
      await settle();
      expect(await copiesInFirestore(book.id), 2);
      expect(student.bookById(book.id)!.totalCopies, 2);
    });

    test('approval is refused when the book document was deleted', () async {
      final book = await addBook();
      final request = await reserve(student, book);
      await db
          .collection('books')
          .doc(book.id)
          .delete(); // e.g. removed in the console
      await settle();

      final result = await librarian.approveReservation(request.id);
      expect(result.success, isFalse);
      expect(result.message, contains('no longer in the catalogue'));
    });
  });

  group('Seats', () {
    test('a seat the librarian adds is shown to students', () async {
      final seat = await addSeat();
      expect(student.seatById(seat.id)!.seatNumber, 'A01');
    });

    test(
      'a seat booking is confirmed at once and the librarian sees it',
      () async {
        final seat = await addSeat();
        final booked = await student.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 10,
          endHour: 12,
        );
        expect(booked.success, isTrue, reason: booked.message);
        await settle();

        final request = librarian.reservations.single;
        expect(request.id, booked.reservationId);
        expect(request.type, ReservationType.seat);
        expect(request.status, ReservationStatus.approved);
        expect(request.timeSlot, '10:00 - 12:00');
        expect(
          student.myReservations.single.status,
          ReservationStatus.approved,
        );
      },
    );

    test(
      'a rejected seat booking frees the seat and the student sees it',
      () async {
        final seat = await addSeat();
        await student.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 10,
          endHour: 12,
        );
        await settle();
        // Seat bookings are confirmed at once; this is an older pending one.
        await db
            .collection('reservations')
            .doc(librarian.reservations.single.id)
            .update({'status': 'pending'});
        await settle();

        await librarian.rejectReservation(
          librarian.reservations.single.id,
          'Room closed',
        );
        await settle();
        expect(
          student.myReservations.single.status,
          ReservationStatus.rejected,
        );
        expect((await db.collection('seatSlots').get()).docs, isEmpty);
      },
    );

    test('an overlapping booking by another student is refused', () async {
      final seat = await addSeat();
      final other = studentRepo(db, uid: otherStudentUid);
      addTearDown(other.dispose);
      await settle();

      expect(
        (await student.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 10,
          endHour: 12,
        )).success,
        isTrue,
      );
      final clash = await other.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 11,
        endHour: 12,
      );
      expect(clash.success, isFalse);
    });
  });

  group('Student notifications', () {
    List<StudentNotificationType> typesOf(StudentLibraryRepository who) => [
      for (final n in who.notifications) n.type,
    ];

    test(
      'request, approval, collection, renewal and return notify the student',
      () async {
        final book = await addBook();
        final request = await reserve(student, book);
        expect(typesOf(student), [
          StudentNotificationType.reservationRequested,
        ]);

        await librarian.approveReservation(request.id);
        await settle();
        final approved = student.notifications.first;
        expect(approved.type, StudentNotificationType.reservationApproved);
        expect(approved.recipientUid, studentUid);
        expect(approved.reservationId, request.id);
        expect(approved.itemId, book.id);
        expect(approved.isRead, isFalse);

        await librarian.markReservationCollected(request.id);
        await settle();
        await librarian.renewBorrowing(librarian.borrowings.single.id);
        await settle();
        await librarian.markBorrowingReturned(librarian.borrowings.single.id);
        await settle();
        expect(
          typesOf(student),
          containsAll([
            StudentNotificationType.bookCollected,
            StudentNotificationType.loanRenewed,
            StudentNotificationType.bookReturned,
          ]),
        );
        expect(student.unreadNotificationCount, student.notifications.length);
      },
    );

    test('rejections and seat updates notify the student', () async {
      final seat = await addSeat();
      await student.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 10,
        endHour: 12,
      );
      await settle();
      // Seat bookings are confirmed at once; this is an older pending one.
      await db
          .collection('reservations')
          .doc(librarian.reservations.single.id)
          .update({'status': 'pending'});
      await settle();
      await librarian.rejectReservation(
        librarian.reservations.single.id,
        'Room closed',
      );
      await settle();

      final rejected = student.notifications.first;
      expect(rejected.type, StudentNotificationType.reservationRejected);
      expect(rejected.message, contains('Room closed'));
      // A new seat booking sends no "requested" notification.
      expect(
        typesOf(student),
        isNot(contains(StudentNotificationType.reservationRequested)),
      );
    });

    test('cancelling notifies the student', () async {
      final book = await addBook();
      final request = await reserve(student, book);
      expect((await student.cancelReservation(request.id)).success, isTrue);
      await settle();
      expect(
        student.notifications.first.type,
        StudentNotificationType.reservationCancelled,
      );
    });

    test('each student only sees their own notifications', () async {
      final book = await addBook();
      final other = studentRepo(db, uid: otherStudentUid);
      addTearDown(other.dispose);
      await settle();
      final request = await reserve(student, book);
      await librarian.approveReservation(request.id);
      await settle();

      expect(student.notifications, isNotEmpty);
      expect(
        student.notifications.every((n) => n.recipientUid == studentUid),
        isTrue,
      );
      expect(other.notifications, isEmpty); // nothing about someone else
      // Librarian alerts are not student notifications.
      expect(
        student.notifications.any((n) => n.title == 'New Reservation Request'),
        isFalse,
      );
    });

    test('marking as read; already read is a no-op', () async {
      final book = await addBook();
      await reserve(student, book);
      final id = student.notifications.single.id;

      expect((await student.markNotificationRead(id)).success, isTrue);
      await settle();
      expect(student.notifications.single.isRead, isTrue);
      expect(student.unreadNotificationCount, 0);
      expect(
        (await student.markNotificationRead(id)).success,
        isTrue,
      ); // again: fine
      expect(
        (await student.markAllNotificationsRead()).success,
        isTrue,
      ); // nothing unread
    });

    test('a Firestore error when marking read is reported', () async {
      final book = await addBook();
      await reserve(student, book);
      final id = student.notifications.single.id;
      whenCalling(Invocation.method(#update, null))
          .on(db.collection('notifications').doc(id))
          .thenThrow(
            FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
          );

      final result = await student.markNotificationRead(id);
      expect(result.success, isFalse);
      expect(result.message, contains('Cannot reach the database'));
    });
  });

  group('Student screens', () {
    Future<void> pump(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
    }

    testWidgets('a book with 0 available copies cannot be reserved', (
      tester,
    ) async {
      late BookRecord book;
      await tester.runAsync(() async {
        book = await addBook(copies: 1);
        await db.collection('books').doc(book.id).update({
          'availableCopies': 0,
          'available': false,
        });
        await settle();
      });

      await pump(tester, BookDetailsScreen(library: student, bookId: book.id));
      expect(find.text('No copies are available right now.'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Reserve Book'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('notifications screen: own list, tap marks read, empty state', (
      tester,
    ) async {
      await pump(tester, StudentNotificationsScreen(library: student));
      expect(find.text('You have no new notifications.'), findsOneWidget);

      await tester.runAsync(() async {
        final book = await addBook();
        await reserve(student, book);
        await settle();
      });
      await tester.pumpAndSettle();
      expect(find.text('Reservation Requested'), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);

      await tester.tap(find.text('Reservation Requested'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
      final saved =
          (await db
                  .collection('notifications')
                  .where('recipientUid', isEqualTo: studentUid)
                  .get())
              .docs
              .single
              .data();
      expect(saved['isRead'], isTrue);
    });
  });

  group('Student logout', () {
    testWidgets(
      'logout signs out, shows Login and the Student pages are gone',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final auth = _FakeAuthRepository();
        final authProvider = AuthProvider(
          authRepository: auth,
          userRepository: _Profiles(),
        );
        final router = AppRouter(
          authProvider,
          createStudentLibrary: () => StudentLibraryRepository(
            firestore: db,
            student: const StudentIdentity(
              uid: studentUid,
              studentId: 'IT23004512',
              name: 'Nethmi Perera',
              email: 'nethmi@student.test',
            ),
            onSignOut: authProvider.signOut,
          ),
        ).router;
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        String path() => router.routerDelegate.currentConfiguration.uri.path;

        auth.emitSignedIn();
        await tester.pumpAndSettle();
        expect(path(), AppRoutes.studentHome);

        // Home -> Profile -> Log Out -> confirm.
        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();
        final logOut = find.widgetWithText(OutlinedButton, 'Log Out');
        await tester.ensureVisible(logOut);
        await tester.pumpAndSettle();
        await tester.tap(logOut);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Log Out'));
        await tester.pumpAndSettle();

        expect(auth.signOutCalls, 1);
        expect(authProvider.user, isNull);
        expect(authProvider.profile, isNull);
        expect(path(), AppRoutes.login);
        expect(find.text('Welcome Back!'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Log Out'),
          findsNothing,
        ); // Profile gone

        // Protected Student pages stay closed.
        router.go(AppRoutes.studentHome);
        await tester.pumpAndSettle();
        expect(path(), AppRoutes.login);

        // Signing in again opens a fresh Student home.
        auth.emitSignedIn();
        await tester.pumpAndSettle();
        expect(path(), AppRoutes.studentHome);
        expect(find.text('Nethmi!'), findsOneWidget);
      },
    );
  });
}

/// A librarian whose own list-based check always passes, so approval is
/// decided only by the Firestore transaction.
class _StaleListLibrarian extends LibrarianFirestoreRepository {
  _StaleListLibrarian(FakeFirebaseFirestore db, FakeImageStorage storage)
    : super(firestore: db, imageStorage: storage, librarianUid: librarianUid);

  @override
  String? approvalBlocker(ReservationRecord reservation) => null;
}

class _FakeUser implements User {
  @override
  String get uid => studentUid;

  @override
  String? get email => 'nethmi@student.test';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Behaves like Firebase Auth: sign-in / sign-out are reported on the stream.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<User?>.broadcast();
  User? _current;
  int signOutCalls = 0;

  void emitSignedIn() {
    _current = _FakeUser();
    _controller.add(_current);
  }

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<User?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class _Profiles implements UserRepository {
  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async => const AppUser(
    uid: studentUid,
    name: 'Nethmi Perera',
    studentId: 'IT23004512',
    email: 'nethmi@student.test',
    role: UserRole.student,
  );
}
