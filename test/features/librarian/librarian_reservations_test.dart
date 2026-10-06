import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/models/reservation_record.dart';
import 'package:libmate_app/features/librarian/widgets/reservation_card.dart';

import 'librarian_test_helpers.dart';

Future<void> _pickMenuOption(WidgetTester tester, String pill, String option) async {
  await tester.tap(find.text(pill));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(CheckedPopupMenuItem<int>, option));
  await tester.pumpAndSettle();
}

void main() {
  group('Reservation Management', () {
    testWidgets('lists all reservations', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservations);
      expect(find.text('Reservation Management'), findsOneWidget);
      expect(find.text('13 reservations found'), findsOneWidget);
      expect(find.byType(ReservationCard), findsWidgets);
    });

    testWidgets('search filters the list', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservations);

      await tester.enterText(find.byType(TextField), 'Kavindu');
      await tester.pumpAndSettle();
      expect(find.text('01 reservation found'), findsOneWidget);
      expect(find.text('Kavindu Silva'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No results for "zzz"'), findsOneWidget);
    });

    testWidgets('Books button filters by type', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservations);

      await tester.tap(find.widgetWithText(FilledButton, 'Books'));
      await tester.pumpAndSettle();
      expect(find.text('06 reservations found'), findsOneWidget);
      expect(find.text('Type: Book'), findsOneWidget);

      // Tapping again shows all types.
      await tester.tap(find.widgetWithText(FilledButton, 'Books'));
      await tester.pumpAndSettle();
      expect(find.text('13 reservations found'), findsOneWidget);
    });

    testWidgets('status filter combines with type and search', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservations);

      await _pickMenuOption(tester, 'Status: All', 'Pending');
      expect(find.text('06 reservations found'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Seats'));
      await tester.pumpAndSettle();
      expect(find.text('03 reservations found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Nimali');
      await tester.pumpAndSettle();
      expect(find.text('01 reservation found'), findsOneWidget);
    });

    testWidgets('book reservation opens Book Reservation Details', (tester) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.reservations);

      await tapVisible(tester, find.text('Nethmi Perera'));
      expect(router.currentPath, LibrarianRoutes.reservationDetails('RSV-1001'));
      expect(find.text('Book Reservation Details'), findsOneWidget);
    });

    testWidgets('seat reservation opens Seat Reservation Details', (tester) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.reservations);

      await tapVisible(tester, find.text('Kavindu Silva'));
      expect(router.currentPath, LibrarianRoutes.reservationDetails('RSV-1002'));
      expect(find.text('Seat Reservation Details'), findsOneWidget);
    });
  });

  group('Approval', () {
    testWidgets('approving an available book shows the confirmation', (tester) async {
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.reservationDetails('RSV-1001'),
      );

      await tapVisible(tester, find.text('Approve Reservation'));
      expect(router.currentPath, LibrarianRoutes.reservationConfirmation('RSV-1001'));
      expect(find.text('Reservation Approved!'), findsOneWidget);
      expect(find.text('14 Days'), findsOneWidget);

      final repository = repositoryOf(tester);
      expect(repository.reservationById('RSV-1001')!.status, ReservationStatus.approved);
      expect(repository.bookById('B001')!.availableCopies, 1);

      // Back to Reservations shows the updated status.
      await tapVisible(tester, find.text('Back to Reservations'));
      expect(router.currentPath, LibrarianRoutes.reservations);
      expect(find.text('05 reservations found'), findsNothing); // filter is All
    });

    testWidgets('approving an available seat shows the seat confirmation', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservationDetails('RSV-1002'));

      await tapVisible(tester, find.text('Approve Reservation'));
      expect(find.text('Reservation Approved!'), findsOneWidget);
      expect(find.text('01:00 PM - 03:00 PM'), findsOneWidget);
    });

    testWidgets('book with no copies cannot be approved', (tester) async {
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.reservationDetails('RSV-1010'),
      );
      expect(find.text('Cannot Be Approved Yet'), findsOneWidget);

      await tapVisible(tester, find.text('Approve Reservation'));
      expect(find.text('Cannot approve yet'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(router.currentPath, LibrarianRoutes.reservationDetails('RSV-1010'));
      expect(repositoryOf(tester).reservationById('RSV-1010')!.isPending, isTrue);
    });

    testWidgets('maintenance seat cannot be approved', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservationDetails('RSV-1011'));

      await tapVisible(tester, find.text('Approve Reservation'));
      expect(find.text('Cannot approve yet'), findsOneWidget);
      expect(find.textContaining('maintenance'), findsWidgets);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(repositoryOf(tester).reservationById('RSV-1011')!.isPending, isTrue);
    });

    testWidgets('approved reservation shows no actions', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservationDetails('RSV-1004'));
      expect(find.text('Reservation Approved'), findsOneWidget);
      expect(find.text('Approve Reservation'), findsNothing);
      expect(find.text('Reject Reservation'), findsNothing);
    });
  });

  group('Rejection', () {
    testWidgets('pending reservation can be rejected once, with a reason', (tester) async {
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.reservationDetails('RSV-1003'),
      );

      await tapVisible(tester, find.text('Reject Reservation'));
      expect(find.text('Reject reservation?'), findsOneWidget);

      // The Reject button is disabled until a reason is chosen.
      final reject = find.widgetWithText(FilledButton, 'Reject');
      expect(tester.widget<FilledButton>(reject).onPressed, isNull);
      await tester.tap(find.text('Duplicate request'));
      await tester.pumpAndSettle();
      await tester.tap(reject);
      await tester.pumpAndSettle();

      expect(router.currentPath, LibrarianRoutes.reservationConfirmation('RSV-1003'));
      // The confirmation page title (the new-notification banner above it
      // shows the same words, so look inside the page only).
      expect(
        find.descendant(of: find.byType(Scaffold).first, matching: find.text('Reservation Rejected')),
        findsOneWidget,
      );
      expect(find.text('Reservation Rejected'), findsNWidgets(2)); // page + banner
      final reservation = repositoryOf(tester).reservationById('RSV-1003')!;
      expect(reservation.status, ReservationStatus.rejected);
      expect(reservation.rejectionReason, 'Duplicate request');

      // Details no longer offer Approve / Reject.
      await tapVisible(tester, find.text('View Reservation'));
      expect(find.text('Reject Reservation'), findsNothing);
    });

    testWidgets('cancelling the dialog keeps the reservation pending', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reservationDetails('RSV-1003'));

      await tapVisible(tester, find.text('Reject Reservation'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repositoryOf(tester).reservationById('RSV-1003')!.isPending, isTrue);
    });
  });
}
