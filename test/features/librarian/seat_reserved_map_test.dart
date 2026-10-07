import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/theme/librarian_theme.dart';
import 'package:libmate_app/features/librarian/widgets/count_tile.dart';
import 'package:libmate_app/features/librarian/widgets/seat_tile.dart';
import 'package:libmate_app/features/librarian/widgets/status_chip.dart';
import 'package:libmate_app/models/seat.dart';

import '../library_sync/library_test_support.dart';
import 'librarian_test_helpers.dart';

/// A student's seat booking turns the seat yellow (Reserved) on the
/// Librarian Seat Management map straight away, from the live Firestore
/// `reservations` data, with no approval step.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() async => db = await seededFirestore());

  SeatTile tileFor(WidgetTester tester, String number) => tester.widget<SeatTile>(
    find.byWidgetPredicate((w) => w is SeatTile && w.seat.seatNumber == number),
  );

  int countOf(WidgetTester tester, String label) => tester
      .widget<CountTile>(find.byWidgetPredicate((w) => w is CountTile && w.label == label))
      .count;

  testWidgets('a student booking shows the seat as Reserved (yellow) live', (tester) async {
    await tester.runAsync(() async {
      final setup = librarianRepo(db, FakeImageStorage());
      for (final number in ['A01', 'A02']) {
        await setup.addSeat(
          seatNumber: number,
          zone: 'Row A',
          readingRoom: 'Reading Room A',
          type: SeatType.quietZone,
        );
      }
      setup.dispose();
    });
    await pumpLibrarian(
      tester,
      LibrarianRoutes.seats,
      size: const Size(1200, 1400),
      createRepository: () => librarianRepo(db, FakeImageStorage()),
    );
    await tester.runAsync(settle);
    await tester.pumpAndSettle();
    expect(tileFor(tester, 'A01').seat.status, SeatStatus.available);
    expect(countOf(tester, 'Reserved'), 0);

    final student = studentRepo(db);
    addTearDown(student.dispose);
    await tester.runAsync(() async {
      await settle();
      final booked = await student.bookSeat(
        seat: student.seats.firstWhere((s) => s.seatNumber == 'A01'),
        date: tomorrow(),
        startHour: 10,
        endHour: 12,
      );
      expect(booked.success, isTrue, reason: booked.message);
      await settle();
    });
    await tester.pumpAndSettle();

    final tile = tileFor(tester, 'A01');
    expect(tile.seat.status, SeatStatus.reserved);
    expect(StatusChip.seatColor(tile.seat.status), LibrarianColors.gold); // the existing yellow
    expect(tileFor(tester, 'A02').seat.status, SeatStatus.available);
    expect(countOf(tester, 'Reserved'), 1);
    expect(countOf(tester, 'Available'), 1);

    // The selected seat's details show it as reserved, with the booking.
    await tester.tap(find.byWidget(tile));
    await tester.pumpAndSettle();
    expect(find.text('Reserved'), findsWidgets);
    expect(find.textContaining('Nethmi'), findsWidgets);
  });
}
