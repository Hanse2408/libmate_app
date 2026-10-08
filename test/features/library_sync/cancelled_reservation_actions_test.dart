import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'library_test_support.dart';

void main() {
  testWidgets('cancelled card hides actions and still opens disabled details', (tester) async {
    tester.view.physicalSize = const Size(440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    final doc = db.collection('reservations').doc('cancelled-book');
    await doc.set({
      'studentUid': studentUid, 'type': 'book', 'status': 'pending',
      'itemId': 'book', 'itemName': 'Cancelled Book',
      'date': Timestamp.fromDate(tomorrow()),
    });
    await tester.pumpWidget(MaterialApp(home: MyReservationsScreen(library: library)));
    await tester.pumpAndSettle();
    expect(find.text('Modify'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await doc.update({'status': 'cancelled'});
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(const SizedBox.shrink());
  });
}