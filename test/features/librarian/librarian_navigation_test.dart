import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';

import 'librarian_test_helpers.dart';

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('Bottom navigation switches between the main sections', (
    tester,
  ) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);
    final nav = find.byType(NavigationBar);

    for (final (label, path) in [
      ('Reservations', LibrarianRoutes.reservations),
      ('Books', LibrarianRoutes.books),
      ('Seats', LibrarianRoutes.seats),
      ('Dashboard', LibrarianRoutes.dashboard),
    ]) {
      await tester.tap(find.descendant(of: nav, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(router.currentPath, path);
    }
  });

  testWidgets('Sub-pages keep the bottom nav on their section and go back', (
    tester,
  ) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.addBook);

    expect(find.text('Add New Book'), findsOneWidget);
    expect(_selectedTab(tester), 2); // Books

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.currentPath, LibrarianRoutes.books);
  });

  testWidgets('Confirmation for an undecided reservation explains itself', (
    tester,
  ) async {
    final router = await pumpLibrarian(
      tester,
      LibrarianRoutes.reservationConfirmation('RSV-1001'),
    );
    expect(find.text('No decision yet'), findsOneWidget);
    expect(_selectedTab(tester), 1); // Reservations

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.currentPath, LibrarianRoutes.reservations);
  });

  testWidgets('Unknown reservation shows a not-found state', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.reservationDetails('RSV-9999'));
    expect(find.text('Reservation not found'), findsOneWidget);
  });
}
