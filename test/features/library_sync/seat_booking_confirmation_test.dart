import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_booking_confirmation_screen.dart';
import 'package:libmate_app/models/seat.dart';

import 'library_test_support.dart';

/// H02 Booking Confirmed: shows the booking it is given and never writes.
void main() {
  late FakeFirebaseFirestore db;
  late StudentLibraryRepository student;

  const seat = SeatRecord(
    id: 'seat-1',
    seatNumber: 'B07',
    zone: 'Row B',
    readingRoom: 'Reading Room A',
    type: SeatType.quietZone,
    status: SeatStatus.available,
  );

  setUp(() async {
    db = await seededFirestore();
    student = studentRepo(db);
    await settle();
  });

  tearDown(() => student.dispose());

  Future<void> pumpConfirmation(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SeatBookingConfirmationScreen(
          library: student,
          seat: seat,
          date: DateTime(2030, 3, 5),
          startHour: 10,
          endHour: 12,
          reservationId: 'abc123XYZ',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the actual booking as confirmed', (tester) async {
    await pumpConfirmation(tester);

    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('Seat booked successfully!'), findsOneWidget);
    expect(find.text('B07'), findsOneWidget);
    expect(find.text('Reading Room A'), findsOneWidget);
    expect(find.text('Tue, 5 Mar 2030'), findsOneWidget);
    expect(find.text('10:00 – 12:00'), findsOneWidget);
    expect(find.text('abc123XYZ'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.textContaining('Pending'), findsNothing);
    expect(find.textContaining('approval'), findsNothing);
  });

  testWidgets('does not create a reservation', (tester) async {
    await pumpConfirmation(tester);

    expect((await db.collection('reservations').get()).docs, isEmpty);
    expect((await db.collection('seatSlots').get()).docs, isEmpty);
  });

  testWidgets('View Reservation opens the seat reservations', (tester) async {
    await pumpConfirmation(tester);

    await tester.tap(find.text('View Reservation'));
    await tester.pumpAndSettle();

    final screen = tester.widget<MyReservationsScreen>(find.byType(MyReservationsScreen));
    expect(screen.showSeats, isTrue);
    expect(find.byType(SeatBookingConfirmationScreen), findsNothing);
  });

  testWidgets('Back to Home returns to the first screen', (tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SeatBookingConfirmationScreen(
                    library: student,
                    seat: seat,
                    date: DateTime(2030, 3, 5),
                    startHour: 10,
                    endHour: 12,
                    reservationId: 'abc123XYZ',
                  ),
                ),
              ),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.byType(SeatBookingConfirmationScreen), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
