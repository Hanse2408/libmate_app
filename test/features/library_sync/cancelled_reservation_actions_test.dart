import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';

import 'library_test_support.dart';

void main() {
  testWidgets(
    'book detail update and cancel keep success feedback out of SnackBars',
    (tester) async {
      tester.view.physicalSize = const Size(440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await seededFirestore();
      await db.collection('reservations').doc('pending').set({
        'studentUid': studentUid,
        'type': 'book',
        'status': 'pending',
        'itemId': 'book',
        'itemName': 'Test Book',
        'date': Timestamp.fromDate(tomorrow()),
        'pickupLocation': 'Main Desk',
      });
      final library = studentRepo(db);
      addTearDown(library.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailsScreen(
            library: library,
            reservationId: 'pending',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Modify Reservation'));
      await tester.tap(find.text('Modify Reservation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(library.notifications.single.type.name, 'bookReservationUpdated');
      await tester.ensureVisible(find.text('Cancel Reservation'));
      await tester.tap(find.text('Cancel Reservation'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel Reservation'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(
        (await db.collection('reservations').doc('pending').get())
            .data()!['status'],
        'cancelled',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('cancelled card hides actions and still opens disabled details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    final doc = db.collection('reservations').doc('cancelled-book');
    await doc.set({
      'studentUid': studentUid,
      'type': 'book',
      'status': 'pending',
      'itemId': 'book',
      'itemName': 'Cancelled Book',
      'date': Timestamp.fromDate(tomorrow()),
    });
    await tester.pumpWidget(
      MaterialApp(home: MyReservationsScreen(library: library)),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete cancelled reservation'), findsNothing);
    expect(find.text('Modify'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await doc.update({'status': 'cancelled'});
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete cancelled reservation'), findsOneWidget);
    expect(find.text('Modify'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.text('Cancelled Book'));
    await tester.pumpAndSettle();
    expect(find.byType(ReservationDetailsScreen), findsOneWidget);
    final modify = find.widgetWithText(ElevatedButton, 'Modify Reservation');
    final cancel = find.widgetWithText(OutlinedButton, 'Reservation Cancelled');
    expect(tester.widget<ElevatedButton>(modify).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(cancel).onPressed, isNull);
    await tester.ensureVisible(modify);
    await tester.tap(modify);
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect((await doc.get()).data()!['status'], 'cancelled');
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(ReservationDetailsScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete cancelled reservation'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Delete Reservation?'), findsOneWidget);
    expect((await doc.get()).exists, isTrue);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect((await doc.get()).exists, isTrue);
    await tester.tap(find.byTooltip('Delete cancelled reservation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Reservation'));
    await tester.pumpAndSettle();
    expect((await doc.get()).exists, isFalse);
    expect(find.text('Cancelled Book'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('deleting a cancelled book saves student and librarian notifications', () async {
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    final doc = db.collection('reservations').doc('delete-notifications');
    await doc.set({
      'studentUid': studentUid,
      'type': 'book',
      'status': 'cancelled',
      'itemId': 'book',
      'itemName': 'Test Book',
      'date': Timestamp.fromDate(tomorrow()),
    });
    final result = await library.deleteCancelledBookReservation(doc.id);
    expect(result.success, isTrue);
    expect((await doc.get()).exists, isFalse);
    final notifications = (await db.collection('notifications').get()).docs;
    final student = notifications.singleWhere((d) => d.data()['type'] == 'reservationDeleted').data();
    final librarian = notifications.singleWhere((d) => d.data()['type'] == 'deleted').data();
    expect(student['recipientUid'], studentUid);
    expect(student['audience'], 'student');
    expect(student['isRead'], isFalse);
    expect(student['reservationId'], isNull);
    expect(librarian['audience'], 'librarian');
    expect(librarian['isRead'], isFalse);
  });

  test('delete refuses active books, cancelled seats and another student records', () async {
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    for (final entry in [
      ('pending-book', studentUid, 'book', 'pending'),
      ('approved-book', studentUid, 'book', 'approved'),
      ('rejected-book', studentUid, 'book', 'rejected'),
      ('cancelled-seat', studentUid, 'seat', 'cancelled'),
      ('other-book', otherStudentUid, 'book', 'cancelled'),
    ]) {
      final doc = db.collection('reservations').doc(entry.$1);
      await doc.set({
        'studentUid': entry.$2, 'type': entry.$3, 'status': entry.$4,
        'itemId': 'book', 'itemName': 'Test',
        'date': Timestamp.fromDate(tomorrow()),
      });
      final result = await library.deleteCancelledBookReservation(entry.$1);
      expect(result.success, isFalse);
      expect((await doc.get()).exists, isTrue);
    }
    expect((await library.deleteCancelledBookReservation('missing')).success, isFalse);
  });

}
