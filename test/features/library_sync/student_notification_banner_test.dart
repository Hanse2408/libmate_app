import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/notifications/widgets/in_app_notification_banner.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';

import 'library_test_support.dart';

class _Host extends StatefulWidget {
  const _Host(this.library);
  final StudentLibraryRepository library;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final InAppNotificationBanner banner;
  @override
  void initState() {
    super.initState();
    banner = InAppNotificationBanner(context: context, library: widget.library);
  }

  @override
  void dispose() {
    banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home'));
}

Future<void> _add(
  FakeFirebaseFirestore db,
  String id,
  String type, {
  String? reservationId,
  String? itemId,
  bool read = false,
}) {
  return db.collection('notifications').doc(id).set({
    'recipientUid': studentUid,
    'audience': 'student',
    'type': type,
    'title': 'Title $id',
    'message': 'Message $id',
    'isRead': read,
    'createdAt': Timestamp.now(),
    'reservationId': ?reservationId,
    'itemId': ?itemId,
  });
}

Future<void> _pumpFor(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

Future<StudentLibraryRepository> _setup(WidgetTester tester, FakeFirebaseFirestore db) async {
  tester.view.physicalSize = const Size(440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final library = studentRepo(db);
  addTearDown(library.dispose);
  await tester.pumpWidget(MaterialApp(home: _Host(library)));
  await _pumpFor(tester);
  return library;
}

void main() {
  final banner = find.byKey(const ValueKey('in-app-banner'));

  testWidgets('initial notifications do not pop; new one does, once', (t) async {
    final db = await seededFirestore();
    await _add(db, 'old1', 'reservationApproved');
    await _add(db, 'old2', 'bookReturned');
    final library = await _setup(t, db);
    expect(library.unreadNotificationCount, 2);
    expect(banner, findsNothing);

    await _add(db, 'new1', 'reservationApproved');
    await _pumpFor(t);
    expect(banner, findsOneWidget);
    expect(find.text('Title new1'), findsOneWidget);
    expect(find.text('Message new1'), findsOneWidget);
    expect(library.unreadNotificationCount, 3);

    // Refresh caused by an unrelated change must not re-pop.
    await t.tap(find.byTooltip('Close'));
    await t.pump();
    await db.collection('notifications').doc('old1').update({'isRead': true});
    await _pumpFor(t);
    expect(banner, findsNothing);
    expect(library.unreadNotificationCount, 2);
  });

  testWidgets('auto-dismisses and stays unread', (t) async {
    final db = await seededFirestore();
    final library = await _setup(t, db);
    await _add(db, 'n', 'reservationApproved');
    await _pumpFor(t);
    expect(banner, findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    expect(banner, findsNothing);
    expect(library.unreadNotificationCount, 1);
  });

  testWidgets('close dismisses without marking read', (t) async {
    final db = await seededFirestore();
    final library = await _setup(t, db);
    await _add(db, 'n', 'reservationApproved');
    await _pumpFor(t);
    await t.tap(find.byTooltip('Close'));
    await t.pump();
    expect(banner, findsNothing);
    expect(library.unreadNotificationCount, 1);
  });

  testWidgets('multiple arrivals are queued one at a time', (t) async {
    final db = await seededFirestore();
    await _setup(t, db);
    await _add(db, 'a', 'reservationApproved');
    await _add(db, 'b', 'reservationApproved');
    await _pumpFor(t);
    expect(banner, findsOneWidget);
    final first = find.textContaining('Title ').evaluate().length;
    expect(first, 1);
    await t.pump(const Duration(seconds: 5));
    expect(banner, findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    expect(banner, findsNothing);
  });

  for (final seat in [true, false]) {
    testWidgets('tapping ${seat ? 'seat' : 'book'} banner marks read and opens details', (t) async {
      final db = await seededFirestore();
      await db.collection('reservations').doc('r').set({
        'studentUid': studentUid,
        'type': seat ? 'seat' : 'book',
        'status': 'approved',
        'itemId': 'item',
        'itemName': 'Item',
        'date': Timestamp.fromDate(tomorrow()),
        'timeSlot': '09:00 - 11:00',
      });
      final library = await _setup(t, db);
      await _add(
        db,
        'n',
        seat ? 'seatBookingConfirmed' : 'reservationApproved',
        reservationId: 'r',
        itemId: 'item',
      );
      await _pumpFor(t);
      expect(library.unreadNotificationCount, 1);
      await t.tap(find.text('View'));
      await _pumpFor(t);
      await t.pumpAndSettle();
      expect(
        seat ? find.byType(SeatReservationDetailsScreen) : find.byType(ReservationDetailsScreen),
        findsOneWidget,
      );
      expect(library.unreadNotificationCount, 0);
      expect(banner, findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
