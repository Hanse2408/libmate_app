import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/core/services/report_export_service.dart';
import 'package:libmate_app/features/manager/data/manager_mock_data.dart';
import 'package:libmate_app/features/manager/data/manager_repository.dart';
import 'package:libmate_app/models/user.dart';

class _TestManagerRepository extends ManagerRepository {
  _TestManagerRepository()
    : _users = [
        ManagerUser(
          id: 'repo-user-1',
          name: 'Repo Manager',
          email: 'repo.manager@libmate.com',
          role: 'manager',
          accountStatus: AccountStatus.active,
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
      _reservations = [
        ManagerReservation(
          id: 'R-9001',
          book: 'Repo Book',
          student: 'Repo Student',
          studentId: 'S-9001',
          date: '05 Oct 2026',
          time: '09:00 - 11:00',
          status: ManagerReservationStatus.confirmed,
          seat: 'A09',
        ),
      ],
      _notices = [
        ManagerNotice(
          title: 'Repo notice',
          subtitle: 'Saved from Firebase',
          time: 'just now',
          kind: 'info',
        ),
      ],
      _policyValues = [3, 5, 7, 2, 7];

  final List<ManagerUser> _users;
  final List<ManagerReservation> _reservations;
  final List<ManagerNotice> _notices;
  final List<int> _policyValues;

  @override
  List<ManagerUser> get users => _users;

  @override
  List<ManagerReservation> get reservations => _reservations;

  @override
  List<ManagerNotice> get notices => _notices;

  @override
  List<int> get policyValues => _policyValues;

  @override
  void replaceUsers(List<ManagerUser> users) {
    _users.clear();
    _users.addAll(users);
  }

  @override
  void replaceReservations(List<ManagerReservation> reservations) {
    _reservations.clear();
    _reservations.addAll(reservations);
  }

  @override
  void replacePolicyValues(List<int> values) {
    _policyValues.clear();
    _policyValues.addAll(values);
  }
}

void main() {
  group('Manager report export', () {
    test('creates CSV content for the users report', () async {
      final csv = ReportExportService.generateCsv(
        ManagerReportSelection(
          reportType: 'Users',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 6),
          format: 'CSV',
        ),
      );

      expect(csv, contains('name'));
      expect(csv, contains('email'));
      expect(csv, contains('Neranjala Gunarathne'));
      expect(csv, contains('Student'));
    });

    test('creates CSV content for the reservations report', () {
      final csv = ReportExportService.generateCsv(
        ManagerReportSelection(
          reportType: 'Reservations',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 6),
          format: 'CSV',
        ),
      );

      expect(csv, contains('reservationId'));
      expect(csv, contains('book'));
      expect(csv, contains('RES-1024'));
    });

    test('uses the provided repository data for CSV generation', () {
      final repository = _TestManagerRepository();
      final csv = ReportExportService.generateCsv(
        ManagerReportSelection(
          reportType: 'Users',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 6),
          format: 'CSV',
        ),
        repository: repository,
      );

      expect(csv, contains('Repo Manager'));
      expect(csv, contains('repo.manager@libmate.com'));
      expect(csv, isNot(contains('Neranjala Gunarathne')));
    });

    test('uses live reservation aggregates for the popular books report', () {
      final repository = _TestManagerRepository();
      final csv = ReportExportService.generateCsv(
        ManagerReportSelection(
          reportType: 'Popular Books',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 6),
          format: 'CSV',
        ),
        repository: repository,
      );

      expect(csv, contains('title'));
      expect(csv, contains('Repo Book'));
      expect(csv, contains('1 reservations'));
      expect(csv, isNot(contains('Clean Code')));
    });

    test('normalizes capitalized role labels before Firestore writes', () {
      expect(UserRole.fromValue('Manager'), UserRole.manager);
      expect(UserRole.fromValue('Librarian'), UserRole.librarian);
      expect(UserRole.fromValue('Student'), UserRole.student);
    });

    test(
      'Remove Access keeps the record but flips accountStatus to inactive',
      () async {
        final repository = _TestManagerRepository();
        final result = await repository.setAccountStatus(
          'repo-user-1',
          AccountStatus.inactive,
        );
        expect(result.success, isTrue);

        // The record is kept for audit/reference - it is not deleted.
        final user = repository.users.singleWhere(
          (user) => user.id == 'repo-user-1',
        );
        expect(user.accountStatus, AccountStatus.inactive);
        expect(user.status, 'Inactive');

        final csv = ReportExportService.generateCsv(
          ManagerReportSelection(
            reportType: 'Users',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 10, 6),
            format: 'CSV',
          ),
          repository: repository,
        );

        expect(csv, contains('name'));
        expect(csv, contains('Repo Manager'));
        expect(csv, contains('Inactive'));
      },
    );
  });
}
