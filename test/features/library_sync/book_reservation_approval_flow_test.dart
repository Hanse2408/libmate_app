import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/librarian/widgets/reservation_card.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reserve_book_screen.dart';
import 'package:libmate_app/models/reservation.dart';

import '../librarian/librarian_test_helpers.dart';
import 'library_test_support.dart';

/// The real book reservation flow, through the real screens, on one shared
/// (fake) Firestore database:
/// Student "Confirm Reservation" -> `reservations` (pending) -> Librarian
/// Reservation Management + banner -> Librarian Approve / Reject.
void main() {
  late FakeFirebaseFirestore db;
  late String bookId;

  setUp(() async {
    db = await seededFirestore();
    // 1. A librarian adds a physical book (3 copies).
    final librarian = librarianRepo(db, FakeImageStorage());
    await librarian.addBook(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'SE-1',
      totalCopies: 3,
    );
    await settle();
    bookId = librarian.books.single.id;
    librarian.dispose();
  });

  /// Steps 2-4: the student opens Reserve Book and taps Confirm Reservation.
  Future<void> studentConfirms(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final student = studentRepo(db);
    addTearDown(student.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ReserveBookScreen(library: student, bookId: bookId),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Clean Code'), findsWidgets); // the student sees the book

    await tester.ensureVisible(find.text('Confirm Reservation'));
    await tester.tap(find.text('Confirm Reservation'));
    await tester.pumpAndSettle();
    // The student is told it is waiting for the librarian.
    expect(find.text('Reservation Requested!'), findsOneWidget);
    expect(find.text('Pending approval'), findsOneWidget);
  }

  Future<Map<String, dynamic>> onlyReservation() async =>
      (await db.collection('reservations').get()).docs.single.data();

  Future<int> copies() async =>
      (await db.collection('books').doc(bookId).get())
              .data()!['availableCopies']
          as int;

  testWidgets(
    'Confirm creates a PENDING reservation; only the librarian approves it',
    (tester) async {
      await studentConfirms(tester);

      // 5. Firestore: one reservation, pending, linked to the book and student.
      final saved = await onlyReservation();
      expect(saved['status'], 'pending');
      expect(saved['type'], 'book');
      expect(saved['itemId'], bookId);
      expect(saved['studentUid'], studentUid);
      expect(saved['studentId'], 'IT23004512');
      expect(await copies(), 3); // a request does not take a copy

      // 6-7. Librarian: Reservation Management lists it, the banner shows it.
      LibrarianFirestoreRepository? librarian;
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.reservations,
        size: const Size(420, 1000),
        createRepository: () =>
            librarian = librarianRepo(db, FakeImageStorage()),
      );
      await tester.pumpAndSettle();
      final card = find.widgetWithText(ReservationCard, 'Nethmi Perera');
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Pending')),
        findsOneWidget,
      );
      expect(librarian!.notifications.first.title, 'New Reservation Request');
      expect(librarian!.notifications.first.isRead, isFalse);

      // Still pending: nothing approved it yet.
      expect((await onlyReservation())['status'], 'pending');

      // 8-10. The librarian opens it and approves.
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        router.currentPath,
        LibrarianRoutes.reservationDetails(librarian!.reservations.single.id),
      );
      await tapVisible(tester, find.text('Approve Reservation'));

      // 11-12. Only now: approved, and one copy is set aside.
      expect((await onlyReservation())['status'], 'approved');
      expect(await copies(), 2);
      expect(router.currentPath, endsWith('/confirmation'));
    },
  );

  testWidgets('the librarian can reject it instead', (tester) async {
    await studentConfirms(tester);

    LibrarianFirestoreRepository? librarian;
    await pumpLibrarian(
      tester,
      LibrarianRoutes.reservations,
      size: const Size(420, 1000),
      createRepository: () => librarian = librarianRepo(db, FakeImageStorage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ReservationCard, 'Nethmi Perera'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Reject Reservation'));
    await tester.tap(find.text('Duplicate request'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();

    final saved = await onlyReservation();
    expect(saved['status'], 'rejected');
    expect(saved['rejectionReason'], 'Duplicate request');
    expect(await copies(), 3); // a rejection never takes a copy
    expect(librarian!.reservations.single.status, ReservationStatus.rejected);
  });

  test(
    'an existing book in the earlier format can be reserved and approved',
    () async {
      await db.collection('books').doc('LEGACY').set(legacyBook('LEGACY'));
      final student = studentRepo(db);
      await settle();
      final book = student.bookById('LEGACY')!;
      expect(
        book.isAvailable,
        isTrue,
        reason: 'available: true means a copy can be reserved',
      );

      final reserved = await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      expect(reserved.success, isTrue, reason: reserved.message);
      await settle();

      final librarian = librarianRepo(db, FakeImageStorage());
      await settle();
      final request = librarian.reservations.singleWhere(
        (r) => r.itemId == 'LEGACY',
      );
      expect(request.status, ReservationStatus.pending);
      final approved = await librarian.approveReservation(request.id);
      expect(approved.success, isTrue, reason: approved.message);

      final saved = (await db.collection('books').doc('LEGACY').get()).data()!;
      expect(saved['availableCopies'], 0);
      expect(saved['available'], isFalse);
      expect(
        saved['totalCopies'],
        1,
      ); // now stored, so the rules accept the update
      librarian.dispose();
      student.dispose();
    },
  );

  test(
    'a student cannot approve: the student repository has no approve action',
    () async {
      // The only write a student can make to an existing reservation is a
      // cancellation (see StudentLibraryRepository and firestore.rules).
      final student = studentRepo(db);
      await settle();
      final result = await student.reserveBook(
        book: student.bookById(bookId)!,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      expect(result.success, isTrue);
      await settle();
      expect(student.myReservations.single.status, ReservationStatus.pending);
      student.dispose();
    },
  );
}

/// A book saved in the earlier Student-side format (no copy counts, only
/// `available`), like the existing book1.jpg ... book12 documents.
Map<String, dynamic> legacyBook(String id) => {
  'bookId': id,
  'title': 'Atomic Habits',
  'author': 'James Clear',
  'category': 'Self-Help',
  'description': 'Small changes, remarkable results.',
  'coverAsset': 'assets/images/books/book2.jpg',
  'publisher': 'Avery',
  'publishedYear': 2018,
  'pages': 320,
  'available': true,
  'location': 'Shelf B',
};
