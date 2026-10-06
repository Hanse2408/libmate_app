import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/seat_booking/providers/seat_booking_provider.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/seat.dart';

import 'library_test_support.dart';

/// Seat availability on the Book a Seat screen, on a fake Firestore shared by
/// a librarian and two students.
void main() {
  late FakeFirebaseFirestore db;
  late LibrarianFirestoreRepository librarian;
  late StudentLibraryRepository student;
  late StudentLibraryRepository other;
  late SeatBookingProvider provider;

  setUp(() async {
    db = await seededFirestore();
    librarian = librarianRepo(db, FakeImageStorage());
    student = studentRepo(db);
    other = studentRepo(db, uid: otherStudentUid);
    await settle();
    provider = SeatBookingProvider(student);
    provider.setDate(tomorrow());
    provider.setStartHour(8); // tomorrow, 08:00 – 09:00
    await settle();
  });

  tearDown(() {
    provider.dispose();
    librarian.dispose();
    student.dispose();
    other.dispose();
  });

  Future<SeatRecord> addSeat(String number, {String zone = 'Row A'}) async {
    final result = await librarian.addSeat(
      seatNumber: number,
      zone: zone,
      readingRoom: 'Reading Room A',
      type: SeatType.quietZone,
    );
    expect(result.success, isTrue, reason: result.message);
    await settle();
    return librarian.seats.firstWhere((s) => s.seatNumber == number);
  }

  SeatRecord latest(SeatRecord seat) => student.seatById(seat.id)!;

  test('seats added by the librarian appear grouped by room and row, in order', () async {
    await addSeat('A10');
    await addSeat('A02');
    await addSeat('B01', zone: 'Row B');

    final room = provider.rooms.single;
    expect(room.name, 'Reading Room A');
    expect([for (final z in room.zones) z.name], ['Row A', 'Row B']);
    expect([for (final s in room.zones.first.seats) s.seatNumber], ['A02', 'A10']);
  });

  test('each seat state is told apart and only available seats can be chosen', () async {
    final free = await addSeat('A01');
    final reserved = await addSeat('A02');
    final maintenance = await addSeat('A03');
    await librarian.updateSeatStatus(maintenance.id, SeatStatus.maintenance);
    await settle();
    final booked = await other.bookSeat(
      seat: latest(reserved),
      date: tomorrow(),
      startHour: 8,
      endHour: 9,
    );
    expect(booked.success, isTrue, reason: booked.message);
    await settle();

    expect(provider.availabilityOf(latest(free)), SeatAvailability.available);
    expect(provider.availabilityOf(latest(reserved)), SeatAvailability.reserved);
    expect(provider.availabilityOf(latest(maintenance)), SeatAvailability.maintenance);

    provider.selectSeat(latest(reserved));
    provider.selectSeat(latest(maintenance));
    expect(provider.selectedSeat, isNull);
    expect(provider.canBook, isFalse);

    provider.selectSeat(latest(free));
    expect(provider.selectedSeat?.id, free.id);
    expect(provider.canBook, isTrue);
  });

  test('changing the time refreshes availability and drops an invalid seat', () async {
    final seat = await addSeat('A01');
    final booked = await other.bookSeat(
      seat: latest(seat),
      date: tomorrow(),
      startHour: 9,
      endHour: 10,
    );
    expect(booked.success, isTrue, reason: booked.message);
    await settle();

    provider.selectSeat(latest(seat)); // 08:00 – 09:00 is free
    expect(provider.selectedSeat?.id, seat.id);

    provider.setStartHour(9); // now overlaps the other student's booking
    expect(provider.availabilityOf(latest(seat)), SeatAvailability.reserved);
    expect(provider.selectedSeat, isNull);
    expect(provider.canBook, isFalse);
  });

  test('a seat the librarian puts under maintenance or removes is dropped live', () async {
    final seat = await addSeat('A01');
    provider.selectSeat(latest(seat));
    expect(provider.selectedSeat, isNotNull);

    await librarian.updateSeatStatus(seat.id, SeatStatus.maintenance);
    await settle();
    expect(provider.selectedSeat, isNull);

    final removed = await addSeat('A02');
    provider.selectSeat(latest(removed));
    await librarian.deleteSeat(removed.id);
    await settle();
    expect(provider.selectedSeat, isNull);
    expect(provider.rooms.single.zones.single.seats.map((s) => s.seatNumber), ['A01']);
  });

  test('booking creates one confirmed reservation and the seat is then taken', () async {
    final seat = await addSeat('A01');
    provider.selectSeat(latest(seat));

    final result = await provider.book();
    expect(result.success, isTrue, reason: result.message);
    await settle();

    final bookings = (await db.collection('reservations').get()).docs;
    expect(bookings, hasLength(1));
    expect(bookings.single.data()['status'], ReservationStatus.approved.name);
    expect(result.reservationId, bookings.single.id);
    expect(provider.isBooking, isFalse);
    expect(provider.availabilityOf(latest(seat)), SeatAvailability.reserved);
    expect(provider.selectedSeat, isNull);
    expect(provider.hasOwnBooking, isTrue);
  });

  test('the time choices follow the library hours and the booking limit', () {
    expect(provider.startHours.first, 8);
    expect(provider.startHours.last, 19);
    expect(provider.endHours, [9, 10]); // at most 2 hours
    provider.setStartHour(19);
    expect(provider.endHours, [20]); // never after closing
    expect(provider.endHour, 20);
  });
}
