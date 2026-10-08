import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/manager/data/manager_firestore_repository.dart';
import 'package:libmate_app/features/manager/data/manager_mock_data.dart';
import 'package:libmate_app/features/manager/data/manager_repository.dart';
import 'package:libmate_app/features/manager/providers/manager_scope.dart';
import 'package:libmate_app/features/manager/screens/manager_reading_room_screen.dart';
import 'package:libmate_app/features/manager/screens/manager_reservation_screens.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/seat.dart';
import 'package:libmate_app/models/user.dart';

import 'manager_user_management_test.dart' as support;

final now = DateTime(2026, 10, 9, 10, 30);
ReservationRecord booking(
  String id, {
  ReservationType type = ReservationType.seat,
  String itemId = 'real-seat',
  String itemName = 'Seat Z99',
  ReservationStatus status = ReservationStatus.approved,
  String? time = '10:00 - 12:00',
  DateTime? date,
}) => ReservationRecord(
  id: id,
  type: type,
  status: status,
  studentUid: 'student-uid',
  studentId: 'IT987',
  studentName: 'Real Student',
  studentEmail: 'real@student.test',
  itemId: itemId,
  itemName: itemName,
  date: date ?? now,
  requestedAt: now,
  timeSlot: time,
  pickupLocation: type == ReservationType.book ? 'Main desk' : null,
  loanPeriodDays: type == ReservationType.book ? 14 : null,
);

SeatRecord seat(
  String id, {
  SeatStatus status = SeatStatus.available,
  String room = 'Real room',
}) => SeatRecord(
  id: id,
  seatNumber: id,
  readingRoom: room,
  zone: 'West',
  type: SeatType.individualDesk,
  status: status,
);

Future<void> settle() async =>
    Future<void>.delayed(const Duration(milliseconds: 20));

class MonitoringRepository extends ManagerRepository {
  List<ManagerReservation> records = [];
  List<SeatRecord> inventory = [];
  bool loading = false;
  String? error;
  @override
  List<ManagerReservation> get reservations => records;
  @override
  List<SeatRecord> get seats => inventory;
  @override
  List<ManagerUser> get users => [];
  @override
  List<ManagerNotice> get notices => [];
  @override
  List<int> get policyValues => [3, 5, 7, 2, 7];
  @override
  DateTime get monitoringTime => now;
  @override
  bool get reservationsLoading => loading;
  @override
  bool get seatsLoading => loading;
  @override
  String? get reservationsError => error;
  @override
  String? get seatsError => error;
  @override
  void replaceReservations(List<ManagerReservation> reservations) {
    records = reservations;
    notifyListeners();
  }

  @override
  void replaceUsers(List<ManagerUser> users) {}
  @override
  void replacePolicyValues(List<int> values) {}
}

