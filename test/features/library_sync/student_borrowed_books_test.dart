import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/models/student_loan.dart';
import 'package:libmate_app/features/librarian/models/librarian_settings.dart';
import 'package:libmate_app/features/student/book_reservation/screens/borrowed_books_screen.dart';
import 'package:libmate_app/features/student/common/screens/profile_screen.dart';

import 'library_test_support.dart';

void main() {
  test('fine starts after due calendar day and stops at return', () {
    final loan = StudentLoan(
      id: '1',
      bookId: 'b',
      bookTitle: 'Book',
      dueDate: DateTime(2026, 10, 8, 23),
    );
    expect(
      loan.estimatedFineOn(DateTime(2026, 10, 8, 23, 59), dailyRate: 25),
      0,
    );
    expect(loan.estimatedFineOn(DateTime(2026, 10, 9), dailyRate: 25), 25);
    expect(loan.estimatedFineOn(DateTime(2026, 10, 11), dailyRate: 25), 75);
    expect(loan.estimatedFineOn(DateTime(2026, 10, 7), dailyRate: 25), 0);
    final returned = StudentLoan(
      id: '2',
      bookId: 'b',
      bookTitle: 'Book',
      dueDate: DateTime(2026, 10, 8),
      returnedAt: DateTime(2026, 10, 10),
    );
    expect(returned.estimatedFineOn(DateTime(2026, 11, 1), dailyRate: 25), 50);
    expect(
      const StudentLoan(
        id: '3',
        bookId: 'b',
        bookTitle: 'Book',
      ).estimatedFineOn(DateTime.now(), dailyRate: 25),
      isNull,
    );
  });

  test('shared settings default and preserve the agreed fine rate', () {
    final settings = LibrarianSettings.fromMap({});
    expect(settings.dailyFineRate, 25);
    expect(LibrarianSettings.fromMap(settings.toMap()).dailyFineRate, 25);
    expect(settings.copyWith(dailyFineRate: 30).dailyFineRate, 30);
    expect(settings.copyWith(loanPeriodDays: 7).dailyFineRate, 25);
  });

  test(
    'only own active loans appear and renewals and returns update live',
    () async {
      final db = await seededFirestore();
      final now = DateTime.now();
      final due = DateTime(now.year, now.month, now.day - 3);
      for (final entry in {
        'own': studentUid,
        'other': otherStudentUid,
      }.entries) {
        await db.collection('borrowings').doc(entry.key).set({
          'memberUid': entry.value,
          'bookId': 'b',
          'bookTitle': 'Loan Book',
          'dueDate': Timestamp.fromDate(due),
        });
      }
      final repo = studentRepo(db);
      addTearDown(repo.dispose);
      await settle();
      expect(repo.borrowedBooks.map((e) => e.id), ['own']);
      expect(
        repo.borrowedBooks.single.estimatedFineOn(
          now,
          dailyRate: repo.settings.dailyFineRate,
        ),
        75,
      );
      await db.collection('borrowings').doc('own').update({
        'dueDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 7),
        ),
      });
      await settle();
      expect(repo.borrowedBooks.single.estimatedFineOn(now, dailyRate: 25), 0);
      await db.collection('borrowings').doc('own').update({
        'returnedAt': Timestamp.fromDate(now),
      });
      await settle();
      expect(repo.borrowedBooks, isEmpty);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('profile opens real borrowed books in $brightness', (
      tester,
    ) async {
      final db = await seededFirestore();
      final now = DateTime.now();
      await db.collection('borrowings').doc('loan').set({
        'memberUid': studentUid,
        'bookId': 'missing-book',
        'bookTitle': 'My Borrowed Book',
        'issuedAt': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 10),
        ),
        'dueDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 3),
        ),
      });
      final repo = studentRepo(db);
      addTearDown(repo.dispose);
      await tester.runAsync(settle);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: ProfileScreen(library: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Books borrowed'));
      await tester.tap(find.text('Books borrowed'));
      await tester.pumpAndSettle();
      expect(find.byType(BorrowedBooksScreen), findsOneWidget);
      expect(find.text('1 currently borrowed'), findsOneWidget);
      expect(find.text('My Borrowed Book'), findsOneWidget);
      expect(find.text('3 days overdue'), findsOneWidget);
      expect(find.text('Rs. 75'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(BorrowedBooksScreen))).brightness,
        brightness,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
