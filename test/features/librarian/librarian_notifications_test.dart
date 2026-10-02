import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/widgets/notification_tile.dart';

import 'librarian_test_helpers.dart';

void main() {
  testWidgets('Notifications list with unread count', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.notifications);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Unread (4)'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.byType(NotificationTile), findsWidgets);
  });

  testWidgets('Unread filter shows only unread notifications', (tester) async {
    // Tall screen so every card is built.
    await pumpLibrarian(
      tester,
      LibrarianRoutes.notifications,
      size: const Size(400, 2400),
    );

    await tester.tap(find.text('Unread (4)'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationTile), findsNWidgets(4));
    expect(find.byKey(const Key('unread-dot')), findsNWidgets(4));
  });

  testWidgets('Opening a reservation notification marks it read and returns', (
    tester,
  ) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.notifications);

    await tapVisible(tester, find.text('Nethmi Perera — Clean Code'));
    expect(router.currentPath, LibrarianRoutes.reservationDetails('RSV-1001'));
    expect(find.text('Book Reservation Details'), findsOneWidget);
    expect(repositoryOf(tester).unreadNotificationCount, 3);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.currentPath, LibrarianRoutes.notifications);
    expect(find.text('Unread (3)'), findsOneWidget);
  });

  testWidgets('Mark all as read clears the dashboard badge', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.notifications);

    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('Unread (0)'), findsOneWidget);
    expect(find.text('Mark all as read'), findsNothing);

    router.go(LibrarianRoutes.dashboard);
    await tester.pumpAndSettle();
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isFalse);
  });
}
