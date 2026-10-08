import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/core/services/push_messaging_client.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/notifications/providers/student_push_controller.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';
import 'package:libmate_app/features/student/notifications/widgets/in_app_notification_banner.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';

import 'library_test_support.dart';

class _FakeClient implements PushMessagingClient {
  bool permission = true;
  String? token = 'tok-1';
  bool throwOnDelete = false;
  PushPayload? initial;
  int permissionCalls = 0;
  bool deleted = false;
  final refresh = StreamController<String>.broadcast();
  final message = StreamController<PushPayload>.broadcast();
  final opened = StreamController<PushPayload>.broadcast();

  @override
  Future<bool> ensurePermission() async {
    permissionCalls++;
    return permission;
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async {
    if (throwOnDelete) throw Exception('boom');
    deleted = true;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushPayload> get onMessage => message.stream;
  @override
  Stream<PushPayload> get onMessageOpenedApp => opened.stream;
  @override
  Future<PushPayload?> getInitialMessage() async => initial;
}

class _Host extends StatefulWidget {
  const _Host(this.library, this.client, {this.withBanner = false});
  final StudentLibraryRepository library;
  final _FakeClient client;
  final bool withBanner;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final StudentPushController push;
  InAppNotificationBanner? banner;
  @override
  void initState() {
    super.initState();
    push = StudentPushController(
      context: context,
      library: widget.library,
      client: widget.client,
      waitForNotifications: const Duration(milliseconds: 200),
    );
    if (widget.withBanner) {
      banner = InAppNotificationBanner(context: context, library: widget.library);
    }
  }

  @override
  void dispose() {
    banner?.dispose();
    push.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home'));
}

Future<void> _pumpFor(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _addNotification(
  FakeFirebaseFirestore db,
  String id,
  String type, {
  String? reservationId,
  String? itemId,
}) {
  return db.collection('notifications').doc(id).set({
    'recipientUid': studentUid,
    'audience': 'student',
    'type': type,
    'title': 'Title $id',
    'message': 'Message $id',
    'isRead': false,
    'createdAt': Timestamp.now(),
    'reservationId': ?reservationId,
    'itemId': ?itemId,
  });
}

Future<List<dynamic>> _tokens(FakeFirebaseFirestore db) async {
  final doc = await db.collection('users').doc(studentUid).get();
  return (doc.data()!['fcmTokens'] as List?) ?? const [];
}

Future<StudentLibraryRepository> _setup(
  WidgetTester t,
  FakeFirebaseFirestore db,
  _FakeClient client, {
  bool withBanner = false,
}) async {
  t.view.physicalSize = const Size(440, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final library = studentRepo(db);
  addTearDown(library.dispose);
  await t.pumpWidget(MaterialApp(home: _Host(library, client, withBanner: withBanner)));
  await _pumpFor(t);
  return library;
}

Future<void> _addReservation(FakeFirebaseFirestore db, {required bool seat}) {
  return db.collection('reservations').doc('r').set({
    'studentUid': studentUid,
    'type': seat ? 'seat' : 'book',
    'status': 'approved',
    'itemId': 'item',
    'itemName': 'Item',
    'date': Timestamp.fromDate(tomorrow()),
    'timeSlot': '09:00 - 11:00',
  });
}

void main() {
  group('token storage', () {
    testWidgets('stores token once, keeps other fields, no duplicates', (t) async {
      final db = await seededFirestore();
      final client = _FakeClient();
      final library = await _setup(t, db, client);
      expect(await _tokens(db), ['tok-1']);
      await library.addFcmToken('tok-1');
      expect(await _tokens(db), ['tok-1']);
      final data = (await db.collection('users').doc(studentUid).get()).data()!;
      expect(data['name'], 'Nethmi Perera');
      expect(data['role'], 'student');
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('refresh adds the new token and drops the old one', (t) async {
      final db = await seededFirestore();
      final client = _FakeClient();
      await _setup(t, db, client);
      client.refresh.add('tok-2');
      await _pumpFor(t);
      expect(await _tokens(db), ['tok-2']);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('permission denied stores nothing and does not crash', (t) async {
      final db = await seededFirestore();
      final client = _FakeClient()..permission = false;
      await _setup(t, db, client);
      expect(client.permissionCalls, 1);
      expect(await _tokens(db), isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
    });
  });

  group('logout', () {
    testWidgets('removes only this device token', (t) async {
      final db = await seededFirestore();
      await db.collection('users').doc(studentUid).update({
        'fcmTokens': ['other-device'],
      });
      final client = _FakeClient();
      final library = await _setup(t, db, client);
      expect(await _tokens(db), ['other-device', 'tok-1']);
      await t.runAsync(library.signOut);
      expect(await _tokens(db), ['other-device']);
      expect(client.deleted, isTrue);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('sign-out succeeds even when cleanup fails', (t) async {
      final db = await seededFirestore();
      final client = _FakeClient()..throwOnDelete = true;
      var signedOut = false;
      t.view.physicalSize = const Size(440, 1400);
      addTearDown(t.view.reset);
      final library = StudentLibraryRepository(
        firestore: db,
        student: const StudentIdentity(
          uid: studentUid,
          studentId: 'IT23004512',
          name: 'Nethmi Perera',
          email: 'nethmi@student.test',
        ),
        onSignOut: () async => signedOut = true,
      );
      addTearDown(library.dispose);
      await t.pumpWidget(MaterialApp(home: _Host(library, client)));
      await _pumpFor(t);
      await t.runAsync(library.signOut);
      expect(signedOut, isTrue);
      await t.pumpWidget(const SizedBox.shrink());
    });
  });

  group('foreground', () {
    testWidgets('message creates no banner and marks nothing read', (t) async {
      final db = await seededFirestore();
      await _addNotification(db, 'old', 'reservationApproved');
      final client = _FakeClient();
      final library = await _setup(t, db, client, withBanner: true);
      client.message.add(const PushPayload(notificationId: 'old'));
      await _pumpFor(t);
      expect(find.byKey(const ValueKey('in-app-banner')), findsNothing);
      expect(library.unreadNotificationCount, 1);
      await t.pumpWidget(const SizedBox.shrink());
    });
  });

  group('tap handling', () {
    for (final seat in [true, false]) {
      testWidgets('${seat ? 'seat' : 'book'} tap marks read and navigates', (t) async {
        final db = await seededFirestore();
        await _addReservation(db, seat: seat);
        await _addNotification(
          db,
          'n',
          seat ? 'seatBookingConfirmed' : 'reservationApproved',
          reservationId: 'r',
          itemId: 'item',
        );
        final client = _FakeClient();
        final library = await _setup(t, db, client);
        expect(library.unreadNotificationCount, 1);
        client.opened.add(const PushPayload(notificationId: 'n', reservationId: 'r'));
        await _pumpFor(t);
        await t.pumpAndSettle();
        expect(
          seat ? find.byType(SeatReservationDetailsScreen) : find.byType(ReservationDetailsScreen),
          findsOneWidget,
        );
        expect(library.unreadNotificationCount, 0);
        await t.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('initial (terminated) message is handled', (t) async {
      final db = await seededFirestore();
      await _addReservation(db, seat: true);
      await _addNotification(db, 'n', 'seatBookingConfirmed', reservationId: 'r', itemId: 'item');
      final client = _FakeClient()
        ..initial = const PushPayload(notificationId: 'n', reservationId: 'r');
      final library = await _setup(t, db, client);
      await t.pumpAndSettle();
      expect(find.byType(SeatReservationDetailsScreen), findsOneWidget);
      expect(library.unreadNotificationCount, 0);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('malformed payload opens the notifications centre safely', (t) async {
      final db = await seededFirestore();
      final client = _FakeClient();
      await _setup(t, db, client);
      client.opened.add(PushPayload.fromData({'notificationId': 5, 'x': 1}));
      await _pumpFor(t);
      await t.pumpAndSettle();
      expect(find.byType(StudentNotificationsScreen), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('unknown notification id does not crash or mark anything', (t) async {
      final db = await seededFirestore();
      await _addNotification(db, 'keep', 'reservationApproved');
      final client = _FakeClient();
      final library = await _setup(t, db, client);
      client.opened.add(const PushPayload(notificationId: 'missing'));
      await _pumpFor(t);
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
      expect(tester(t), isNull);
      expect(library.unreadNotificationCount, 1);
      await t.pumpWidget(const SizedBox.shrink());
    });
  });

  test('PushPayload parses safely', () {
    expect(PushPayload.fromData(null).isEmpty, isTrue);
    expect(PushPayload.fromData('x').isEmpty, isTrue);
    final p = PushPayload.fromData({
      'type': 'seatBookingConfirmed',
      'notificationId': ' n1 ',
      'reservationId': 3,
      'itemId': '',
    });
    expect(p.type, 'seatBookingConfirmed');
    expect(p.notificationId, 'n1');
    expect(p.reservationId, isNull);
    expect(p.itemId, isNull);
  });
}

Object? tester(WidgetTester t) => t.takeException();
