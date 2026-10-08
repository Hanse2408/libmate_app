import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/common/widgets/student_notification_button.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';
import 'library_test_support.dart';

void main() {
  testWidgets('read notifications stay hidden and dismiss clears the badge without navigation', (tester) async {
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    for (final id in ['old-read', 'new-alert', 'other-alert']) {
      await db.collection('notifications').doc(id).set({
        'recipientUid': studentUid, 'type': 'reservationApproved',
        'isRead': id == 'old-read', 'title': id,
      });
    }
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StudentNotificationButton(library: library))));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('old-read'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('dismiss-new-alert')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentNotificationsScreen), findsOneWidget);
    expect(find.text('new-alert'), findsNothing);
    expect(find.text('other-alert'), findsOneWidget);
    expect(library.unreadNotificationCount, 1);
    expect((await db.collection('notifications').doc('new-alert').get()).data()!['isRead'], true);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.text('other-alert'), findsNothing);
    expect(find.text('You have no new notifications.'), findsOneWidget);
    expect(library.unreadNotificationCount, 0);
    Navigator.of(tester.element(find.byType(StudentNotificationsScreen))).pop();
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, false);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('You have no new notifications.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('opened notifications disappear persistently and only for their recipient', () async {
    final db = await seededFirestore(); final library = studentRepo(db);
    addTearDown(library.dispose);
    await db.collection('notifications').doc('notification').set({
      'recipientUid': studentUid, 'type': 'reservationApproved', 'isRead': false,
    });
    await settle(); expect(library.unreadNotificationCount, 1);
    expect((await library.dismissNotification('notification')).success, true);
    await settle(); expect(library.notifications, isEmpty); expect(library.unreadNotificationCount, 0);
    expect((await db.collection('notifications').doc('notification').get()).data()!['isRead'], true);
    final reopened = studentRepo(db); addTearDown(reopened.dispose); await settle();
    expect(reopened.notifications, isEmpty);
    expect((await library.dismissNotification('notification')).success, true);
  });

  for (final seat in [false, true]) {
    testWidgets('numbered bell opens ${seat ? 'seat' : 'book'} reservation and removes notification', (tester) async {
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
          'recipientUid': studentUid, 'type': 'reservationApproved', 'isRead': false,
          'title': id, 'reservationId': 'reservation', 'itemId': 'item',
        });
      }
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: StudentNotificationButton(library: library))));
      await tester.pumpAndSettle(); expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byTooltip('Notifications')); await tester.pumpAndSettle();
      await tester.tap(find.text('open-me')); await tester.pumpAndSettle();
      expect(seat ? find.byType(SeatReservationDetailsScreen) : find.byType(ReservationDetailsScreen), findsOneWidget);
      expect(library.notifications.map((n) => n.id), ['keep-me']);
      Navigator.of(tester.element(seat ? find.byType(SeatReservationDetailsScreen) : find.byType(ReservationDetailsScreen))).pop();
      await tester.pumpAndSettle(); expect(find.text('open-me'), findsNothing); expect(find.text('keep-me'), findsOneWidget);
      Navigator.of(tester.element(find.byType(StudentNotificationsScreen))).pop();
      await tester.pumpAndSettle(); expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
