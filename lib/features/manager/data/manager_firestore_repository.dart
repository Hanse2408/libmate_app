import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../models/action_result.dart';
import '../../../models/user.dart';
import 'manager_mock_data.dart';
import 'manager_repository.dart';

class ManagerFirestoreRepository extends ManagerRepository {
  ManagerFirestoreRepository({
    required FirebaseFirestore firestore,
    this.managerUid = '',
    Future<FirebaseApp> Function()? createSecondaryApp,
    FirebaseAuth Function(FirebaseApp)? secondaryAuthFor,
  }) : _db = firestore,
       _createSecondaryApp = createSecondaryApp ?? _initializeSecondaryApp,
       _secondaryAuthFor = secondaryAuthFor ?? _authForApp {
    _listen();
  }

  final FirebaseFirestore _db;
  final String managerUid;
  final Future<FirebaseApp> Function() _createSecondaryApp;
  final FirebaseAuth Function(FirebaseApp) _secondaryAuthFor;

  static Future<FirebaseApp> _initializeSecondaryApp() =>
      Firebase.initializeApp(
        name:
            'ManagerUserProvisioning-${DateTime.now().microsecondsSinceEpoch}',
        options: Firebase.app().options,
      );

  static FirebaseAuth _authForApp(FirebaseApp app) =>
      FirebaseAuth.instanceFor(app: app);

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
  Future<ActionResult> addUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? institutionId,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final cleanInstitutionId = institutionId?.trim().isEmpty ?? true
        ? null
        : institutionId!.trim();

    // A secondary Firebase App + its own FirebaseAuth instance lets us call
    // createUserWithEmailAndPassword for *another* account without touching
    // (or signing out) the Manager's own signed-in session on the default app.
    FirebaseApp? secondaryApp;
    FirebaseAuth? secondaryAuth;
    try {
      secondaryApp = await _createSecondaryApp();
      secondaryAuth = _secondaryAuthFor(secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final createdUser = credential.user;
      if (createdUser == null) {
        return const ActionResult.failure(
          'Could not confirm account creation. An incomplete Auth account may '
          'need manual cleanup.',
        );
      }
      final uid = createdUser.uid;
      try {
        // _db belongs to the default app, authenticated as the Manager.
        await _db.collection(FirestoreCollections.users).doc(uid).set({
          'uid': uid,
          'name': trimmedName,
          'email': trimmedEmail,
          'role': role.value,
          'studentId': cleanInstitutionId,
          'accountStatus': AccountStatus.active.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (error) {
        try {
          // Delete only the incomplete secondary account while still signed in.
          await createdUser.delete();
        } catch (rollbackError) {
          return ActionResult.failure(
            'Saving the profile failed ($error). Rollback also failed '
            '($rollbackError). An incomplete Auth account for $trimmedEmail '
            '($uid) may need manual cleanup.',
          );
        }
        return ActionResult.failure(
          'Saving the profile failed ($error). The incomplete login account '
          'was rolled back. Please try Add User again.',
        );
      }
      return const ActionResult.success();
    } on FirebaseAuthException catch (error) {
      return ActionResult.failure(_authErrorMessage(error));
    } catch (error) {
      return ActionResult.failure('Could not create the user: $error');
    } finally {
      // Cleanup must not mask the profile/rollback result, and app disposal
      // must still run if sign-out fails. Never touch default FirebaseAuth.
      try {
        await secondaryAuth?.signOut();
      } catch (_) {
        // The temporary app is disposed below.
      } finally {
        try {
          await secondaryApp?.delete();
        } catch (_) {
          // Account creation/rollback has already completed.
        }
      }
    }
  }

  @override
  Future<ActionResult> updateUser(
    String id, {
    required String name,
    required UserRole role,
    String? institutionId,
  }) async {
    if (id == managerUid && role != UserRole.manager) {
      return const ActionResult.failure('You cannot change your own role.');
    }
    final cleanInstitutionId = institutionId?.trim().isEmpty ?? true
        ? null
        : institutionId!.trim();
    try {
      await _db.collection(FirestoreCollections.users).doc(id).update({
        'name': name.trim(),
        'role': role.value,
        'studentId': cleanInstitutionId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const ActionResult.success();
    } catch (error) {
      return ActionResult.failure('Could not update the user: $error');
    }
  }

  @override
  Future<ActionResult> setAccountStatus(String id, AccountStatus status) async {
    if (id == managerUid) {
      return const ActionResult.failure(
        'You cannot change your own account status.',
      );
    }
    if (status == AccountStatus.suspended) {
      return const ActionResult.failure('Choose Active or Inactive.');
    }
    try {
      await _db.collection(FirestoreCollections.users).doc(id).update({
        'accountStatus': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const ActionResult.success();
    } catch (error) {
      return ActionResult.failure(
        'Could not update the account status: $error',
      );
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      default:
        return error.message ?? 'Could not create the account.';
    }
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
    final institutionId = ((data['studentId'] ?? data['staffId']) as String?)?.trim();
    return ManagerUser(
      name: (data['name'] as String?) ?? 'Unknown User',
      id: (data['uid'] as String?) ?? id,
      role: userRole,
      email: (data['email'] as String?) ?? '',
      institutionId: institutionId == null || institutionId.isEmpty ? null : institutionId,
      accountStatus: AccountStatus.fromMap(data),
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
