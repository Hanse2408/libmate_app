import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';

import 'library_test_support.dart';

void main() {
  testWidgets('search, type and status filters work alone and together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);

    for (final (id, type) in [
      ('seat-reservation', 'seat'),
      ('book-reservation', 'book'),
    ]) {
      await db.collection('reservations').doc(id).set({
        'studentUid': studentUid,
        'type': type,
        'status': 'cancelled',
        'itemId': id,
        'itemName': id,
        'date': Timestamp.fromDate(tomorrow()),
        'timeSlot': '09:00 - 10:00',
      });
    }
    final now = DateTime.now();
    final rows = [
      ('n-book', 'bookCollected', 'Collected Dune', true, 0, null),
      ('n-seat', 'seatBookingConfirmed', 'Seat B03 booked', false, 1, null),
      ('n-seat-upd', 'seatReservationUpdated', 'Seat moved', true, 2, null),
      (
        'n-cancel-seat',
        'reservationCancelled',
        'Cancelled seat',
        false,
        3,
        'seat-reservation',
      ),
      (
        'n-cancel-book',
        'reservationCancelled',
        'Cancelled book',
        false,
        4,
        'book-reservation',
      ),
    ];
    for (final (id, type, title, read, ago, res) in rows) {
      await db.collection('notifications').doc(id).set({
        'recipientUid': studentUid,
        'audience': 'student',
        'type': type,
        'title': title,
        'message': 'Message for $id',
        'isRead': read,
        'reservationId': res,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: ago))),
      });
    }
    await tester.pumpWidget(
      MaterialApp(home: StudentNotificationsScreen(library: library)),
    );
    await tester.pumpAndSettle();

    Future<void> tapChip(String group, String text) async {
      await tester.tap(find.byKey(ValueKey('filter-$group-$text')));
      await tester.pumpAndSettle();
    }

    void shows(List<String> titles) {
      for (final t in [
        'Collected Dune',
        'Seat B03 booked',
        'Seat moved',
        'Cancelled seat',
        'Cancelled book',
      ]) {
        expect(
          find.text(t),
          titles.contains(t) ? findsOneWidget : findsNothing,
        );
      }
    }

    // Order: newest first.
    expect(
      tester.getTopLeft(find.text('Collected Dune')).dy <
          tester.getTopLeft(find.text('Cancelled book')).dy,
      isTrue,
    );
    shows([
      'Collected Dune',
      'Seat B03 booked',
      'Seat moved',
      'Cancelled seat',
      'Cancelled book',
    ]);

    await tapChip('Type', 'Books');
    shows(['Collected Dune', 'Cancelled book']);
    await tapChip('Type', 'Seats');
    shows(['Seat B03 booked', 'Seat moved', 'Cancelled seat']);

    await tapChip('Status', 'Unread');
    shows(['Seat B03 booked', 'Cancelled seat']);
    await tapChip('Status', 'Read');
    shows(['Seat moved']);

    await tapChip('Status', 'All');
    shows(['Seat B03 booked', 'Seat moved', 'Cancelled seat']);
    await tapChip('Type', 'All');
    expect(find.text('Collected Dune'), findsOneWidget);
  });

  testWidgets('search is case-insensitive, combines with filters, clears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    for (final (id, type, title, msg, read) in [
      (
        'a',
        'seatBookingConfirmed',
        'Seat Booking Confirmed',
        'Seat B03 reserved',
        false,
      ),
      ('b', 'bookCollected', 'Book Collected', 'Dune collected', false),
      (
        'c',
        'seatReservationUpdated',
        'Reservation Updated',
        'booking changed',
        true,
      ),
    ]) {
      await db.collection('notifications').doc(id).set({
        'recipientUid': studentUid,
        'audience': 'student',
        'type': type,
        'title': title,
        'message': msg,
        'isRead': read,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await tester.pumpWidget(
      MaterialApp(home: StudentNotificationsScreen(library: library)),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Search'), findsOneWidget);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('notification-search'));
    await tester.enterText(field, '  BOOKING ');
    await tester.pumpAndSettle();
    expect(find.text('Seat Booking Confirmed'), findsOneWidget); // title
    expect(find.text('Reservation Updated'), findsOneWidget); // message
    expect(find.text('Book Collected'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('filter-Status-Unread')));
    await tester.pumpAndSettle();
    expect(find.text('Seat Booking Confirmed'), findsOneWidget);
    expect(find.text('Reservation Updated'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('filter-Type-Books')));
    await tester.pumpAndSettle();
    expect(find.text('No matching notifications'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Book Collected'), findsOneWidget);
    expect(find.text('Seat Booking Confirmed'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('filter-Status-Read')));
    await tester.pumpAndSettle();
    expect(find.text('No read notifications'), findsOneWidget);
  });

  testWidgets('shows date sections, badges and unread dots', (tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await seededFirestore();
    final library = studentRepo(db);
    addTearDown(library.dispose);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final (id, type, title, read, at) in [
      (
        't',
        'seatBookingConfirmed',
        'Seat today',
        false,
        today.add(const Duration(seconds: 1)),
      ),
      (
        'y',
        'bookCollected',
        'Book yesterday',
        true,
        today.subtract(const Duration(hours: 5)),
      ),
      (
        'e',
        'bookReturned',
        'Book earlier',
        true,
        today.subtract(const Duration(days: 4)),
      ),
    ]) {
      await db.collection('notifications').doc(id).set({
        'recipientUid': studentUid,
        'audience': 'student',
        'type': type,
        'title': title,
        'message': 'm',
        'isRead': read,
        'createdAt': Timestamp.fromDate(at),
      });
    }
    await tester.pumpWidget(
      MaterialApp(home: StudentNotificationsScreen(library: library)),
    );
    await tester.pumpAndSettle();

    double y(String s) => tester.getTopLeft(find.text(s)).dy;
    expect(y('Today') < y('Seat today'), isTrue);
    expect(y('Seat today') < y('Yesterday'), isTrue);
    expect(y('Yesterday') < y('Book yesterday'), isTrue);
    expect(y('Book yesterday') < y('Earlier'), isTrue);
    expect(y('Earlier') < y('Book earlier'), isTrue);
    expect(find.byKey(const ValueKey('badge-seat')), findsOneWidget);
    expect(find.byKey(const ValueKey('badge-book')), findsNWidgets(2));
    expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);
  });
}
