import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_data.dart';
import 'package:libmate_app/features/librarian/models/book_record.dart';
import 'package:libmate_app/features/librarian/models/reservation_record.dart';
import 'package:libmate_app/features/librarian/providers/book_filter.dart';
import 'package:libmate_app/features/librarian/providers/reservation_filter.dart';
import 'package:libmate_app/features/librarian/utils/librarian_validators.dart';

void main() {
  group('ReservationFilter', () {
    final all = LibrarianMockData.reservations();
    List<String> ids(ReservationFilter filter) =>
        filter.apply(all).map((r) => r.id).toList();

    test(
      'search matches reservation ID, student name, student ID and item',
      () {
        expect(ids(const ReservationFilter(query: 'RSV-1002')), ['RSV-1002']);
        expect(ids(const ReservationFilter(query: 'kavindu')), ['RSV-1002']);
        expect(ids(const ReservationFilter(query: 'IT23865894')), ['RSV-1011']);
        expect(ids(const ReservationFilter(query: 'clean code')), ['RSV-1001']);
        expect(ids(const ReservationFilter(query: 'seat a05')), ['RSV-1004']);
      },
    );

    test('type and status filters', () {
      expect(
        const ReservationFilter(type: ReservationType.book).apply(all).length,
        6,
      );
      expect(
        const ReservationFilter(status: ReservationStatus.pending)
            .apply(all)
            .length,
        6,
      );
      expect(
        const ReservationFilter(status: ReservationStatus.rejected)
            .apply(all)
            .length,
        1,
      );
    });

    test('filters and search combine', () {
      expect(
        ids(
          const ReservationFilter(
            type: ReservationType.seat,
            status: ReservationStatus.pending,
          ),
        )..sort(),
        ['RSV-1002', 'RSV-1006', 'RSV-1011'],
      );
      expect(
        ids(
          const ReservationFilter(
            query: 'Perera',
            type: ReservationType.book,
            status: ReservationStatus.pending,
          ),
        ),
        ['RSV-1001'],
      );
    });

    test('date filter and pending-first order', () {
      final today = const ReservationFilter(date: ReservationDateFilter.today)
          .apply(all);
      expect(today.length, 6);
      final sorted = const ReservationFilter().apply(all);
      expect(sorted.take(6).every((r) => r.isPending), isTrue);
    });
  });

  group('BookFilter', () {
    final books = LibrarianMockData.books();

    test('search by title, author and ISBN', () {
      expect(
        const BookFilter(query: 'madol').apply(books).single.title,
        'Madol Doova',
      );
      expect(const BookFilter(query: 'silberschatz').apply(books).length, 2);
      expect(
        const BookFilter(query: '978-0132350884').apply(books).single.title,
        'Clean Code',
      );
    });

    test('stock, category and author filters', () {
      expect(
        const BookFilter(stock: BookStock.notAvailable).apply(books).length,
        3,
      );
      expect(
        const BookFilter(stock: BookStock.lowStock).apply(books).single.id,
        'B003',
      );
      expect(
        const BookFilter(category: 'Novel').apply(books).single.id,
        'B008',
      );
      expect(
        const BookFilter(author: 'Alan Dix').apply(books).single.id,
        'B004',
      );
    });
  });

  group('LibrarianValidators', () {
    test('ISBN', () {
      expect(LibrarianValidators.isbn(''), isNotNull);
      expect(LibrarianValidators.isbn('123'), contains('10 or 13'));
      expect(LibrarianValidators.isbn('abc'), isNotNull);
      expect(LibrarianValidators.isbn('978-0132350884'), isNull);
      expect(LibrarianValidators.isbn('0132350882'), isNull);
    });

    test('copies and seat number', () {
      expect(LibrarianValidators.positiveCount('0', 'Copies'), isNotNull);
      expect(LibrarianValidators.positiveCount('5', 'Copies'), isNull);
      expect(LibrarianValidators.seatNumber('D09'), isNull);
      expect(LibrarianValidators.seatNumber('9'), isNotNull);
    });
  });
}
