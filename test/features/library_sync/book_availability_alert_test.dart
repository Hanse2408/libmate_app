import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/book_reservation/widgets/book_availability_alert.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reserve_book_screen.dart';
import 'package:libmate_app/features/student/notifications/screens/student_notifications_screen.dart';

import 'library_test_support.dart';

void main() {
  test('subscriptions persist, isolate students, cancel and reject available books', () async {
    final db = await seededFirestore();
    await db.collection('books').doc('watched').set({
      'title': 'Waiting Book',
      'availableCopies': 0,
    });
    final library = studentRepo(db);
    final other = studentRepo(db, uid: otherStudentUid);
    addTearDown(library.dispose);
    addTearDown(other.dispose);
    await settle();
    expect((await library.setAvailabilityWatch('watched', true)).success, true);
    await settle();
    expect(library.isWatchingAvailability('watched'), true);
    expect(other.isWatchingAvailability('watched'), false);
    final reopened = studentRepo(db);
    addTearDown(reopened.dispose);
    await settle();
    expect(reopened.isWatchingAvailability('watched'), true);
    await library.setAvailabilityWatch('watched', false);
    await settle();
    expect(reopened.isWatchingAvailability('watched'), false);
    await db.collection('books').doc('watched').update({'availableCopies': 1});
    expect(
      (await library.setAvailabilityWatch('watched', true)).success,
      false,
    );
    expect(
      (await library.setAvailabilityWatch('missing', true)).success,
      false,
    );
  });
  test(
    'live alerts are one-shot, personal, persist and support read actions',
    () async {
      final db = await seededFirestore();
      await db.collection('books').doc('watched').set({
        'title': 'Waiting Book',
        'availableCopies': 0,
      });
      final first = studentRepo(db);
      final secondDevice = studentRepo(db);
      final other = studentRepo(db, uid: otherStudentUid);
      addTearDown(first.dispose);
      addTearDown(secondDevice.dispose);
      addTearDown(other.dispose);
      await settle();
      await first.setAvailabilityWatch('watched', true);
      await db.collection('books').doc('watched').update({
        'availableCopies': 1,
      });
      await settle();
      await settle();
      expect(
        first.notifications.where((n) => n.itemId == 'watched'),
        hasLength(1),
      );
      expect(other.notifications.where((n) => n.itemId == 'watched'), isEmpty);
      expect(first.isWatchingAvailability('watched'), false);
      final alert = first.notifications.singleWhere(
        (n) => n.itemId == 'watched',
      );
      expect(alert.isRead, false);
      await first.markNotificationRead(alert.id);
      await settle();
      expect(
        first.notifications.singleWhere((n) => n.id == alert.id).isRead,
        true,
      );
      await db.collection('books').doc('watched').update({
        'availableCopies': 0,
      });
      await first.setAvailabilityWatch('watched', true);
      await db.collection('books').doc('watched').update({
        'availableCopies': 1,
      });
      await settle();
      await settle();
      expect(
        first.notifications.where((n) => n.itemId == 'watched'),
        hasLength(2),
      );
      await first.markAllNotificationsRead();
      await settle();
      expect(first.unreadNotificationCount, 0);
    },
  );

  test(
    'reopening checks stock; cancelled requests never create alerts',
    () async {
      final db = await seededFirestore();
      await db.collection('books').doc('watched').set({
        'title': 'Waiting Book',
        'availableCopies': 0,
      });
      final first = studentRepo(db);
      await settle();
      await first.setAvailabilityWatch('watched', true);
      await settle();
      first.dispose();
      await db.collection('books').doc('watched').update({
        'availableCopies': 1,
      });
      final reopened = studentRepo(db);
      addTearDown(reopened.dispose);
      await settle();
      await settle();
      expect(
        reopened.notifications.where((n) => n.itemId == 'watched'),
        hasLength(1),
      );
      await db.collection('books').doc('watched').update({
        'availableCopies': 0,
      });
      await reopened.setAvailabilityWatch('watched', true);
      await reopened.setAvailabilityWatch('watched', false);
      await db.collection('books').doc('watched').update({
        'availableCopies': 1,
      });
      await settle();
      await settle();
      expect(
        reopened.notifications.where((n) => n.itemId == 'watched'),
        hasLength(1),
      );
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'alert toggle and unread notification navigation, dark: $dark',
      (tester) async {
        tester.view.physicalSize = const Size(440, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final db = await seededFirestore();
        await db.collection('books').doc('watched').set({
          'title': 'Waiting Book',
          'availableCopies': 0,
        });
        final library = studentRepo(db);
        addTearDown(library.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: BookAvailabilityAlert(library: library, bookId: 'watched'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(library.isWatchingAvailability('watched'), true);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(library.isWatchingAvailability('watched'), false);
        await db.collection('books').doc('watched').update({
          'availableCopies': 1,
        });
        await db.collection('books').doc('watched').update({
          'availableCopies': 0,
        });
        await library.setAvailabilityWatch('watched', true);
        await db.collection('books').doc('watched').update({
          'availableCopies': 1,
        });
        await tester.pumpAndSettle();
        final alert = library.notifications.singleWhere(
          (n) => n.itemId == 'watched',
        );
        expect(alert.isRead, false);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: StudentNotificationsScreen(library: library),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Your next read is available!'));
        await tester.pumpAndSettle();
        expect(find.byType(ReserveBookScreen), findsOneWidget);
        expect(
          library.notifications.singleWhere((n) => n.id == alert.id).isRead,
          true,
        );
        Navigator.of(tester.element(find.byType(ReserveBookScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Your next read is available!'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('filter-Status-Read')));
        await tester.pumpAndSettle();
        expect(find.text('Your next read is available!'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
