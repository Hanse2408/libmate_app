import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';

import 'librarian_test_helpers.dart';

/// Every Librarian page, opened at phone, tablet and desktop widths and
/// scrolled to the bottom, must render without overflow or other errors.
void main() {
  final routes = <String>[
    LibrarianRoutes.dashboard,
    LibrarianRoutes.reservations,
    LibrarianRoutes.reservationDetails('RSV-1001'), // book, pending
    LibrarianRoutes.reservationDetails('RSV-1011'), // seat, blocked
    LibrarianRoutes.reservationDetails('RSV-1007'), // rejected
    LibrarianRoutes.reservationConfirmation('RSV-1004'), // approved seat
    LibrarianRoutes.reservationConfirmation('RSV-1005'), // approved book
    LibrarianRoutes.reservationConfirmation('RSV-1007'), // rejected book
    LibrarianRoutes.seats,
    LibrarianRoutes.addSeat,
    LibrarianRoutes.books,
    LibrarianRoutes.addBook,
    LibrarianRoutes.editBook('B001'),
    LibrarianRoutes.notifications,
    LibrarianRoutes.borrowings,
    LibrarianRoutes.borrowingDetails('LN-2003'), // overdue
    LibrarianRoutes.borrowingDetails('LN-2001'), // renew blocked
    LibrarianRoutes.borrowingDetails('LN-1990'), // returned
    LibrarianRoutes.members,
    LibrarianRoutes.memberDetails('IT23003341'), // has overdue items
    LibrarianRoutes.memberDetails('IT23012876'), // suspended, no activity
    LibrarianRoutes.reports,
    LibrarianRoutes.settings,
    LibrarianRoutes.ebooks,
    LibrarianRoutes.addEbook,
  ];

  for (final width in [360.0, 390.0, 720.0, 1280.0]) {
    testWidgets('All Librarian pages fit at ${width.toInt()}px', (tester) async {
      for (final route in routes) {
        await pumpLibrarian(tester, route, size: Size(width, 800));
        await tester.fling(find.byType(ListView).first, const Offset(0, -5000), 4000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$route at $width px');
      }
    });
  }
}
