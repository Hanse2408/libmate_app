import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/models/seat_record.dart';
import 'package:libmate_app/features/librarian/widgets/seat_tile.dart';

import 'librarian_test_helpers.dart';

Finder _seat(String number) =>
    find.ancestor(of: find.text(number), matching: find.byType(SeatTile));

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await scrollTo(tester, find.text(label)); // make sure the field is built
  await scrollTo(tester, _field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Seat Management shows counts and the seat map', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.seats);

    expect(find.text('Seat Management'), findsOneWidget);
    expect(find.text('9'), findsOneWidget); // available
    expect(find.text('Reading Room A — Seat Map'), findsOneWidget);
    expect(find.byType(SeatTile), findsNWidgets(18));
  });

  testWidgets('Selecting a reserved seat shows who reserved it', (
    tester,
  ) async {
    await pumpLibrarian(tester, LibrarianRoutes.seats);

    await tapVisible(tester, _seat('A05'));
    await scrollTo(tester, find.text('Seat A05'));
    expect(find.text('Reserved By'), findsOneWidget);
    expect(find.text('Tharindu Jayasinghe'), findsOneWidget);
  });

  testWidgets('Update Seat Status changes the seat', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.seats);

    await tapVisible(tester, _seat('A01'));
    await tapVisible(tester, find.text('Update Seat Status'));
    await tester.tap(find.widgetWithText(ListTile, 'Maintenance'));
    await tester.pumpAndSettle();

    expect(
      repositoryOf(tester).seatById('S001')!.status,
      SeatStatus.maintenance,
    );
    expect(find.text('Seat A01 is now Maintenance.'), findsOneWidget);
  });

  testWidgets('Add Seat validates the form', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.addSeat);

    await tapVisible(tester, find.text('Save Seat'));
    expect(find.text('Seat number is required'), findsOneWidget);
    expect(find.text('Choose a seat type'), findsOneWidget);

    await _type(tester, 'SEAT NUMBER', '9');
    expect(find.text('Use a letter and number, e.g. D09'), findsOneWidget);

    await _type(tester, 'SEAT NUMBER', 'a01');
    expect(find.text('Seat A01 already exists in this room'), findsOneWidget);
    expect(repositoryOf(tester).seats.length, 18);
  });

  testWidgets('Saving a valid seat adds it to the map', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.addSeat);

    await _type(tester, 'SEAT NUMBER', 'D09');
    await _type(tester, 'ROW / ZONE', 'Row D');
    await tapVisible(
      tester,
      find.widgetWithText(ChoiceChip, 'Individual Desk'),
    );
    await tapVisible(tester, find.text('Power Outlet'));
    await tapVisible(tester, find.text('Save Seat'));

    expect(router.currentPath, LibrarianRoutes.seats);
    expect(find.text('Seat D09 added to Reading Room A.'), findsOneWidget);
    await scrollTo(tester, _seat('D09'));
    expect(find.text('ROW D — INDIVIDUAL DESK'), findsOneWidget);

    final seat = repositoryOf(tester).seats.last;
    expect(seat.seatNumber, 'D09');
    expect(seat.hasPowerOutlet, isTrue);
  });
}
