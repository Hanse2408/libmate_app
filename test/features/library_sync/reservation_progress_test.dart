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
      await show(ReservationStatus.rejected);
      expect(find.text('No copies remain'), findsOneWidget);
      expect(find.text('Requested'), findsNothing);
      await show(ReservationStatus.cancelled);
      expect(find.text('Reservation cancelled'), findsOneWidget);
    });
  }

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
