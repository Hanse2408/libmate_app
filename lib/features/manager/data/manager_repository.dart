import 'package:flutter/foundation.dart';

import '../../../models/action_result.dart';
import '../../../models/user.dart';
import '../../../models/seat.dart';
import '../../../models/reservation.dart';
import 'manager_mock_data.dart';

abstract class ManagerRepository extends ChangeNotifier {
  List<ManagerUser> get users;
  List<ManagerReservation> get reservations;
  List<ManagerNotice> get notices;
  List<int> get policyValues;

  bool get isLoading => false;
  String? get loadError => null;
  bool get isDemoData => false;

  List<SeatRecord> get seats => const [];
  bool get reservationsLoading => isLoading;
  String? get reservationsError => loadError;
  bool get seatsLoading => false;
  String? get seatsError => null;
  DateTime get monitoringTime => DateTime.now();

  SeatStatus seatStatus(SeatRecord seat, {DateTime? at}) {
    if (seat.status != SeatStatus.available) return seat.status;
    final now = at ?? monitoringTime;
    for (final reservation in reservations) {
      final day = reservation.bookingDate;
      if (reservation.type != ReservationType.seat ||
          reservation.status != ManagerReservationStatus.confirmed ||
          reservation.itemId != seat.id || day == null ||
          day.year != now.year || day.month != now.month || day.day != now.day) {
        continue;
      }
      final parts = reservation.time.split('-');
      if (parts.length != 2) continue;
      int? minutes(String part) {
        final hm = part.trim().split(':');
        if (hm.length != 2) return null;
        final h = int.tryParse(hm[0]);
        final m = int.tryParse(hm[1]);
        return h == null || m == null ? null : h * 60 + m;
      }
      final start = minutes(parts.first);
      final end = minutes(parts.last);
      final current = now.hour * 60 + now.minute;
      if (start != null && end != null && start <= current && current < end) {
        return SeatStatus.reserved;
      }
    }
    return SeatStatus.available;
  }

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
      return const ActionResult.failure(
        'A user with this email already exists.',
      );
    }
    final newUser = ManagerUser(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: trimmedEmail,
      role: managerRoleLabel(role),
      institutionId: institutionId?.trim().isEmpty ?? true
          ? null
          : institutionId!.trim(),
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
    );
    final nextUsers = List<ManagerUser>.from(users)..add(newUser);
    replaceUsers(nextUsers);
    notifyListeners();
    return const ActionResult.success();
  }

  /// Updates name, role and institution ID; status has separate actions.
  /// Email is read-only here; see the class comment on the Firestore
  /// implementation for why.
  Future<ActionResult> updateUser(
    String id, {
    required String name,
    required UserRole role,
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
      institutionId: institutionId?.trim().isEmpty ?? true
          ? null
          : institutionId!.trim(),
    );
    replaceUsers(current);
    notifyListeners();
    return const ActionResult.success();
  }

  /// Sets account status through Activate / Deactivate.
  Future<ActionResult> setAccountStatus(String id, AccountStatus status) async {
    if (status == AccountStatus.suspended) {
      return const ActionResult.failure('Choose Active or Inactive.');
    }
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

  Future<ActionResult> resolveConflict(String reservationId, {required String newSeat}) async {
    return const ActionResult.failure('Seat reassignment is unavailable. No conflict engine is configured.');
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
