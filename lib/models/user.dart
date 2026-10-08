import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles supported by the app, matching the `role` field in Firestore `users/{uid}` docs.
enum UserRole {
  student,
  librarian,
  manager;

  String get value => name;

  /// Lenient parse used for display/listing (e.g. the Manager's user list),
  /// where a malformed document should still show up rather than crash.
  /// Unrecognised values default to [student].
  static UserRole fromValue(String value) {
    final normalized = value.trim().toLowerCase();
    return UserRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => UserRole.student,
    );
  }

  /// Strict parse used for authentication: returns null instead of guessing,
  /// so sign-in can refuse an invalid/missing role rather than silently
  /// defaulting someone into the Student area.
  static UserRole? tryFromValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.name == normalized) return role;
    }
    return null;
  }
}

/// Canonical login-eligibility field stored at `users/{uid}.accountStatus`.
/// This is the single source of truth; the legacy boolean `isActive` field
/// (if still present on older documents) is only read as a fallback.
enum AccountStatus {
  active,
  inactive,
  suspended;

  String get value => name;

  static AccountStatus fromValue(String value) {
    final normalized = value.trim().toLowerCase();
    return AccountStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => AccountStatus.active,
    );
  }

  /// Resolves `accountStatus`, falling back to the legacy `isActive` bool
  /// (`false` -> inactive) only when `accountStatus` is missing entirely.
  static AccountStatus fromMap(Map<String, dynamic> map) {
    final raw = map['accountStatus'] as String?;
    if (raw != null && raw.trim().isNotEmpty) return AccountStatus.fromValue(raw);
    final legacyActive = map['isActive'] as bool?;
    if (legacyActive == false) return AccountStatus.inactive;
    return AccountStatus.active;
  }
}

/// Thrown by [AppUser.fromMap] when `users/{uid}.role` is missing or does not
/// match a known [UserRole]. The Firestore role is authoritative, so the
/// caller (the login flow) must refuse the sign-in instead of guessing.
class InvalidUserRoleException implements Exception {
  const InvalidUserRoleException(this.rawRole);

  final String? rawRole;

  @override
  String toString() => 'InvalidUserRoleException(rawRole: $rawRole)';
}

/// Shared user profile stored in Firestore at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.accountStatus = AccountStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;

  /// Human-readable Student ID (students) or Staff ID (librarians/managers).
  /// Separate from [uid], which is always the Firebase Auth UID.
  final String? studentId;
  final String email;
  final UserRole role;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Parses a `users/{uid}` document. Throws [InvalidUserRoleException] when
  /// the role is missing/unrecognised, so the login flow can refuse sign-in
  /// instead of silently defaulting to Student.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    final rawRole = map['role'] as String?;
    final role = UserRole.tryFromValue(rawRole);
    if (role == null) {
      throw InvalidUserRoleException(rawRole);
    }
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String? ?? '',
      studentId: map['studentId'] as String?,
      email: map['email'] as String? ?? '',
      role: role,
      accountStatus: AccountStatus.fromMap(map),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'studentId': studentId,
      'email': email,
      'role': role.value,
      'accountStatus': accountStatus.value,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? name,
    String? studentId,
    String? email,
    UserRole? role,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
