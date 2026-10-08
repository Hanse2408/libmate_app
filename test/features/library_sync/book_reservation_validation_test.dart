import 'package:flutter/material.dart';
import 'package:libmate_app/features/student/common/widgets/loan_period_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/models/book_reservation_validation.dart';
import 'package:libmate_app/models/book.dart';

import 'library_test_support.dart';

void main() {
  testWidgets('numeric loan input displays days and rejects invalid lengths', (
    tester,
  ) async {
    var days = 14;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanPeriodField(
            initialValue: 14,
            onChanged: (value) => days = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '11');
    await tester.pump();
    expect(days, 11);
    expect(find.text('days'), findsOneWidget);
    expect(find.text('Enter a whole number from 1 to 30.'), findsNothing);
    for (final text in ['', '0', '31']) {
      await tester.enterText(find.byType(TextFormField), text);
      await tester.pump();
      expect(find.text('Enter a whole number from 1 to 30.'), findsOneWidget);
    }
  });
  test(
    'custom eleven-day reservation saves as a number and can be modified',
    () async {
      final db = await seededFirestore();
      const book = BookRecord(
        id: 'b',
        title: 'Book',
        author: 'Author',
        isbn: '',
        category: '',
        language: '',
        shelfLocation: '',
        totalCopies: 1,
        availableCopies: 1,
      );
      await db.collection('books').doc('b').set(book.toMap());
      final repo = studentRepo(db);
      addTearDown(repo.dispose);
      await settle();
      final result = await repo.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 11,
        pickupLocation: 'Main Desk',
      );
      expect(result.success, isTrue, reason: result.message);
      final saved =
          (await db.collection('reservations').doc(result.reservationId).get())
              .data()!;
      expect(saved['loanPeriodDays'], 11);
      expect(saved['loanPeriodDays'], isA<int>());
      final updated = await repo.updateBookReservation(
        reservationId: result.reservationId!,
        pickupDate: tomorrow(),
        loanPeriodDays: 19,
        pickupLocation: 'Main Desk',
      );
      expect(updated.success, isTrue, reason: updated.message);
      expect(
        (await db.collection('reservations').doc(result.reservationId).get())
            .data()!['loanPeriodDays'],
        19,
      );
    },
  );
  test('pickup calendar boundaries and supported fields', () {
    final now = DateTime(2026, 10, 8, 18);
    String? validate(
      DateTime date, {
      int days = 14,
      String location = 'Main Desk',
    }) => BookReservationValidation.error(
      pickupDate: date,
      loanPeriodDays: days,
      pickupLocation: location,
      now: now,
    );
    expect(validate(DateTime(2026, 10, 8)), isNull);
    expect(validate(DateTime(2026, 11, 7)), isNull);
    expect(validate(DateTime(2026, 10, 7)), contains('past'));
    expect(validate(DateTime(2026, 11, 8)), contains('30 days'));
    expect(validate(now, days: 0), contains('loan period'));
    expect(validate(now, days: 60), contains('loan period'));
    expect(validate(now, location: '  '), contains('pickup location'));
    for (final days in List.generate(30, (index) => index + 1)) {
      expect(validate(now, days: days), isNull);
    }
  });
  test('invalid requests and modifications write nothing', () async {
    final db = await seededFirestore();
    final repo = studentRepo(db);
    addTearDown(repo.dispose);
    const book = BookRecord(
      id: 'b',
      title: 'Book',
      author: 'Author',
      isbn: '',
      category: '',
      language: '',
      shelfLocation: '',
      totalCopies: 1,
      availableCopies: 1,
    );
    final result = await repo.reserveBook(
      book: book,
      pickupDate: DateTime.now().subtract(const Duration(days: 2)),
      loanPeriodDays: 14,
      pickupLocation: 'Main Desk',
    );
    expect(result.success, isFalse);
    expect(result.message, contains('past'));
    final modified = await repo.updateBookReservation(
      reservationId: 'r',
      pickupDate: DateTime.now(),
      loanPeriodDays: 14,
      pickupLocation: ' ',
    );
    expect(modified.success, isFalse);
    expect(modified.message, contains('pickup location'));
    expect((await db.collection('reservations').get()).docs, isEmpty);
    expect((await db.collection('notifications').get()).docs, isEmpty);
  });
}
