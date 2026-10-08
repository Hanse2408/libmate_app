import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/librarian/models/borrowing_record.dart';
import 'package:libmate_app/features/librarian/models/member_record.dart';
import 'package:libmate_app/features/librarian/providers/borrowing_filter.dart';
import 'package:libmate_app/features/librarian/providers/librarian_report.dart';
import 'package:libmate_app/features/librarian/providers/member_filter.dart';

void main() {
  late LibrarianMockRepository repository;

  setUp(() => repository = LibrarianMockRepository());

  group('Borrowings', () {
    test('statuses are calculated from the dates', () {
      final counts = BorrowingFilter.countByStatus(repository.borrowings);
      expect(counts[BorrowingStatus.active], 10);
      expect(counts[BorrowingStatus.dueToday], 2);
      expect(counts[BorrowingStatus.overdue], 4);
      expect(counts[BorrowingStatus.returned], 4);
    });

    test('filter by status and search', () {
      final loans = repository.borrowings;
      expect(
        const BorrowingFilter(status: BorrowingStatus.overdue)
            .apply(loans)
            .length,
        4,
      );
      expect(
        const BorrowingFilter(query: 'LN-2011').apply(loans).single.memberName,
        'Nimali Perera',
      );
      expect(const BorrowingFilter(query: 'it23003341').apply(loans).length, 2);
      expect(
        const BorrowingFilter(query: '9780262046305').apply(loans).length,
        4,
      );
      // Overdue loans are listed first.
      expect(
        const BorrowingFilter().apply(loans).first.status,
        BorrowingStatus.overdue,
      );
    });

    test(
      'returning a loan puts the copy back; it cannot be returned twice',
      () async {
        final copies = repository.bookById('B001')!.availableCopies;

        final result = await repository.markBorrowingReturned('LN-2002');
        expect(result.success, isTrue);
        expect(
          repository.borrowingById('LN-2002')!.status,
          BorrowingStatus.returned,
        );
        expect(repository.bookById('B001')!.availableCopies, copies + 1);

        final again = await repository.markBorrowingReturned('LN-2002');
        expect(again.success, isFalse);
        expect(again.message, contains('already been returned'));
        expect(repository.bookById('B001')!.availableCopies, copies + 1);
      },
    );

    test('renewing extends the due date by the loan period', () async {
      final before = repository.borrowingById('LN-2011')!;
      final result = await repository.renewBorrowing('LN-2011');

      expect(result.success, isTrue);
      final after = repository.borrowingById('LN-2011')!;
      expect(after.dueDate, before.dueDate.add(const Duration(days: 14)));
      expect(after.renewals, 1);
    });

    test(
      'renewal limit, overdue, returned and reserved books are refused',
      () async {
        await repository.renewBorrowing('LN-2011');
        await repository.renewBorrowing('LN-2011');
        expect(
          (await repository.renewBorrowing('LN-2011')).message,
          contains('2 times'),
        );

        expect(
          (await repository.renewBorrowing('LN-2003')).message,
          contains('Overdue'),
        );
        expect(
          (await repository.renewBorrowing('LN-1990')).message,
          contains('returned'),
        );
        // RSV-1001 is a pending reservation for Clean Code.
        expect(
          (await repository.renewBorrowing('LN-2001')).message,
          contains('reserved'),
        );
      },
    );

    test('renewal uses the loan period from Settings', () async {
      await repository.updateSettings(
        repository.settings.copyWith(loanPeriodDays: 7),
      );
      final before = repository.borrowingById('LN-2007')!.dueDate;
      await repository.renewBorrowing('LN-2007');
      expect(
        repository.borrowingById('LN-2007')!.dueDate,
        before.add(const Duration(days: 7)),
      );
    });
  });

  group('Members', () {
    test('counts come from loans and reservations', () {
      expect(repository.members.length, 15);
      expect(repository.currentLoanCount('IT23004512'), 2); // Nethmi
      expect(repository.activeReservationCount('IT23004512'), 1);
      expect(repository.overdueLoanCount('IT23003341'), 1); // Sachini
      expect(repository.borrowingsForMember('IT23004512').length, 3);
    });

    test('search and filters', () {
      expect(
        const MemberFilter(query: 'sachini').apply(repository).single.id,
        'IT23003341',
      );
      expect(
        const MemberFilter(query: 'it23514658@my')
            .apply(repository)
            .single
            .name,
        'Nilumi Dakshika',
      );
      expect(
        const MemberFilter(option: MemberFilterOption.overdue)
            .apply(repository)
            .length,
        4,
      );
      expect(
        const MemberFilter(option: MemberFilterOption.suspended)
            .apply(repository)
            .single
            .name,
        'Amaya Senanayake',
      );
    });

    test('Librarians cannot change member account status', () async {
      for (final status in MemberStatus.values) {
        final result = await repository.updateMemberStatus('IT23004512', status);
        expect(result.success, isFalse);
        expect(result.message, contains('Only Managers'));
      }
      expect(repository.memberById('IT23004512')!.isActive, isTrue);
    });
  });

  group('Settings', () {
    test('valid changes are saved, invalid ones refused', () async {
      expect(repository.settings.loanPeriodDays, 14);
      final ok = await repository.updateSettings(
        repository.settings.copyWith(maxBorrowLimit: 8),
      );
      expect(ok.success, isTrue);
      expect(repository.settings.maxBorrowLimit, 8);

      final badHours = await repository.updateSettings(
        repository.settings.copyWith(openingHour: 20, closingHour: 8),
      );
      expect(badHours.success, isFalse);
      expect(repository.settings.openingHour, 8);
    });
  });

  group('LibrarianReport', () {
    test('weekly summary values', () {
      final report = LibrarianReport.fromRepository(
        repository,
        ReportPeriod.weekly,
      );

      expect(report.totalTitles, 9);
      expect(report.totalCopies, 32);
      expect(report.loansOut, 16);
      expect(report.overdueLoans, 4);
      expect(report.returnedInPeriod, 1);
      expect(report.reservationsInPeriod, 13);
      expect(report.countFor(report.reservationStatus, 'Pending'), 6);
      expect(report.countFor(report.reservationStatus, 'Approved'), 4);
      expect(report.countFor(report.reservationStatus, 'Rejected'), 1);
      expect(report.occupancyRate, closeTo(8 / 17, 0.001));
      expect(report.mostReserved.first, (
        label: 'Introduction to Algorithms',
        count: 2,
      ));
      expect(report.countFor(report.bookingPeriods, 'Morning'), 2);
      expect(report.countFor(report.bookingPeriods, 'Afternoon'), 5);
      expect(report.activity.length, 7);
      expect(report.activity.fold<int>(0, (sum, e) => sum + e.count), 13);
    });

    test('monthly view covers 4 weeks', () {
      final report = LibrarianReport.fromRepository(
        repository,
        ReportPeriod.monthly,
      );
      expect(report.activity.length, 4);
      expect(report.returnedInPeriod, 4);
      expect(report.mostBorrowed.first, (
        label: 'Introduction to Algorithms',
        count: 4,
      ));
    });

    test('reflects changes in the repository', () async {
      await repository.markBorrowingReturned('LN-2003');
      final report = LibrarianReport.fromRepository(
        repository,
        ReportPeriod.weekly,
      );
      expect(report.overdueLoans, 3);
      expect(report.returnedInPeriod, 2);
    });
  });
}
