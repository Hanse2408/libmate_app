import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/common/widgets/student_notification_button.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';
import 'library_test_support.dart';

void main() {
  test('delete removes only the selected own notifications', () async {
    final db = await seededFirestore(); final library = studentRepo(db);
    addTearDown(library.dispose);
    for (final id in ['a', 'b']) {
      await db.collection('notifications').doc(id).set({
        'recipientUid': studentUid, 'audience': 'student', 'type': 'reservationApproved', 'isRead': false,
      });
    }
    await db.collection('notifications').doc('theirs').set({
      'recipientUid': otherStudentUid, 'audience': 'student', 'type': 'reservationApproved', 'isRead': false,
    });
    await settle();
    expect((await library.deleteNotifications({'a', 'theirs'})).success, true);
    await settle();
    expect(library.notifications.map((n) => n.id), ['b']);
    expect((await db.collection('notifications').doc('a').get()).exists, false);
    expect((await db.collection('notifications').doc('theirs').get()).exists, true);
  });
  for (final seat in [false, true]) {
    testWidgets('numbered bell opens ${seat ? 'seat' : 'book'} reservation and keeps notification as read', (tester) async {
      tester.view.physicalSize = const Size(440, 1400); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await seededFirestore(); final library = studentRepo(db); addTearDown(library.dispose);
      await db.collection('reservations').doc('reservation').set({
        'studentUid': studentUid, 'type': seat ? 'seat' : 'book', 'status': 'approved',
        'itemId': 'item', 'itemName': 'Actual item', 'date': Timestamp.fromDate(tomorrow()),
        'timeSlot': '09:00 - 11:00',
      });
      for (final id in ['open-me', 'keep-me']) {
        await db.collection('notifications').doc(id).set({
          'recipientUid': studentUid, 'type': !seat ? 'reservationApproved' : id == 'open-me' ? 'seatReservationUpdated' : 'seatBookingConfirmed', 'isRead': false,
          'title': id, 'reservationId': 'reservation', 'itemId': 'item',
        });
      }
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: StudentNotificationButton(library: library))));
      await tester.pumpAndSettle(); expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byTooltip('Notifications')); await tester.pumpAndSettle();
      await tester.tap(find.text('open-me')); await tester.pumpAndSettle();
      expect(seat ? find.byType(SeatReservationDetailsScreen) : find.byType(ReservationDetailsScreen), findsOneWidget);
      expect(library.notifications.map((n) => n.id).toSet(), {'open-me', 'keep-me'});
      expect(library.notifications.singleWhere((n) => n.id == 'open-me').isRead, true);
      Navigator.of(tester.element(seat ? find.byType(SeatReservationDetailsScreen) : find.byType(ReservationDetailsScreen))).pop();
      await tester.pumpAndSettle(); expect(find.text('open-me'), findsOneWidget); expect(find.text('keep-me'), findsOneWidget);
      Navigator.of(tester.element(find.byType(StudentNotificationsScreen))).pop();
      await tester.pumpAndSettle(); expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('long press selects, cancel keeps, delete removes and shows empty state', (tester) async {
    tester.view.physicalSize = const Size(440, 1400); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore(); final library = studentRepo(db); addTearDown(library.dispose);
    for (final (i, id) in ['n1', 'n2', 'n3'].indexed) {
      await db.collection('notifications').doc(id).set({
        'recipientUid': studentUid, 'audience': 'student', 'type': i == 0 ? 'bookCollected' : 'seatBookingConfirmed',
        'isRead': false, 'title': id, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: i))),
      });
    }
    await tester.pumpWidget(MaterialApp(home: StudentNotificationsScreen(library: library)));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('n1')).dy < tester.getTopLeft(find.text('n3')).dy, true);
    await tester.tap(find.text('Mark all read')); await tester.pumpAndSettle();
    expect(library.unreadNotificationCount, 0); expect(find.text('n2'), findsOneWidget);

    await tester.longPress(find.text('n1')); await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('n2')); await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel selection')); await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget); expect(find.text('n3'), findsOneWidget);

    await tester.longPress(find.text('n1')); await tester.pumpAndSettle();
    await tester.tap(find.text('n2')); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete')); await tester.pumpAndSettle();
    expect(find.text('Delete selected notifications?'), findsOneWidget);
    await tester.tap(find.text('Delete')); await tester.pumpAndSettle();
    expect(find.text('n1'), findsNothing); expect(find.text('n2'), findsNothing); expect(find.text('n3'), findsOneWidget);

    await tester.longPress(find.text('n3')); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete')); await tester.pumpAndSettle();
    await tester.tap(find.text('Delete')); await tester.pumpAndSettle();
    expect(find.text('No notifications yet'), findsOneWidget);
  });
}