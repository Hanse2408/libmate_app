import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/reservation_loan_progress.dart';
import 'package:libmate_app/features/student/book_reservation/widgets/reservation_progress_card.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'library_test_support.dart';

ReservationRecord reservation(ReservationStatus status) => ReservationRecord(
  id: 'reservation', type: ReservationType.book, status: status,
  studentUid: studentUid, studentId: 'student', studentName: 'Test Student',
  studentEmail: 'student@example.com', itemId: 'book', itemName: 'Test Book',
  requestedAt: DateTime(2026, 1, 1), date: DateTime(2026, 1, 2), rejectionReason: 'No copies remain',
);

/// The step the tracker highlights (its accessible label names it).
String journeyStep(WidgetTester tester) {
  final semantics = tester.widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? '')
      .firstWhere((label) => label.startsWith('Reservation progress:'));
  return semantics;
}

void main() {
  test('loans are linked by reservation and student, not just the book', () async {
    final db = await seededFirestore(); final library = studentRepo(db);
    addTearDown(library.dispose);
    await db.collection('borrowings').doc('mine').set({
      'memberUid': studentUid, 'reservationId': 'mine', 'bookId': 'same-book',
      'issuedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    });
    await db.collection('borrowings').doc('other').set({
      'memberUid': otherStudentUid, 'reservationId': 'other', 'bookId': 'same-book',
      'returnedAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
    });
    await settle();
    expect(library.loanProgressForReservation('mine')?.returnedAt, isNull);
    expect(library.loanProgressForReservation('other'), isNull);
    expect(library.loanProgressForReservation('missing'), isNull);
    await db.collection('borrowings').doc('mine').update({
      'returnedAt': Timestamp.fromDate(DateTime(2026, 1, 4)),
    });
    await settle();
    expect(library.loanProgressForReservation('mine')?.returnedAt, DateTime(2026, 1, 4));
  });

  for (final dark in [false, true]) {
    testWidgets('all progress states fit a small screen, dark: $dark', (tester) async {
      tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<void> show(ReservationStatus status, {ReservationLoanProgress? loan}) async {
        await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16),
            child: ReservationProgressCard(reservation: reservation(status), loan: loan))))));
        await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
      }
      await show(ReservationStatus.pending);
      expect(find.textContaining('Your request is with'), findsOneWidget);
      await show(ReservationStatus.approved);
      expect(find.textContaining('Your book is ready!'), findsOneWidget);
      await show(ReservationStatus.completed);
      expect(find.textContaining('Enjoy your book!'), findsOneWidget);
      await show(ReservationStatus.completed, loan: ReservationLoanProgress(
        issuedAt: DateTime(2026, 1, 2), returnedAt: DateTime(2026, 1, 4)));
      expect(find.textContaining('Book returned on 4/1/2026'), findsOneWidget);
      await show(ReservationStatus.collected);
      expect(find.textContaining('Enjoy your book!'), findsOneWidget);
      await show(ReservationStatus.returned);
      expect(find.textContaining('Reading journey complete.'), findsOneWidget);
      await show(ReservationStatus.rejected);
      expect(find.text('No copies remain'), findsOneWidget);
      expect(find.text('Requested'), findsNothing);
      await show(ReservationStatus.cancelled);
      expect(find.text('Reservation cancelled'), findsOneWidget);
    });
  }

  testWidgets('journey shows Collected, then Returned, when the librarian marks them', (tester) async {
    tester.view.physicalSize = const Size(440, 1400); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore();
    final librarian = librarianRepo(db, FakeImageStorage());
    final library = studentRepo(db);
    addTearDown(library.dispose);
    addTearDown(librarian.dispose);

    late String id;
    await tester.runAsync(() async {
      await librarian.addBook(title: 'Clean Code', author: 'Robert C. Martin',
        isbn: '9780132350884', category: 'Software Engineering', language: 'English',
        shelfLocation: 'SE-1', totalCopies: 1);
      await settle();
      final booked = await library.reserveBook(book: library.books.single,
        pickupDate: tomorrow(), loanPeriodDays: 14, pickupLocation: 'Main Desk');
      expect(booked.success, isTrue, reason: booked.message);
      await settle();
      id = librarian.reservations.single.id;
      await librarian.approveReservation(id);
      await settle();
    });
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: ReservationDetailsScreen(library: library, reservationId: id)));
    await tester.pumpAndSettle();
    expect(journeyStep(tester), contains('Ready for Pickup'));
    expect(find.textContaining('Your book is ready!'), findsOneWidget);

    // Librarian: Mark as Collected -> the student's journey follows.
    await tester.runAsync(() async {
      expect((await librarian.markReservationCollected(id)).success, isTrue);
      await settle();
    });
    await tester.pumpAndSettle();
    expect(journeyStep(tester), contains('Collected'));
    expect(find.textContaining('Enjoy your book!'), findsOneWidget);

    // Librarian: Mark as Returned -> the student's journey follows.
    await tester.runAsync(() async {
      expect((await librarian.markReservationReturned(id)).success, isTrue);
      await settle();
    });
    await tester.pumpAndSettle();
    expect(journeyStep(tester), contains('Returned'));
    expect(find.textContaining('Reading journey complete.'), findsOneWidget);
    // No way for the student to change these steps.
    expect(find.text('Mark as Collected'), findsNothing);
    expect(find.text('Mark as Returned'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('details tracker updates live when the linked loan is returned', (tester) async {
    tester.view.physicalSize = const Size(440, 1400); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore(); final library = studentRepo(db);
    addTearDown(library.dispose);
    await db.collection('reservations').doc('reservation').set(reservation(ReservationStatus.completed).toMap());
    await db.collection('borrowings').doc('loan').set({
      'memberUid': studentUid, 'reservationId': 'reservation',
      'issuedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    });
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: ReservationDetailsScreen(library: library, reservationId: 'reservation')));
    await tester.pumpAndSettle();
    expect(find.text('Your book journey'), findsOneWidget);
    expect(find.textContaining('Enjoy your book!'), findsOneWidget);
    await db.collection('borrowings').doc('loan').update({
      'returnedAt': Timestamp.fromDate(DateTime(2026, 1, 4)),
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Book returned on 4/1/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
