import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/book_reservation/screens/book_details_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/booking_confirmation_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/find_books_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/modify_book_reservation_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reservation_details_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reserve_book_screen.dart';
import 'package:libmate_app/features/student/common/screens/student_home_screen.dart';
import 'package:libmate_app/features/student/common/screens/profile_screen.dart';
import 'library_test_support.dart';

void main() {
  for (final page in ['catalogue', 'book', 'reserve', 'confirmation', 'details', 'modify', 'reservations', 'home', 'profile']) {
    testWidgets('$page renders with readable dark surfaces', (tester) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await seededFirestore();
      await db.collection('books').doc('book-1').set({
        'title': 'Designing Interfaces', 'author': 'Jenifer Tidwell',
        'category': 'Design', 'totalCopies': 3, 'availableCopies': 2,
      });
      final date = DateTime.now().add(const Duration(days: 1));
      await db.collection('reservations').doc('request-1').set({
        'type': 'book', 'status': 'pending', 'studentUid': studentUid,
        'itemId': 'book-1', 'itemName': 'Designing Interfaces',
        'date': Timestamp.fromDate(date), 'requestedAt': Timestamp.fromDate(DateTime.now()),
        'pickupLocation': 'Library Counter', 'loanPeriodDays': 21, 'notes': 'After class',
      });
      final library = studentRepo(db);
      if (page != 'home') addTearDown(library.dispose);
      await tester.pumpAndSettle();
      final screen = switch (page) {
        'catalogue' => FindBooksScreen(library: library),
        'book' => BookDetailsScreen(library: library, bookId: 'book-1'),
        'reserve' => ReserveBookScreen(library: library, bookId: 'book-1'),
        'confirmation' => BookingConfirmationScreen(library: library, bookTitle: 'Designing Interfaces', pickupDate: 'Tomorrow', loanPeriod: '21 Days', pickupLocation: 'Library Counter', reservationId: 'request-1'),
        'details' => ReservationDetailsScreen(library: library, reservationId: 'request-1'),
        'modify' => ModifyBookReservationScreen(library: library, reservationId: 'request-1'),
        'reservations' => MyReservationsScreen(library: library),
        'home' => StudentHomeScreen(createLibrary: () => library),
        _ => ProfileScreen(library: library),
      };
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.dark, home: screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor, const Color(0xFF0F172A));
      // Light cards and hardcoded navy text must not remain in the dark UI.
      for (final container in tester.widgetList<Container>(find.byType(Container))) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) expect(decoration.color, isNot(Colors.white), reason: container.toStringDeep());
      }
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.style?.color, isNot(const Color(0xFF172033)));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}