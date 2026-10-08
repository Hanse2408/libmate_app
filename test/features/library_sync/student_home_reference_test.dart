import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/common/screens/student_home_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/find_books_screen.dart';
import 'library_test_support.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [360.0, 440.0]) {
      testWidgets('reference Home at $width, dark: $dark keeps live navigation', (tester) async {
        tester.view.physicalSize = Size(width, 1400); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final db = await seededFirestore(); final library = studentRepo(db);
        await db.collection('reservations').doc('home-book').set({
          'studentUid': studentUid, 'type': 'book', 'status': 'pending',
          'itemId': 'book', 'itemName': 'Real Reservation Title',
          'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        });
        await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
          home: StudentHomeScreen(createLibrary: () => library)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Learn  \u2022  Reserve  \u2022  Belong'), findsOneWidget);
        expect(find.text('Real Reservation Title'), findsOneWidget);
        await tester.tap(find.text('Find Books')); await tester.pumpAndSettle();
        expect(find.byType(FindBooksScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(FindBooksScreen))).pop(); await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Real Reservation Title'));
        await tester.tap(find.text('Real Reservation Title')); await tester.pumpAndSettle();
        expect(find.byType(ReservationDetailsScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
      });
    }
  }
}
