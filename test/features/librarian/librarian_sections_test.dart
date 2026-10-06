import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/models/borrowing_record.dart';
import 'package:libmate_app/features/librarian/models/member_record.dart';
import 'package:libmate_app/features/librarian/widgets/borrowing_card.dart';
import 'package:libmate_app/features/librarian/widgets/librarian_tab_chip.dart';
import 'package:libmate_app/features/librarian/widgets/member_card.dart';

import 'librarian_test_helpers.dart';

/// Tests for Borrowing, Members, Reports and Settings screens.
void main() {
  group('Borrowing Management', () {
    testWidgets('lists loans with counts', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.borrowings);

      expect(find.text('Borrowing Management'), findsOneWidget);
      expect(find.text('20 loans found'), findsOneWidget);
      expect(find.text('Active Loans'), findsOneWidget);
      expect(find.byType(BorrowingCard), findsWidgets);
    });

    testWidgets('status tab and search filter the list', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.borrowings);

      // The chip bar scrolls sideways, so "Overdue" may start off screen.
      final overdueTab = find.widgetWithText(
        LibrarianTabChip,
        'Overdue',
        skipOffstage: false,
      );
      await tester.ensureVisible(overdueTab);
      await tester.pumpAndSettle();
      await tester.tap(overdueTab);
      await tester.pumpAndSettle();
      expect(find.text('04 loans found'), findsOneWidget);

      await tester.ensureVisible(
        find.widgetWithText(LibrarianTabChip, 'All', skipOffstage: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(LibrarianTabChip, 'All', skipOffstage: false),
      );
      await tester.pumpAndSettle();
      // Scrolling the chip bar into view may have moved the search box up.
      await tester.enterText(
        find.byType(TextField, skipOffstage: false),
        'LN-2011',
      );
      await tester.pumpAndSettle();
      expect(find.text('01 loan found', skipOffstage: false), findsOneWidget);
    });

    testWidgets('opens on the Overdue tab from a link', (tester) async {
      await pumpLibrarian(
        tester,
        LibrarianRoutes.borrowingsFiltered(BorrowingStatus.overdue),
      );
      expect(find.text('04 loans found'), findsOneWidget);
    });

    testWidgets('Mark Returned from the list', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.borrowings);
      await tester.enterText(find.byType(TextField), 'LN-2002');
      await tester.pumpAndSettle();

      await tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Mark Returned'),
      );
      expect(find.text('Mark as returned?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Mark Returned'));
      await tester.pumpAndSettle();

      expect(find.text('"Clean Code" marked as returned.'), findsOneWidget);
      expect(repositoryOf(tester).borrowingById('LN-2002')!.isReturned, isTrue);
      // A returned loan no longer offers the action.
      expect(find.widgetWithText(TextButton, 'Mark Returned'), findsNothing);
    });

    testWidgets('Borrowing Details renews an eligible loan', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.borrowingDetails('LN-2011'));

      expect(find.text('Borrowing Details'), findsOneWidget);
      expect(find.text('On Loan'), findsOneWidget);
      await tapVisible(tester, find.text('Renew Loan'));
      expect(find.textContaining('Loan renewed. New due date'), findsOneWidget);
      expect(repositoryOf(tester).borrowingById('LN-2011')!.renewals, 1);
    });

    testWidgets('Renew is disabled with a reason when another student waits', (
      tester,
    ) async {
      await pumpLibrarian(tester, LibrarianRoutes.borrowingDetails('LN-2001'));

      await scrollTo(tester, find.text('Renew Loan'));
      final renew = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Renew Loan'),
      );
      expect(renew.onPressed, isNull);
      expect(
        find.textContaining('Another student has reserved this book'),
        findsOneWidget,
      );
    });

    testWidgets('returned loan shows its return date and no actions', (
      tester,
    ) async {
      await pumpLibrarian(tester, LibrarianRoutes.borrowingDetails('LN-1990'));
      expect(find.text('Returned'), findsWidgets);
      expect(find.text('Mark as Returned'), findsNothing);
    });
  });

  group('Member Management', () {
    testWidgets('lists and searches members', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.members);

      expect(find.text('Member Management'), findsOneWidget);
      expect(find.text('15 members found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Sachini');
      await tester.pumpAndSettle();
      expect(find.text('01 member found'), findsOneWidget);
      expect(find.byType(MemberCard), findsOneWidget);
    });

    testWidgets('With Overdue tile filters the list', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.members);
      await tester.tap(find.text('With Overdue'));
      await tester.pumpAndSettle();
      expect(find.text('04 members found'), findsOneWidget);
    });

    testWidgets('member details show loans and reservations', (tester) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.members);

      await tester.enterText(find.byType(TextField), 'IT23003341');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MemberCard));
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.memberDetails('IT23003341'));
      expect(find.text('Sachini Fernando'), findsOneWidget);

      await scrollTo(tester, find.text('Overdue Items'));
      expect(find.textContaining('LN-2003'), findsOneWidget);
      await scrollTo(tester, find.textContaining('LN-2016'));
      await scrollTo(tester, find.text('Human-Computer Interaction · Book'));
    });

    testWidgets('a loan opened from a member returns to that member', (
      tester,
    ) async {
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.memberDetails('IT23003341'),
      );

      await scrollTo(
        tester,
        find.text('Overdue Items'),
      ); // build the loan cards
      await tapVisible(tester, find.byType(BorrowingCard).first);
      expect(
        router.currentPath,
        startsWith('${LibrarianRoutes.borrowings}/LN-'),
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.memberDetails('IT23003341'));
    });

    testWidgets('suspend account', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.memberDetails('IT23514658'));

      await tapVisible(tester, find.text('Suspend Account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();

      expect(
        repositoryOf(tester).memberById('IT23514658')!.status,
        MemberStatus.suspended,
      );
      await scrollTo(tester, find.text('Reactivate Account'));
    });
  });

  group('Reports & Analytics', () {
    testWidgets('shows summary values and switches period', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.reports);

      expect(find.text('Reports & Analytics'), findsOneWidget);
      expect(find.text('32'), findsOneWidget); // total copies
      expect(find.text('47%'), findsOneWidget); // seat occupancy
      expect(find.text('this week'), findsOneWidget);

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('last 4 weeks'), findsOneWidget);
      await scrollTo(tester, find.text('Requests per week'));
    });
  });

  group('Settings', () {
    testWidgets('dashboard gear icon opens Settings; back returns', (
      tester,
    ) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.settings);
      expect(find.text('Library Preferences'.toUpperCase()), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.dashboard);
    });

    testWidgets('shows current values', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.settings);
      await scrollTo(tester, find.text('14 days'));
      expect(find.text('5 books'), findsOneWidget);
      expect(find.text('08:00 – 20:00'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);
    });

    testWidgets('changing the borrowing period saves it', (tester) async {
      await pumpLibrarian(tester, LibrarianRoutes.settings);

      await tapVisible(tester, find.text('Default Borrowing Period'));
      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repositoryOf(tester).settings.loanPeriodDays, 15);
      expect(find.text('15 days'), findsOneWidget);
      expect(find.text('Settings saved.'), findsOneWidget);
    });

    testWidgets('notification switch and password placeholder', (tester) async {
      await pumpLibrarian(
        tester,
        LibrarianRoutes.settings,
        size: const Size(400, 2600),
      );

      final availability = find.descendant(
        of: find
            .ancestor(
              of: find.text('Book Availability'),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byType(Switch),
      );
      await tester.tap(availability);
      await tester.pumpAndSettle();
      expect(repositoryOf(tester).settings.availabilityNotifications, isTrue);

      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Available when accounts are connected.'),
        findsOneWidget,
      );
    });
  });

  group('Dashboard entry points', () {
    for (final (label, path) in [
      ('Borrowing', LibrarianRoutes.borrowings),
      ('Members', LibrarianRoutes.members),
      ('Reports', LibrarianRoutes.reports),
    ]) {
      testWidgets('Quick action $label', (tester) async {
        final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);
        await tapVisible(tester, find.text(label));
        expect(router.currentPath, path);
      });
    }

    testWidgets('overdue alert opens the Overdue tab', (tester) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);
      expect(find.text('4 borrowed books are overdue.'), findsOneWidget);
      await tapVisible(tester, find.text('4 borrowed books are overdue.'));
      expect(router.currentPath, LibrarianRoutes.borrowings);
      expect(find.text('04 loans found'), findsOneWidget);
    });

    testWidgets('avatar menu links to Members', (tester) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.dashboard);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Members'));
      await tester.pumpAndSettle();
      expect(router.currentPath, LibrarianRoutes.members);
    });
  });
}
