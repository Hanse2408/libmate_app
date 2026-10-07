import 'package:flutter/foundation.dart';

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

  void addUser(ManagerUser user) {
    final duplicate = users.any(
      (existing) =>
          existing.id.toLowerCase() == user.id.toLowerCase() ||
          existing.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (duplicate) {
      throw const FormatException('A user with this ID or email already exists.');
    }
    final nextUsers = List<ManagerUser>.from(users)..add(user);
    replaceUsers(nextUsers);
    notifyListeners();
  }

  void updateUser(String id, ManagerUser updatedUser) {
    final current = List<ManagerUser>.from(users);
    final index = current.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw StateError('The user no longer exists.');
    }
    final duplicate = current.any(
      (existing) =>
          existing.id != id &&
          existing.email.toLowerCase() == updatedUser.email.toLowerCase(),
    );
    if (duplicate) {
      throw const FormatException('A user with this email already exists.');
    }
    current[index] = updatedUser;
    replaceUsers(current);
    notifyListeners();
  }

  void deactivateUser(String id) {
    final current = List<ManagerUser>.from(users);
    final index = current.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw StateError('The user no longer exists.');
    }
    current[index] = current[index].copyWith(isActive: false);
    replaceUsers(current);
    notifyListeners();
  }

  void deleteUser(String id) {
    final current = List<ManagerUser>.from(users);
    final index = current.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw StateError('The user no longer exists.');
    }
    current.removeAt(index);
    replaceUsers(current);
    notifyListeners();
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

class ManagerUserStore {
  const ManagerUserStore._();

  static final instance = _ManagerUserStoreAdapter();
}

class _ManagerUserStoreAdapter {
  List<ManagerUser> get users => ManagerMockRepository.instance.users;

  ManagerUser? findById(String id) => ManagerMockRepository.instance.findUserById(id);

  void add(ManagerUser user) => ManagerMockRepository.instance.addUser(user);

  void update(String id, ManagerUser updatedUser) =>
      ManagerMockRepository.instance.updateUser(id, updatedUser);

  void deactivate(String id) =>
      ManagerMockRepository.instance.deactivateUser(id);

  void delete(String id) => ManagerMockRepository.instance.deleteUser(id);
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
