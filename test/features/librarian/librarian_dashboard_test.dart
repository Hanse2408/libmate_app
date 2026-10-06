import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/librarian/providers/librarian_dashboard_summary.dart';
import 'package:libmate_app/features/librarian/widgets/notification_bell_button.dart';
import 'package:libmate_app/features/librarian/widgets/reservation_card.dart';

import 'librarian_test_helpers.dart';

void main() {
  group('LibrarianDashboardSummary', () {
    test('is calculated from the mock repository', () {
      final summary = LibrarianDashboardSummary.fromRepository(
        LibrarianMockRepository(),
      );

      expect(summary.pendingCount, 6);
      expect(
        summary.conflictCount,
        2,
      ); // RSV-1010 (no copies), RSV-1011 (maintenance)
      expect(summary.todayCount, 6);
      expect(summary.yesterdayCount, 1);
      expect(summary.availableSeats, 9);
      expect(summary.reservedSeats, 3);
      expect(summary.occupiedSeats, 5);
      expect(summary.maintenanceSeats, 1);
      expect(summary.occupancyRate, closeTo(8 / 17, 0.001));
      expect(summary.outOfStockBooks, 3);
      expect(summary.unreadNotifications, 4);
    });

    test('updates after a reservation is approved', () async {
      final repository = LibrarianMockRepository();
      await repository.approveReservation('RSV-1002'); // seat S001

      final summary = LibrarianDashboardSummary.fromRepository(repository);
      expect(summary.pendingCount, 5);
      expect(summary.availableSeats, 8);
      expect(summary.reservedSeats, 4);
    });
  });

  testWidgets('Renders without overflow on a phone-sized screen', (
    tester,
  ) async {
    await pumpLibrarian(
      tester,
      LibrarianRoutes.dashboard,
      size: const Size(360, 780),
    );

    expect(find.text('LibMate'), findsOneWidget);
    expect(find.text('06'), findsOneWidget); // pending count
    await scrollTo(tester, find.text('Add New Seat'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Uses two columns on a wide screen', (tester) async {
    await pumpLibrarian(
      tester,
      LibrarianRoutes.dashboard,
      size: const Size(1280, 900),
    );

    final attention = tester.getTopLeft(find.text('Attention Required'));
    final occupancy = tester.getTopLeft(find.text('Reading Room Occupancy'));
    expect(occupancy.dx, greaterThan(attention.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bell opens Notifications', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);

    await tester.tap(find.byType(NotificationBellButton));
    await tester.pumpAndSettle();
    expect(router.currentPath, LibrarianRoutes.notifications);
  });

  testWidgets('Review opens the pending reservations', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);

    await tapVisible(tester, find.text('Review'));
    expect(router.currentPath, LibrarianRoutes.reservations);
    expect(find.text('06 reservations found'), findsOneWidget);
    expect(find.text('Status: Pending'), findsOneWidget);
  });

  testWidgets("Today's reservation opens its details and back returns", (
    tester,
  ) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);

    await tapVisible(tester, find.byType(ReservationCard).first);
    expect(
      router.currentPath,
      startsWith('${LibrarianRoutes.reservations}/RSV-'),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.currentPath, LibrarianRoutes.dashboard);
  });

  testWidgets('Quick action opens Add Book', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);

    await tapVisible(tester, find.text('Add New Book'));
    expect(router.currentPath, LibrarianRoutes.addBook);
  });

  testWidgets('Pending count updates when data changes', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.dashboard);
    expect(find.text('06'), findsOneWidget);

    await repositoryOf(tester).approveReservation('RSV-1001');
    await tester.pumpAndSettle();
    expect(find.text('05'), findsOneWidget);
  });
}