Future<void> pump(
  WidgetTester tester,
  ManagerRepository repo,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = support.LoginAuth();
  final provider = AuthProvider(
    authRepository: auth,
    userRepository: support.Profiles(AccountStatus.active),
  );
  addTearDown(provider.dispose);
  addTearDown(auth.events.close);
  await tester.pumpWidget(
    MaterialApp(
      home: ManagerScope(
        repository: repo,
        authProvider: provider,
        child: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('live Book and Seat schemas preserve identity, type, dates, times and all statuses', () async {
    final db = FakeFirebaseFirestore();
    await db
        .collection('reservations')
        .doc('real-book')
        .set(
          booking(
            'real-book',
            type: ReservationType.book,
            itemId: 'book-id',
            itemName: 'Actual Book',
            status: ReservationStatus.pending,
            time: null,
          ).toMap(),
        );
    await db
        .collection('reservations')
        .doc('real-seat-reservation')
        .set(booking('real-seat-reservation').toMap());
    final repo = ManagerFirestoreRepository(firestore: db, now: () => now);
    addTearDown(repo.dispose);
    await settle();
    final book = repo.findReservationById('real-book')!;
    expect(book.type, ReservationType.book);
    expect(book.itemId, 'book-id');
    expect(book.book, 'Actual Book');
    expect(book.student, 'Real Student');
    expect(book.studentUid, 'student-uid');
    expect(book.studentEmail, 'real@student.test');
    expect(book.statusLabel, 'Pending');
    expect(book.pickupLocation, 'Main desk');
    expect(book.loanPeriodDays, 14);
    expect(book.time, isEmpty);
    expect(book.seat, isEmpty);
    final seat = repo.findReservationById('real-seat-reservation')!;
    expect(seat.type, ReservationType.seat);
    expect(seat.itemId, 'real-seat');
    expect(seat.seat, 'Z99');
    expect(seat.date, '09 Oct 2026');
    expect(seat.time, '10:00 - 12:00');
    expect(seat.statusLabel, 'Approved');
    for (final status in ReservationStatus.values) {
      final record = ManagerReservation.fromMap('status', {
        ...booking(
          'status',
          type: ReservationType.book,
          status: status,
        ).toMap(),
        'requestedAt': Timestamp.fromDate(now),
      });
      expect(
        record.statusLabel.toLowerCase(),
        status == ReservationStatus.completed ? 'collected' : status.name,
      );
    }
    final missing = ManagerReservation.fromMap('missing-fields', {});
    expect(missing.date, 'Not available');
    expect(missing.bookingDate, isNull);
    expect(missing.type, isNull);
    expect(missing.book, isEmpty);
    expect(missing.status, ManagerReservationStatus.unknown);
  });

  test(
    'live reservations order newest first and update/remove from snapshots',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('reservations').doc('old').set({
        ...booking('old').toMap(),
        'requestedAt': Timestamp.fromDate(
          now.subtract(const Duration(days: 1)),
        ),
      });
      await db.collection('reservations').doc('new').set({
        ...booking('new').toMap(),
        'requestedAt': Timestamp.fromDate(now),
      });
      final repo = ManagerFirestoreRepository(firestore: db, now: () => now);
      addTearDown(repo.dispose);
      await settle();
      expect(repo.reservations.map((r) => r.id), ['new', 'old']);
      await db.collection('reservations').doc('new').delete();
      await settle();
      expect(repo.findReservationById('new'), isNull);
      expect(repo.reservations.single.id, 'old');
    },
  );

  test('inventory, bookings and current seatSlots determine availability without double counting', () async {
    final db = FakeFirebaseFirestore();
    for (final record in [
      seat('booked'),
      seat('locked'),
      seat('occupied', status: SeatStatus.occupied),
      seat('maintenance', status: SeatStatus.maintenance),
      seat('free'),
    ]) {
      await db.collection('seats').doc(record.id).set(record.toMap());
    }
    await db
        .collection('reservations')
        .doc('booking')
        .set(booking('booking', itemId: 'booked').toMap());
    await db.collection('seatSlots').doc('lock').set({
      'seatId': 'locked',
      'date': Timestamp.fromDate(DateTime(2026, 10, 9)),
      'hour': 10,
      'reservationId': 'held-reservation',
    });
    var clock = now;
    final repo = ManagerFirestoreRepository(firestore: db, now: () => clock);
    addTearDown(repo.dispose);
    await settle();
    expect(repo.seatsLoading, false);
    expect(repo.seatsError, isNull);
    expect(
      repo.seats
          .map((s) => repo.seatStatus(s))
          .where((s) => s == SeatStatus.reserved)
          .length,
      2,
    );
    expect(
      repo.seats
          .map((s) => repo.seatStatus(s))
          .where((s) => s == SeatStatus.available)
          .length,
      1,
    );
    clock = now.add(const Duration(hours: 3));
    expect(
      repo.seatStatus(repo.seats.firstWhere((s) => s.id == 'locked')),
      SeatStatus.available,
    );
    expect(
      repo.seatStatus(repo.seats.firstWhere((s) => s.id == 'booked')),
      SeatStatus.available,
    );
  });

  testWidgets('list and details reflect live Book/Seat records and deletion', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final repo = ManagerFirestoreRepository(firestore: db, now: () => now);
    await db
        .collection('reservations')
        .doc('book')
        .set(
          booking(
            'book',
            type: ReservationType.book,
            itemName: 'Real Book',
            time: null,
          ).toMap(),
        );
    await db
        .collection('reservations')
        .doc('seat')
        .set(booking('seat').toMap());
    await pump(tester, repo, const ManagerReservationsScreen());
    expect(find.text('Book: Real Book'), findsOneWidget);
    expect(find.text('Seat: Seat Z99'), findsOneWidget);
    expect(find.text('Real Student'), findsNWidgets(2));
    await pump(
      tester,
      repo,
      const ManagerReservationDetailsScreen(reservationId: 'book'),
    );
    expect(find.text('Book Information'), findsOneWidget);
    expect(find.text('Main desk'), findsOneWidget);
    await pump(
      tester,
      repo,
      const ManagerReservationDetailsScreen(reservationId: 'seat'),
    );
    expect(find.text('Seat Information'), findsOneWidget);
    expect(find.text('Book Information'), findsNothing);
    expect(find.textContaining('ISBN'), findsNothing);
    expect(find.text('10:00 - 12:00'), findsOneWidget);
    await db.collection('reservations').doc('seat').delete();
    await tester.pumpAndSettle();
    expect(find.text('Reservation not found'), findsOneWidget);
    expect(find.text('Real Book'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  testWidgets('empty reservations and seat inventory never inject examples', (
    tester,
  ) async {
    final repo = ManagerFirestoreRepository(
      firestore: FakeFirebaseFirestore(),
      now: () => now,
    );
    await pump(tester, repo, const ManagerReservationsScreen());
    expect(find.text('No reservations found'), findsOneWidget);
    expect(find.textContaining('RES-'), findsNothing);
    await pump(tester, repo, const ManagerReadingRoomScreen());
    expect(find.text('No seat data available'), findsOneWidget);
    expect(find.text('B12'), findsNothing);
    expect(find.text('70%'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  testWidgets(
    'Reading Room calculates 40 total, 12 reserved, 28 available, 30 percent',
    (tester) async {
      final repo = MonitoringRepository();
      addTearDown(repo.dispose);
      repo.inventory = [
        for (var i = 0; i < 40; i++)
          seat(
            'actual-$i',
            status: i < 12 ? SeatStatus.reserved : SeatStatus.available,
          ),
      ];
      await pump(tester, repo, const ManagerReadingRoomScreen());
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('12 / 40'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('actual-0'), findsOneWidget);
      expect(find.text('B12'), findsNothing);
      await tester.tap(find.text('actual-0'));
      await tester.pumpAndSettle();
      expect(find.text('Seat actual-0'), findsOneWidget);
      repo.inventory.removeAt(0);
      repo.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Seat not found'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('room filters and maintenance do not inflate occupancy', (
    tester,
  ) async {
    final repo = MonitoringRepository();
    addTearDown(repo.dispose);
    repo.inventory = [
      seat('reserved', status: SeatStatus.reserved),
      seat('occupied', status: SeatStatus.occupied),
      seat('maintenance', status: SeatStatus.maintenance),
      seat('available'),
      seat('other', room: 'Other room'),
    ];
    await pump(tester, repo, const ManagerReadingRoomScreen());
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    await tester.tap(find.text('All rooms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Real room').last);
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('other'), findsNothing);
  });

  testWidgets('loading and repository error states stay honest', (
    tester,
  ) async {
    final repo = MonitoringRepository()..loading = true;
    addTearDown(repo.dispose);
    // pumpAndSettle cannot settle an indeterminate progress indicator.
    final auth = support.LoginAuth();
    final provider = AuthProvider(
      authRepository: auth,
      userRepository: support.Profiles(AccountStatus.active),
    );
    addTearDown(provider.dispose);
    addTearDown(auth.events.close);
    for (final screen in [
      const ManagerReservationsScreen(),
      const ManagerReadingRoomScreen(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerScope(
            repository: repo,
            authProvider: provider,
            child: screen,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.error = 'Unable to load monitoring data.';
      repo.notifyListeners();
      await tester.pump();
      expect(find.text('Unable to load monitoring data.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      repo.error = null;
    }
  });

  test(
    'invalid reservation data reports error and later snapshot recovers',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('reservations').doc('bad').set({'date': 'invalid'});
      final repo = ManagerFirestoreRepository(firestore: db, now: () => now);
      addTearDown(repo.dispose);
      await settle();
      expect(repo.reservationsLoading, false);
      expect(repo.reservationsError, contains('Unable to read'));
      await db.collection('reservations').doc('bad').delete();
      await settle();
      expect(repo.reservationsError, isNull);
      expect(repo.reservations, isEmpty);
    },
  );

  testWidgets(
    'missing routes never fall back; unsupported conflict routes cannot report success',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = support.LoginAuth();
      final provider = AuthProvider(
        authRepository: auth,
        userRepository: support.Profiles(AccountStatus.active),
      );
      final repo = MonitoringRepository()
        ..records = [
          ManagerReservation.fromMap('real', {
            ...booking('real').toMap(),
            'date': Timestamp.fromDate(now),
            'requestedAt': Timestamp.fromDate(now),
          }),
        ];
      final router = AppRouter(
        provider,
        createManagerRepository: () => repo,
      ).router;
      addTearDown(router.dispose);
      addTearDown(provider.dispose);
      addTearDown(auth.events.close);
      addTearDown(repo.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await provider.signIn(email: 'manager@test.com', password: 'secret123');
      await tester.pumpAndSettle();
      router.go(AppRoutes.managerReservationDetails);
      await tester.pumpAndSettle();
      expect(find.text('Reservation not found'), findsOneWidget);
      router.go(AppRoutes.managerReservationDetails, extra: 'missing');
      await tester.pumpAndSettle();
      expect(find.text('Reservation not found'), findsOneWidget);
      router.go('${AppRoutes.managerReservationDetails}?id=real');
      await tester.pumpAndSettle();
      expect(find.text('Seat Information'), findsOneWidget);
      for (final path in [
        AppRoutes.managerConflict,
        AppRoutes.managerReassignSeat,
        AppRoutes.managerResolved,
      ]) {
        router.go(path, extra: 'invented-seat');
        await tester.pumpAndSettle();
        expect(find.text('No conflicts detected'), findsOneWidget);
        expect(find.textContaining('RES-'), findsNothing);
        expect(find.text('Reassign Seat'), findsNothing);
        expect(find.text('Confirm Reassignment'), findsNothing);
        expect(find.text('Conflict Resolved'), findsNothing);
        expect(find.textContaining('(demo)'), findsNothing);
      }
      final result = await repo.resolveConflict(
        'real',
        newSeat: 'invented-seat',
      );
      expect(result.success, false);
      expect(repo.reservations.single.itemId, 'real-seat');
    },
  );
}
