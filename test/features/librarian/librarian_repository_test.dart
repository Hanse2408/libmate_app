import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/librarian/models/reservation_record.dart';
import 'package:libmate_app/features/librarian/models/seat_record.dart';

void main() {
  late LibrarianMockRepository repository;

  setUp(() => repository = LibrarianMockRepository());

  int pendingCount() => repository.reservations.where((r) => r.isPending).length;

  group('Approving reservations', () {
    test('available book is approved and one copy is taken', () async {
      final before = repository.bookById('B001')!.availableCopies;
      final result = await repository.approveReservation('RSV-1001');

      expect(result.success, isTrue);
      expect(repository.reservationById('RSV-1001')!.status, ReservationStatus.approved);
      expect(repository.bookById('B001')!.availableCopies, before - 1);
      expect(pendingCount(), 5);
    });

    test('book with no copies is refused and stays pending', () async {
      final result = await repository.approveReservation('RSV-1010');

      expect(result.success, isFalse);
      expect(result.message, contains('No copies'));
      expect(repository.reservationById('RSV-1010')!.isPending, isTrue);
      expect(repository.bookById('B002')!.availableCopies, 0);
    });

    test('available seat is approved and becomes reserved', () async {
      final result = await repository.approveReservation('RSV-1002');

      expect(result.success, isTrue);
      expect(repository.seatById('S001')!.status, SeatStatus.reserved);
    });

    test('maintenance seat is refused and stays pending', () async {
      final result = await repository.approveReservation('RSV-1011');

      expect(result.success, isFalse);
      expect(result.message, contains('maintenance'));
      expect(repository.reservationById('RSV-1011')!.isPending, isTrue);
      expect(repository.seatById('S011')!.status, SeatStatus.maintenance);
    });

    test('cannot approve the same reservation twice', () async {
      await repository.approveReservation('RSV-1001');
      final copies = repository.bookById('B001')!.availableCopies;

      final second = await repository.approveReservation('RSV-1001');
      expect(second.success, isFalse);
      expect(repository.bookById('B001')!.availableCopies, copies);
    });

    test('approvalBlocker explains conflicts', () {
      expect(repository.approvalBlocker(repository.reservationById('RSV-1001')!), isNull);
      expect(repository.approvalBlocker(repository.reservationById('RSV-1010')!), isNotNull);
      expect(repository.approvalBlocker(repository.reservationById('RSV-1011')!), isNotNull);
    });

    test('approval marks the related request notification as read', () async {
      final unreadBefore = repository.unreadNotificationCount;
      await repository.approveReservation('RSV-1001'); // N004 was unread
      expect(repository.unreadNotificationCount, unreadBefore - 1);
    });
  });

  group('Rejecting reservations', () {
    test('pending reservation is rejected with the reason', () async {
      final result = await repository.rejectReservation('RSV-1003', 'Duplicate request');

      expect(result.success, isTrue);
      final reservation = repository.reservationById('RSV-1003')!;
      expect(reservation.status, ReservationStatus.rejected);
      expect(reservation.rejectionReason, 'Duplicate request');
      expect(pendingCount(), 5);
    });

    test('cannot reject twice or reject an approved reservation', () async {
      await repository.rejectReservation('RSV-1003', 'Duplicate request');
      expect((await repository.rejectReservation('RSV-1003', 'Again')).success, isFalse);
      expect((await repository.rejectReservation('RSV-1004', 'No')).success, isFalse);
    });
  });

  group('Books', () {
    test('new book is added at the top with all copies available', () async {
      final result = await repository.addBook(
        title: 'Refactoring',
        author: 'Martin Fowler',
        isbn: '9780134757599',
        category: 'Software Engineering',
        language: 'English',
        shelfLocation: 'se-02-a',
        totalCopies: 3,
      );

      expect(result.success, isTrue);
      final book = repository.books.first;
      expect(book.title, 'Refactoring');
      expect(book.availableCopies, 3);
      expect(book.shelfLocation, 'SE-02-A');
    });

    test('duplicate ISBN is refused (hyphens ignored)', () async {
      final result = await repository.addBook(
        title: 'Copy',
        author: 'Someone',
        isbn: '978-0132350884',
        category: 'x',
        language: 'English',
        shelfLocation: 'X-1',
        totalCopies: 1,
      );
      expect(result.success, isFalse);
    });

    test('total copies cannot drop below copies already out', () async {
      final book = repository.bookById('B001')!; // 5 total, 2 available
      Future<bool> update(int total) async => (await repository.updateBook(
        id: book.id,
        title: book.title,
        author: book.author,
        isbn: book.isbn,
        category: book.category,
        language: book.language,
        shelfLocation: book.shelfLocation,
        totalCopies: total,
      )).success;

      expect(await update(2), isFalse);
      expect(await update(6), isTrue);
      expect(repository.bookById('B001')!.availableCopies, 3);
    });
  });

  group('Seats', () {
    test('new seat is added as available', () async {
      final result = await repository.addSeat(
        seatNumber: 'd09',
        zone: 'Row D',
        readingRoom: 'Reading Room A',
        type: SeatType.individualDesk,
      );

      expect(result.success, isTrue);
      expect(repository.seats.last.seatNumber, 'D09');
      expect(repository.seats.last.status, SeatStatus.available);
    });

    test('duplicate seat number in the same room is refused', () async {
      final result = await repository.addSeat(
        seatNumber: 'a01',
        zone: 'Row A',
        readingRoom: 'reading room a',
        type: SeatType.quietZone,
      );
      expect(result.success, isFalse);
    });
  });

  group('Notifications', () {
    test('mark one and mark all as read', () async {
      expect(repository.unreadNotificationCount, 4);
      await repository.markNotificationRead('N002');
      expect(repository.unreadNotificationCount, 3);
      await repository.markAllNotificationsRead();
      expect(repository.unreadNotificationCount, 0);
    });
  });
}
