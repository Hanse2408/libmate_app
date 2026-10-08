import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../models/user.dart';
import 'manager_mock_data.dart';
import 'manager_repository.dart';

class ManagerFirestoreRepository extends ManagerRepository {
  ManagerFirestoreRepository({
    required FirebaseFirestore firestore,
    this.managerUid = '',
  }) : _db = firestore {
    _listen();
  }

  final FirebaseFirestore _db;
  final String managerUid;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _isLoading = true;
  String? _loadError;

  List<ManagerUser> _users = const [];
  List<ManagerReservation> _reservations = const [];
  List<ManagerNotice> _notices = const [];
  List<int> _policyValues = const [3, 5, 7, 2, 7];

  @override
  List<ManagerUser> get users => _users;

  @override
  List<ManagerReservation> get reservations => _reservations;

  @override
  List<ManagerNotice> get notices => _notices;

  @override
  List<int> get policyValues => _policyValues;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get loadError => _loadError;

  @override
  void addUser(ManagerUser user) {
    final payload = {
      'uid': user.id,
      'name': user.name,
      'email': user.email,
      'role': UserRole.fromValue(user.role).value,
      'isActive': user.isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _db.collection(FirestoreCollections.users).doc(user.id).set(payload, SetOptions(merge: true));
    final next = List<ManagerUser>.from(_users)..add(user);
    replaceUsers(next);
    notifyListeners();
  }

  @override
  void updateUser(String id, ManagerUser updatedUser) {
    final payload = {
      'uid': id,
      'name': updatedUser.name,
      'email': updatedUser.email,
      'role': UserRole.fromValue(updatedUser.role).value,
      'isActive': updatedUser.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _db.collection(FirestoreCollections.users).doc(id).set(payload, SetOptions(merge: true));
    final next = List<ManagerUser>.from(_users);
    final index = next.indexWhere((user) => user.id == id);
    if (index != -1) {
      next[index] = updatedUser;
      replaceUsers(next);
    }
    notifyListeners();
  }

  @override
  void deactivateUser(String id) {
    final payload = {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()};
    _db.collection(FirestoreCollections.users).doc(id).set(payload, SetOptions(merge: true));
    final next = List<ManagerUser>.from(_users);
    final index = next.indexWhere((user) => user.id == id);
    if (index != -1) {
      next[index] = next[index].copyWith(isActive: false);
      replaceUsers(next);
    }
    notifyListeners();
  }

  @override
  void deleteUser(String id) {
    final next = List<ManagerUser>.from(_users);
    final index = next.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw StateError('The user no longer exists.');
    }
    next.removeAt(index);
    replaceUsers(next);
    unawaited(_db.collection(FirestoreCollections.users).doc(id).delete());
    notifyListeners();
  }

  @override
  void resolveConflict(String reservationId, {required String newSeat}) {
    final next = List<ManagerReservation>.from(_reservations);
    final index = next.indexWhere((reservation) => reservation.id == reservationId);
    if (index == -1) {
      throw StateError('Reservation not found.');
    }
    final reservation = next[index];
    next[index] = ManagerReservation(
      id: reservation.id,
      book: reservation.book,
      student: reservation.student,
      studentId: reservation.studentId,
      date: reservation.date,
      time: reservation.time,
      status: ManagerReservationStatus.confirmed,
      seat: newSeat,
    );
    replaceReservations(next);
    _db.collection(FirestoreCollections.reservations).doc(reservationId).update({
      'status': 'approved',
      'seat': newSeat,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  @override
  void updatePolicyValue(int index, int value) {
    final current = List<int>.from(_policyValues);
    if (index < 0 || index >= current.length) {
      throw RangeError.index(index, current, 'index');
    }
    current[index] = value.clamp(1, 99);
    replacePolicyValues(current);
    final fieldMap = <String, dynamic>{
      'bookReservationLimit': current[0],
      'borrowingLimit': current[1],
      'reservationExpiryDays': current[2],
      'seatBookingHours': current[3],
      'advanceBookingDays': current[4],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _db.collection(FirestoreCollections.settings).doc(FirestoreCollections.librarySettingsDoc).set(
      fieldMap,
      SetOptions(merge: true),
    );
    notifyListeners();
  }

  void _listen() {
    _watchUsers();
    _watchReservations();
    _watchNotifications();
    _watchSettings();
  }

  void _watchUsers() {
    _subscriptions.add(
      _db.collection(FirestoreCollections.users).snapshots().listen((snapshot) {
        _users = [
          for (final doc in snapshot.docs)
            _userFromDoc(doc.id, doc.data()),
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isLoading = false;
        notifyListeners();
      }, onError: (Object error) {
        _loadError = 'Unable to load users from Firebase.';
        _isLoading = false;
        notifyListeners();
      }),
    );
  }

  void _watchReservations() {
    _subscriptions.add(
      _db.collection(FirestoreCollections.reservations).snapshots().listen((snapshot) {
        _reservations = [
          for (final doc in snapshot.docs)
            _reservationFromDoc(doc.id, doc.data()),
        ]..sort((a, b) => a.student.compareTo(b.student));
        notifyListeners();
      }, onError: (Object error) {
        _loadError = 'Unable to load reservations from Firebase.';
        notifyListeners();
      }),
    );
  }

  void _watchNotifications() {
    _subscriptions.add(
      _db.collection(FirestoreCollections.notifications).snapshots().listen((snapshot) {
        final docs = snapshot.docs.where((doc) {
          final audience = (doc.data()['audience'] as String?) ?? 'manager';
          return audience == 'manager' || audience == 'all';
        }).toList();
        _notices = [
          for (final doc in docs)
            _noticeFromDoc(doc.data()),
        ];
        if (_notices.isEmpty) {
          _notices = List<ManagerNotice>.from(managerNotices);
        }
        notifyListeners();
      }, onError: (Object error) {
        _notices = List<ManagerNotice>.from(managerNotices);
        notifyListeners();
      }),
    );
  }

  void _watchSettings() {
    _subscriptions.add(
      _db.collection(FirestoreCollections.settings).doc(FirestoreCollections.librarySettingsDoc).snapshots().listen((snapshot) {
        final data = snapshot.data() ?? {};
        final policyA = _readPolicyInt(data, 'bookReservationLimit', 'maxBorrowLimit', 3);
        final policyB = _readPolicyInt(data, 'borrowingLimit', 'loanPeriodDays', 5);
        final policyC = _readPolicyInt(data, 'reservationExpiryDays', 'reservationExpiryDays', 7);
        final policyD = _readPolicyInt(data, 'seatBookingHours', 'seatBookingHours', 2);
        final policyE = _readPolicyInt(data, 'advanceBookingDays', 'advanceBookingDays', 7);
        _policyValues = [policyA, policyB, policyC, policyD, policyE];
        notifyListeners();
      }, onError: (Object error) {
        _policyValues = const [3, 5, 7, 2, 7];
        notifyListeners();
      }),
    );
  }

  int _readPolicyInt(Map<String, dynamic> data, String canonicalKey, String legacyKey, int fallback) {
    final canonicalValue = data[canonicalKey];
    if (canonicalValue is num) return canonicalValue.toInt();
    final legacyValue = data[legacyKey];
    if (legacyValue is num) return legacyValue.toInt();
    return fallback;
  }

  ManagerUser _userFromDoc(String id, Map<String, dynamic> data) {
    final role = data['role'] as String? ?? UserRole.student.value;
    final userRole = managerRoleLabel(UserRole.fromValue(role));
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ManagerUser(
      name: (data['name'] as String?) ?? 'Unknown User',
      id: (data['uid'] as String?) ?? id,
      role: userRole,
      email: (data['email'] as String?) ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: createdAt,
    );
  }

  ManagerReservation _reservationFromDoc(String id, Map<String, dynamic> data) {
    final statusValue = (data['status'] as String?) ?? 'approved';
    final reservationStatus = switch (statusValue.toLowerCase()) {
      'conflict' => ManagerReservationStatus.conflict,
      'pending' => ManagerReservationStatus.pending,
      'cancelled' => ManagerReservationStatus.cancelled,
      _ => ManagerReservationStatus.confirmed,
    };
    final dateValue = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final startHour = (data['startHour'] as num?)?.toInt() ?? 9;
    final endHour = (data['endHour'] as num?)?.toInt() ?? 12;
    final title = (data['bookTitle'] as String?) ?? 'Library Resource';
    final studentName = (data['studentName'] as String?) ?? 'Student';
    final studentId = (data['studentId'] as String?) ?? 'N/A';
    final seat = (data['seat'] as String?) ?? (data['seatNumber'] as String?) ?? 'N/A';
    return ManagerReservation(
      id: id,
      book: title,
      student: studentName,
      studentId: studentId,
      date: _formatDate(dateValue),
      time: '$startHour:00 - ${endHour}00',
      status: reservationStatus,
      seat: seat,
    );
  }

  ManagerNotice _noticeFromDoc(Map<String, dynamic> data) {
    return ManagerNotice(
      title: (data['title'] as String?) ?? 'System update',
      subtitle: (data['message'] as String?) ?? 'Library update',
      time: (data['timeText'] as String?) ?? 'just now',
      kind: (data['kind'] as String?) ?? 'info',
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  void replaceUsers(List<ManagerUser> nextUsers) {
    _users = List<ManagerUser>.from(nextUsers);
  }

  @override
  void replaceReservations(List<ManagerReservation> nextReservations) {
    _reservations = List<ManagerReservation>.from(nextReservations);
  }

  @override
  void replacePolicyValues(List<int> values) {
    _policyValues = List<int>.from(values);
  }
}
