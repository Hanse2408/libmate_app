import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/notifications/widgets/in_app_notification_banner.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';

import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/models/notification.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';

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
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

Future<StudentLibraryRepository> _setup(
  WidgetTester tester,
  FakeFirebaseFirestore db,
) async {
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

  testWidgets('initial notifications do not pop; new one does, once', (
    t,
  ) async {
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

  testWidgets(
    'book modification writes one notification and shows one dark banner',
    (t) async {
      final db = await seededFirestore();
      await db.collection('reservations').doc('book-r').set({
        'studentUid': studentUid,
        'type': 'book',
        'status': 'pending',
        'itemId': 'book',
        'itemName': 'Dune',
        'date': Timestamp.fromDate(tomorrow()),
      });
      final library = await _setup(t, db);
      await t.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: _Host(library)),
      );
      await t.pumpAndSettle();
      final result = await library.updateBookReservation(
        reservationId: 'book-r',
        pickupDate: tomorrow(),
        pickupLocation: 'Main Desk',
        loanPeriodDays: 14,
      );
      expect(result.success, true);
      await _pumpFor(t);
      final docs = (await db.collection('notifications').get()).docs;
      expect(docs, hasLength(1));
      final data = docs.single.data();
      expect(data['type'], 'bookReservationUpdated');
      expect(data['recipientUid'], studentUid);
      expect(data['reservationId'], 'book-r');
      expect(data['itemId'], 'book');
      expect(data['isRead'], false);
      expect(find.text('Reservation Updated'), findsOneWidget);
      expect(
        find.text('Your reservation for Dune has been updated.'),
        findsOneWidget,
      );
      expect(
        t.widget<Material>(banner).color,
        AppTheme.dark.colorScheme.surface,
      );
      expect(
        t.widget<Text>(find.text('Reservation Updated')).style!.color,
        AppTheme.dark.colorScheme.onSurface,
      );
      expect(find.byType(SnackBar), findsNothing);
      await t.tap(find.text('View'));
      await _pumpFor(t);
      await t.pumpAndSettle();
      expect(find.byType(ReservationDetailsScreen), findsOneWidget);
      expect(
        library.notifications.single.type,
        StudentNotificationType.bookReservationUpdated,
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'availability baseline stays silent; new unread alert pops once',
    (t) async {
      final db = await seededFirestore();
      Map<String, dynamic> alert(String title, {bool read = false}) => {
        'recipientUid': studentUid,
        'type': 'bookAvailable',
        'title': title,
        'message': 'Available now',
        'itemId': 'book',
        'isRead': read,
        'createdAt': Timestamp.now(),
      };
      final user = db.collection('users').doc(studentUid);
      await user.update({
        'bookAvailabilityNotifications': {'old': alert('Old availability')},
      });
      final library = await _setup(t, db);
      expect(banner, findsNothing);
      await user.update({
        'bookAvailabilityNotifications.new': alert('New availability'),
      });
      await _pumpFor(t);
      expect(banner, findsOneWidget);
      expect(find.text('New availability'), findsOneWidget);
      expect(library.notifications, hasLength(2));
      await t.tap(find.byTooltip('Close'));
      await t.pump();
      await user.update({'name': 'Changed profile'});
      await _pumpFor(t);
      expect(banner, findsNothing);
      await user.update({
        'bookAvailabilityNotifications.read': alert('Already read', read: true),
      });
      await _pumpFor(t);
      expect(banner, findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'dark notifications page keeps book filter, selection and deletion',
    (t) async {
      final db = await seededFirestore();
      await _add(db, 'updated', 'bookReservationUpdated');
      final library = studentRepo(db);
      addTearDown(library.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: StudentNotificationsScreen(library: library),
        ),
      );
      await t.pumpAndSettle();
      expect(
        t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppTheme.dark.scaffoldBackgroundColor,
      );
      expect(
        t.widget<Text>(find.text('Title updated')).style!.color,
        AppTheme.dark.colorScheme.onSurface,
      );
      await t.tap(find.byKey(const ValueKey('filter-Type-Books')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('badge-book')), findsOneWidget);
      await t.longPress(find.text('Title updated'));
      await t.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(
        Theme.of(t.element(find.byType(AlertDialog))).brightness,
        Brightness.dark,
      );
      await t.tap(find.widgetWithText(TextButton, 'Delete'));
      await t.pumpAndSettle();
      expect(library.notifications, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

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
    testWidgets(
      'tapping ${seat ? 'seat' : 'book'} banner marks read and opens details',
      (t) async {
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
          seat
              ? find.byType(SeatReservationDetailsScreen)
              : find.byType(ReservationDetailsScreen),
          findsOneWidget,
        );
        expect(library.unreadNotificationCount, 0);
        expect(banner, findsNothing);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
