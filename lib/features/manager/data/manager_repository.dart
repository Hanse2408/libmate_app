import 'package:flutter/foundation.dart';

import '../../../models/action_result.dart';
import '../../../models/user.dart';
import 'manager_mock_data.dart';

abstract class ManagerRepository extends ChangeNotifier {
  List<ManagerUser> get users;
  List<ManagerReservation> get reservations;
  List<ManagerNotice> get notices;
  List<int> get policyValues;

  bool get isLoading => false;
  String? get loadError => null;
  bool get isDemoData => false;

  ManagerUser? findUserById(String id) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  /// Creates a user. For the live (Firestore) repository this also creates
  /// the matching Firebase Auth account using [password] and never signs the
  /// current Manager session out; the in-memory/demo repository ignores
  /// [password] since it has no real Auth backing it.
  Future<ActionResult> addUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? institutionId,
  }) async {
    final trimmedEmail = email.trim();
    final duplicate = users.any(
      (existing) => existing.email.toLowerCase() == trimmedEmail.toLowerCase(),
    );
    if (duplicate) {
      return const ActionResult.failure('A user with this email already exists.');
    }
    final newUser = ManagerUser(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: trimmedEmail,
      role: managerRoleLabel(role),
      institutionId: institutionId?.trim().isEmpty ?? true ? null : institutionId!.trim(),
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
    );
    final nextUsers = List<ManagerUser>.from(users)..add(newUser);
    replaceUsers(nextUsers);
    notifyListeners();
    return const ActionResult.success();
  }

  /// Updates the safe admin fields (name/role/institution id/accountStatus).
  /// Email is read-only here; see the class comment on the Firestore
  /// implementation for why.
  Future<ActionResult> updateUser(
    String id, {
    required String name,
    required UserRole role,
    required AccountStatus accountStatus,
    String? institutionId,
  }) async {
    final current = List<ManagerUser>.from(users);
    final index = current.indexWhere((user) => user.id == id);
    if (index == -1) {
      return const ActionResult.failure('The user no longer exists.');
    }
    current[index] = current[index].copyWith(
      name: name.trim(),
      role: managerRoleLabel(role),
      institutionId: institutionId?.trim().isEmpty ?? true ? null : institutionId!.trim(),
      accountStatus: accountStatus,
    );
    replaceUsers(current);
    notifyListeners();
    return const ActionResult.success();
  }

  /// Sets `accountStatus`. Used for Activate / Deactivate / Suspend and for
  /// "Remove Access" (which sets [AccountStatus.inactive] rather than
  /// deleting the Firestore profile or the Firebase Auth account).
  Future<ActionResult> setAccountStatus(String id, AccountStatus status) async {
    final current = List<ManagerUser>.from(users);
    final index = current.indexWhere((user) => user.id == id);
    if (index == -1) {
      return const ActionResult.failure('The user no longer exists.');
    }
    current[index] = current[index].copyWith(accountStatus: status);
    replaceUsers(current);
    notifyListeners();
    return const ActionResult.success();
  }

  ManagerReservation? findReservationById(String id) {
    for (final reservation in reservations) {
      if (reservation.id == id) return reservation;
    }
    return null;
  }

  void resolveConflict(String reservationId, {required String newSeat}) {
    final current = List<ManagerReservation>.from(reservations);
    final index = current.indexWhere((it) => it.id == reservationId);
    if (index == -1) throw StateError('Reservation not found.');
    final reservation = current[index];
    current[index] = ManagerReservation(
      id: reservation.id,
      book: reservation.book,
      student: reservation.student,
      studentId: reservation.studentId,
      date: reservation.date,
      time: reservation.time,
      status: ManagerReservationStatus.confirmed,
      seat: newSeat,
    );
    replaceReservations(current);
    notifyListeners();
  }

  void updatePolicyValue(int index, int value) {
    if (index < 0 || index >= policyValues.length) {
      throw RangeError.index(index, policyValues, 'index');
    }
    final safe = value.clamp(1, 99);
    final current = List<int>.from(policyValues)..[index] = safe;
    replacePolicyValues(current);
    notifyListeners();
  }

  void replaceUsers(List<ManagerUser> users);
  void replaceReservations(List<ManagerReservation> reservations);
  void replacePolicyValues(List<int> values);
}

class ManagerMockRepository extends ManagerRepository {
  ManagerMockRepository._()
    : _users = [
        for (final user in managerUsers)
          user.copyWith(createdAt: DateTime(2026, 10, 2)),
      ],
      _reservations = List<ManagerReservation>.from(managerReservations),
      _notices = List<ManagerNotice>.from(managerNotices),
      _policyValues = [3, 5, 7, 2, 7];

  static final instance = ManagerMockRepository._();

  final List<ManagerUser> _users;
  final List<ManagerReservation> _reservations;
  final List<ManagerNotice> _notices;
  final List<int> _policyValues;

  @override
  List<ManagerUser> get users => List.unmodifiable(_users);

  @override
  List<ManagerReservation> get reservations => List.unmodifiable(_reservations);

  @override
  List<ManagerNotice> get notices => List.unmodifiable(_notices);

  @override
  List<int> get policyValues => List.unmodifiable(_policyValues);

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
