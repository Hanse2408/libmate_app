import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/student/book_reservation/screens/modify_book_reservation_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart'
    show MyReservationsScreen;
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/seat_booking/providers/seat_booking_provider.dart';
import 'package:libmate_app/features/student/seat_booking/screens/modify_seat_reservation_screen.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_reservation_details_screen.dart';
import 'package:libmate_app/models/action_result.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/seat.dart';

import 'library_test_support.dart';

/// H05 Modify Seat Reservation: repository rules and screen flow.
void main() {
  group('modifySeatReservation', () {
    late FakeFirebaseFirestore db;
    late LibrarianFirestoreRepository librarian;
    late StudentLibraryRepository student;
    late StudentLibraryRepository other;
    late SeatRecord a1;
    late SeatRecord a2;

    setUp(() async {
      db = await seededFirestore();
      librarian = librarianRepo(db, FakeImageStorage());
      student = studentRepo(db);
      other = studentRepo(db, uid: otherStudentUid);
      await settle();
      for (final number in ['A01', 'A02']) {
        await librarian.addSeat(
          seatNumber: number,
          zone: 'Row A',
          readingRoom: 'Reading Room A',
          type: SeatType.quietZone,
        );
      }
      await settle();
      a1 = librarian.seats.firstWhere((s) => s.seatNumber == 'A01');
      a2 = librarian.seats.firstWhere((s) => s.seatNumber == 'A02');
    });

    tearDown(() {
      librarian.dispose();
      student.dispose();
      other.dispose();
    });

    Future<String> book(
      StudentLibraryRepository who,
      SeatRecord seat,
      int start,
      int end,
    ) async {
      final result = await who.bookSeat(seat: seat, date: tomorrow(), startHour: start, endHour: end);
      expect(result.success, isTrue, reason: result.message);
      await settle();
      return result.reservationId!;
    }

    Future<ActionResult> modify(
      String id,
      SeatRecord seat,
      int start,
      int end, {
      StudentLibraryRepository? who,
    }) async {
      final result = await (who ?? student).modifySeatReservation(
        reservationId: id,
        seat: seat,
        date: tomorrow(),
        startHour: start,
        endHour: end,
      );
      await settle();
      return result;
    }

    Future<Set<String>> slotIds() async =>
        (await db.collection('seatSlots').get()).docs.map((d) => d.id).toSet();

    test('keeping the same seat and time does not clash with itself', () async {
      final id = await book(student, a1, 10, 12);
      final before = await slotIds();

      final result = await modify(id, a1, 10, 12);
      expect(result.success, isTrue, reason: result.message);
      expect(await slotIds(), before);
    });

    test('moving to another seat and time updates the same reservation', () async {
      final id = await book(student, a1, 10, 12);
      final oldSlots = await slotIds();

      final result = await modify(id, a2, 14, 15);
      expect(result.success, isTrue, reason: result.message);
      expect(result.reservationId, id);

      final reservations = (await db.collection('reservations').get()).docs;
      expect(reservations, hasLength(1)); // no second reservation
      final data = reservations.single.data();
      expect(reservations.single.id, id);
      expect(data['status'], 'approved');
      expect(data['itemId'], a2.id);
      expect(data['itemName'], 'Seat A02');
      expect(data['timeSlot'], '14:00 - 15:00');

      final newSlots = await slotIds();
      expect(newSlots, SeatSlots.ids(a2.id, tomorrow(), 14, 15).toSet());
      expect(newSlots.intersection(oldSlots), isEmpty);
      final slot = (await db.collection('seatSlots').get()).docs.single.data();
      expect(slot['reservationId'], id);
      expect(slot['studentUid'], studentUid);

      // The old seat and time can be booked by someone else again.
      final freed = await other.bookSeat(seat: a1, date: tomorrow(), startHour: 10, endHour: 12);
      expect(freed.success, isTrue, reason: freed.message);
    });

    test('an overlapping change keeps shared slots and swaps the rest', () async {
      final id = await book(student, a1, 10, 12);

      final result = await modify(id, a1, 11, 13);
      expect(result.success, isTrue, reason: result.message);
      expect(await slotIds(), SeatSlots.ids(a1.id, tomorrow(), 11, 13).toSet());
    });

    test('a seat-hour held by another student cannot be taken', () async {
      final id = await book(student, a1, 10, 12);
      await book(other, a2, 14, 15);
      final before = await slotIds();

      final result = await modify(id, a2, 14, 15);
      expect(result.success, isFalse);
      expect(result.message, contains('booked by someone else'));
      expect(await slotIds(), before); // nothing released or claimed
      expect((await db.collection('reservations').doc(id).get()).data()!['itemId'], a1.id);
    });

    test('a slot taken after the screen loaded is refused by the transaction', () async {
      final id = await book(student, a1, 10, 12);
      // Another student takes A02 at 14:00 behind the student's back.
      await db.collection('seatSlots').doc(SeatSlots.id(a2.id, tomorrow(), 14)).set({
        'seatId': a2.id,
        'date': Timestamp.fromDate(tomorrow()),
        'hour': 14,
        'reservationId': 'x',
        'studentUid': otherStudentUid,
      });

      final result = await modify(id, a2, 14, 15);
      expect(result.success, isFalse);
      expect(result.message, contains('just booked by someone else'));
      expect(await slotIds(), contains(SeatSlots.id(a1.id, tomorrow(), 10)));
    });

    test("moving onto the student's own other booking is refused", () async {
      final first = await book(student, a1, 8, 9);
      await book(student, a2, 10, 11);

      final clash = await modify(first, a1, 10, 12);
      expect(clash.success, isFalse);
      expect(clash.message, contains('already have a seat booked'));

      // Next to it (no overlap) is fine.
      final adjacent = await modify(first, a1, 9, 10);
      expect(adjacent.success, isTrue, reason: adjacent.message);
    });

    test('a seat under maintenance cannot be chosen', () async {
      final id = await book(student, a1, 10, 12);
      await librarian.updateSeatStatus(a2.id, SeatStatus.maintenance);
      await settle();

      final result = await modify(id, student.seatById(a2.id)!, 10, 12);
      expect(result.success, isFalse);
      expect(result.message, contains('maintenance'));
    });

    test('the booking rules are the same as when booking', () async {
      final id = await book(student, a1, 10, 12);

      final tooLong = await modify(id, a1, 9, 13);
      expect(tooLong.success, isFalse);
      expect(tooLong.message, contains('at most 2 hours'));
    });

    test('cancelled, past, foreign and book reservations cannot be modified', () async {
      final cancelled = await book(student, a1, 10, 12);
      await student.cancelReservation(cancelled);
      await settle();
      final afterCancel = await modify(cancelled, a1, 14, 15);
      expect(afterCancel.success, isFalse);
      expect(afterCancel.message, contains('cancelled'));

      final yesterday = tomorrow().subtract(const Duration(days: 2));
      final past = await db.collection('reservations').add(
        ReservationRecord(
          id: '',
          type: ReservationType.seat,
          status: ReservationStatus.approved,
          studentUid: studentUid,
          studentId: 'IT23004512',
          studentName: 'Nethmi Perera',
          studentEmail: 'nethmi@student.test',
          itemId: a1.id,
          itemName: 'Seat A01',
          requestedAt: yesterday,
          date: yesterday,
          timeSlot: '10:00 - 12:00',
        ).toMap(),
      );
      await settle();
      final pastResult = await modify(past.id, a1, 14, 15);
      expect(pastResult.success, isFalse);
      expect(pastResult.message, contains('already ended'));

      final mine = await book(student, a2, 8, 9);
      final foreign = await modify(mine, a2, 9, 10, who: other);
      expect(foreign.success, isFalse);
      expect(foreign.message, contains('not your reservation'));

      await librarian.addBook(
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '9780132350884',
        category: 'SE',
        language: 'English',
        shelfLocation: 'SE-01',
        totalCopies: 1,
      );
      await settle();
      final bookResult = await student.reserveBook(
        book: student.books.single,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      final bookModify = await modify(bookResult.reservationId!, a2, 9, 10);
      expect(bookModify.success, isFalse);
      expect(bookModify.message, contains('Only seat reservations'));
    });

    test('the provider starts from the booking and only saves a real change', () async {
      final id = await book(student, a1, 10, 12);
      final provider = SeatBookingProvider(
        student,
        editing: student.myReservations.firstWhere((r) => r.id == id),
      );
      addTearDown(provider.dispose);
      await settle();

      expect(provider.date, tomorrow());
      expect(provider.startHour, 10);
      expect(provider.endHour, 12);
      expect(provider.selectedSeat?.id, a1.id);
      // Its own seat-hours do not make the current seat "reserved".
      expect(provider.availabilityOf(a1), SeatAvailability.available);
      expect(provider.canSave, isFalse); // nothing changed yet

      provider.selectSeat(a2);
      expect(provider.hasChanges, isTrue);
      expect(provider.canSave, isTrue);
      final result = await provider.save();
      expect(result.success, isTrue, reason: result.message);
      expect(result.reservationId, id);
    });
  });

  group('screens', () {
    late FakeFirebaseFirestore db;
    late LibrarianFirestoreRepository librarian;
    late StudentLibraryRepository student;
    late WidgetTester tester;
    late SeatRecord a1;
    late SeatRecord a2;
    late String reservationId;

    Future<void> flush() => tester.pumpAndSettle();

    void widgetTest(String name, Future<void> Function(WidgetTester) body) {
      testWidgets(name, (t) async {
        tester = t;
        db = await seededFirestore();
        librarian = librarianRepo(db, FakeImageStorage());
        student = studentRepo(db);
        addTearDown(librarian.dispose);
        addTearDown(student.dispose);
        for (final number in ['A01', 'A02']) {
          await librarian.addSeat(
            seatNumber: number,
            zone: 'Row A',
            readingRoom: 'Reading Room A',
            type: SeatType.quietZone,
          );
        }
        await flush();
        a1 = librarian.seats.firstWhere((s) => s.seatNumber == 'A01');
        a2 = librarian.seats.firstWhere((s) => s.seatNumber == 'A02');
        final result = await student.bookSeat(seat: a1, date: tomorrow(), startHour: 10, endHour: 12);
        expect(result.success, isTrue, reason: result.message);
        reservationId = result.reservationId!;
        await flush();
        await body(t);
      });
    }

    Future<void> pump(Widget screen) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
    }

    ReservationRecord current() => student.myReservations.firstWhere((r) => r.id == reservationId);

    Finder modifyButtonOnCard() => find.widgetWithText(TextButton, 'Modify');

    widgetTest('My Reservations: seat Modify opens H05', (tester) async {
      await pump(MyReservationsScreen(library: student, showSeats: true));

      await tester.tap(modifyButtonOnCard());
      await tester.pumpAndSettle();

      expect(find.byType(ModifySeatReservationScreen), findsOneWidget);
      expect(find.byType(ModifyBookReservationScreen), findsNothing);
    });

    widgetTest('My Reservations: book Modify still opens the book screen', (tester) async {
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
      await flush();
      await pump(MyReservationsScreen(library: student));

      await tester.tap(modifyButtonOnCard());
      await tester.pumpAndSettle();

      expect(find.byType(ModifyBookReservationScreen), findsOneWidget);
      expect(find.byType(ModifySeatReservationScreen), findsNothing);
    });

    widgetTest('My Reservations: a cancelled seat has Modify disabled', (tester) async {
      await student.cancelReservation(reservationId);
      await flush();
      await pump(MyReservationsScreen(library: student, showSeats: true));

      expect(tester.widget<TextButton>(modifyButtonOnCard()).onPressed, isNull);
    });

    widgetTest('H04 Modify Reservation opens H05 with the booking pre-filled', (tester) async {
      await pump(SeatReservationDetailsScreen(library: student, reservation: current()));

      await tester.tap(find.text('Modify Reservation'));
      await tester.pumpAndSettle();

      expect(find.byType(ModifySeatReservationScreen), findsOneWidget);
      expect(find.text('Modifying your current booking'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget); // start time
      expect(find.text('12:00'), findsOneWidget); // end time
      expect(find.text('Seat A01'), findsWidgets); // selected seat card
      expect(find.text('Book Seat'), findsNothing);

      // Nothing changed yet, so Save Changes is disabled.
      final save = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save Changes'));
      expect(save.onPressed, isNull);
    });

    widgetTest('saving a new seat updates H04 with the same booking ID', (tester) async {
      await pump(SeatReservationDetailsScreen(library: student, reservation: current()));
      await tester.tap(find.text('Modify Reservation'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('seat-${a2.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Back on H04 with the new data.
      expect(find.byType(ModifySeatReservationScreen), findsNothing);
      expect(find.byType(SeatReservationDetailsScreen), findsOneWidget);
      expect(find.text('Reservation updated successfully.'), findsOneWidget);
      expect(find.text('A02'), findsOneWidget);
      expect(find.text(reservationId), findsOneWidget);
      expect(find.text('Confirmed'), findsNWidgets(2));

      final docs = (await db.collection('reservations').get()).docs;
      expect(docs, hasLength(1));
      expect(docs.single.id, reservationId);
      expect(docs.single.data()['status'], 'approved');
      expect(docs.single.data()['itemId'], a2.id);
    });
  });
}
