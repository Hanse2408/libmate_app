import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart'
    show MyReservationsScreen;
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/seat.dart';

import 'library_test_support.dart';

/// H04 Seat Reservation Details, reached from My Reservations > Seats.
void main() {
  late FakeFirebaseFirestore db;
  late LibrarianFirestoreRepository librarian;
  late StudentLibraryRepository student;
  late SeatRecord seat;

  late WidgetTester tester;

  /// Under testWidgets the clock is fake, so Firestore listeners are
  /// delivered by pumping the tester (not by settle()).
  Future<void> flush() => tester.pumpAndSettle();

  /// testWidgets plus a librarian-added seat for the student to book.
  void widgetTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (t) async {
      tester = t;
      db = await seededFirestore();
      librarian = librarianRepo(db, FakeImageStorage());
      student = studentRepo(db);
      addTearDown(librarian.dispose);
      addTearDown(student.dispose);
      await librarian.addSeat(
        seatNumber: 'A01',
        zone: 'Row A',
        readingRoom: 'Reading Room A',
        type: SeatType.quietZone,
        hasPowerOutlet: true,
      );
      await flush();
      seat = librarian.seats.single;
      await body(t);
    });
  }

  Future<String> book({int start = 10, int end = 12}) async {
    final result = await student.bookSeat(
      seat: seat,
      date: tomorrow(),
      startHour: start,
      endHour: end,
    );
    expect(result.success, isTrue, reason: result.message);
    await flush();
    return result.reservationId!;
  }

  /// A booking whose time has passed (written directly, as the app cannot book the past).
  Future<String> pastBooking() async {
    final yesterday = tomorrow().subtract(const Duration(days: 2));
    final doc = await db
        .collection('reservations')
        .add(
          ReservationRecord(
            id: '',
            type: ReservationType.seat,
            status: ReservationStatus.approved,
            studentUid: studentUid,
            studentId: 'IT23004512',
            studentName: 'Nethmi Perera',
            studentEmail: 'nethmi@student.test',
            itemId: seat.id,
            itemName: 'Seat A01',
            requestedAt: yesterday,
            date: yesterday,
            timeSlot: '10:00 - 12:00',
          ).toMap(),
        );
    await flush();
    return doc.id;
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(WidgetTester tester, String id) => pump(
    tester,
    SeatReservationDetailsScreen(
      library: student,
      reservation: student.myReservations.firstWhere((r) => r.id == id),
    ),
  );

  widgetTest('tapping a seat reservation card opens H04 with its data', (
    tester,
  ) async {
    final id = await book();
    await pump(tester, MyReservationsScreen(library: student, showSeats: true));

    await tester.tap(find.text('Seat A01'));
    await tester.pumpAndSettle();

    expect(find.byType(SeatReservationDetailsScreen), findsOneWidget);
    expect(find.text('Reservation Details'), findsOneWidget);
    expect(find.text('A01'), findsOneWidget);
    expect(find.text('Reading Room A'), findsOneWidget);
    expect(find.text('Row A'), findsOneWidget);
    expect(find.text('Quiet Zone'), findsOneWidget);
    expect(find.text('Power outlet'), findsOneWidget);
    expect(find.text('10:00 – 12:00'), findsOneWidget);
    expect(find.text(id), findsOneWidget);
    expect(find.text('Note'), findsNothing); // empty optional values are hidden

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(MyReservationsScreen), findsOneWidget);
  });

  widgetTest('an approved booking shows Confirmed with Modify and Cancel', (
    tester,
  ) async {
    final id = await book();
    await openDetails(tester, id);

    expect(find.text('Confirmed'), findsNWidgets(2)); // chip and receipt row
    expect(find.text('Approved'), findsNothing);
    expect(find.text('Modify Reservation'), findsOneWidget);
    expect(find.text('Cancel Reservation'), findsOneWidget);
  });

  widgetTest('cancelling asks first, then cancels and frees the seat', (
    tester,
  ) async {
    final id = await book();
    await openDetails(tester, id);

    await tester.tap(find.text('Cancel Reservation'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Reservation?'), findsOneWidget);

    // Keep: nothing changes.
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(
      (await db.collection('reservations').doc(id).get()).data()!['status'],
      'approved',
    );
    expect((await db.collection('seatSlots').get()).docs, hasLength(2));

    await tester.tap(find.text('Cancel Reservation'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel Reservation'),
      ),
    );
    await tester.pumpAndSettle();

    final doc = await db.collection('reservations').doc(id).get();
    expect(doc.exists, isTrue); // kept, not deleted
    expect(doc.data()!['status'], 'cancelled');
    expect((await db.collection('seatSlots').get()).docs, isEmpty);
    expect(find.text('Seat reservation cancelled.'), findsOneWidget);
    expect(find.text('Cancelled'), findsNWidgets(2));
    expect(find.text('Modify Reservation'), findsNothing);
    expect(find.text('Cancel Reservation'), findsNothing);

    // The same seat and time can be booked again.
    final other = studentRepo(db, uid: otherStudentUid);
    final again = await other.bookSeat(
      seat: seat,
      date: tomorrow(),
      startHour: 10,
      endHour: 12,
    );
    expect(again.success, isTrue, reason: again.message);
    other.dispose();
  });

  widgetTest('cancelling one seat booking leaves book reservations alone', (
    tester,
  ) async {
    await librarian.addBook(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'SE',
      language: 'English',
      shelfLocation: 'SE-01',
      totalCopies: 1,
    );
    await flush();
    await student.reserveBook(
      book: student.books.single,
      pickupDate: tomorrow(),
      loanPeriodDays: 14,
      pickupLocation: 'Main Desk',
    );
    final id = await book();
    await openDetails(tester, id);

    await tester.tap(find.text('Cancel Reservation'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel Reservation'),
      ),
    );
    await tester.pumpAndSettle();

    final docs = (await db.collection('reservations').get()).docs;
    final bookDoc = docs.singleWhere((d) => d.data()['type'] == 'book');
    expect(bookDoc.data()['status'], 'pending');
  });

  widgetTest('a cancelled booking has no Modify or Cancel', (tester) async {
    final id = await book();
    await student.cancelReservation(id);
    await flush();
    await openDetails(tester, id);

    expect(find.text('Cancelled'), findsNWidgets(2));
    expect(find.text('Modify Reservation'), findsNothing);
    expect(find.text('Cancel Reservation'), findsNothing);
  });

  widgetTest('a booking in the past has no actions and cannot be cancelled', (
    tester,
  ) async {
    final id = await pastBooking();
    await openDetails(tester, id);

    expect(find.text('Modify Reservation'), findsNothing);
    expect(find.text('Cancel Reservation'), findsNothing);
    expect(find.text('This booking time has already passed.'), findsOneWidget);

    // The repository refuses too, even if a button were somehow reached.
    final result = await student.cancelReservation(id);
    expect(result.success, isFalse);
    expect(result.message, contains('already ended'));
  });

  widgetTest('a completed booking shows Completed without actions', (
    tester,
  ) async {
    final id = await book();
    await db.collection('reservations').doc(id).update({'status': 'completed'});
    await flush();
    await openDetails(tester, id);

    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Modify Reservation'), findsNothing);
    expect(find.text('Cancel Reservation'), findsNothing);
  });
}
