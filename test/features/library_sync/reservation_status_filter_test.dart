import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart';
import 'library_test_support.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('book and seat filters preserve separate choices (dark: $dark)', (tester) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await seededFirestore();
      for (final type in ['book', 'seat']) {
        for (final status in ['pending', 'approved', 'rejected', 'cancelled', 'completed']) {
          await db.collection('reservations').doc('$type-$status').set({
            'type': type, 'status': status, 'studentUid': studentUid,
            'itemId': '$type-$status', 'itemName': '$type $status item',
            'date': Timestamp.fromDate(tomorrow()),
            'requestedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
      final library = studentRepo(db);
      addTearDown(library.dispose);
      await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light, home: MyReservationsScreen(library: library)));
      await tester.pumpAndSettle();
      Future<void> filter(String name) async {
        final chip = find.byKey(ValueKey('reservation-filter-$name'));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      for (final status in ['pending', 'approved', 'rejected', 'cancelled']) {
        await filter(status);
        expect(find.text('book $status item'), findsOneWidget);
        for (final other in ['pending', 'approved', 'rejected', 'cancelled', 'completed']) {
          if (other != status) expect(find.text('book $other item'), findsNothing);
        }
      }
      await tester.tap(find.text('Seats'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reservation-filter-pending')), findsNothing);
      for (final status in ['approved', 'cancelled']) {
        await filter(status);
        expect(find.text('seat $status item'), findsOneWidget);
        expect(find.text('seat completed item'), findsNothing);
      }
      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();
      expect(find.text('book cancelled item'), findsOneWidget);
      expect(find.text('book pending item'), findsNothing);
      await filter('all');
      expect(find.text('book pending item'), findsOneWidget);
      expect(find.text('book completed item'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}