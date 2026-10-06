import '../../../models/user.dart';

const managerReportTypes = [
  'Reservations',
  'Popular Books',
  'Overdue Books',
  'Occupancy',
  'Peak Usage',
  'Users',
  'Conflicts',
];

enum ManagerReservationStatus { confirmed, conflict, pending, cancelled }

enum ManagerSeatState { available, reserved, conflict, selected }

class ManagerReservation {
  const ManagerReservation({
    required this.id,
    required this.book,
    required this.student,
    required this.studentId,
    required this.date,
    required this.time,
    required this.status,
    required this.seat,
  });

  final String id;
  final String book;
  final String student;
  final String studentId;
  final String date;
  final String time;
  final ManagerReservationStatus status;
  final String seat;
}

class ManagerUser {
  const ManagerUser({
    required this.name,
    required this.id,
    required this.role,
    required this.email,
    this.isActive = true,
    this.createdAt,
  });

  final String name;
  final String id;
  final String role;
  final String email;
  final bool isActive;
  final DateTime? createdAt;

  String get status => isActive ? 'Active' : 'Inactive';

  ManagerUser copyWith({
    String? name,
    String? id,
    String? role,
    String? email,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ManagerUser(
      name: name ?? this.name,
      id: id ?? this.id,
      role: role ?? this.role,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ManagerUserStore {
  ManagerUserStore._()
    : _users = [
        for (final user in managerUsers)
          user.copyWith(createdAt: DateTime(2026, 10, 2)),
      ];

  static final instance = ManagerUserStore._();

  final List<ManagerUser> _users;

  List<ManagerUser> get users => List.unmodifiable(_users);

  ManagerUser? findById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  void add(ManagerUser user) {
    final duplicate = _users.any(
      (existing) =>
          existing.id.toLowerCase() == user.id.toLowerCase() ||
          existing.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (duplicate) {
      throw const FormatException('A user with this ID or email already exists.');
    }
    _users.add(user);
  }

  void update(String id, ManagerUser updatedUser) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw StateError('The user no longer exists.');
    }
    final duplicate = _users.any(
      (existing) =>
          existing.id != id &&
          existing.email.toLowerCase() == updatedUser.email.toLowerCase(),
    );
    if (duplicate) {
      throw const FormatException('A user with this email already exists.');
    }
    _users[index] = updatedUser;
  }

  void deactivate(String id) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw StateError('The user no longer exists.');
    }
    _users[index] = _users[index].copyWith(isActive: false);
  }
}

String managerRoleLabel(UserRole role) {
  return switch (role) {
    UserRole.student => 'Student',
    UserRole.librarian => 'Librarian',
    UserRole.manager => 'Manager',
  };
}

UserRole managerRoleFromLabel(String label) {
  return UserRole.values.firstWhere(
    (role) => managerRoleLabel(role) == label,
  );
}

class ManagerNotice {
  const ManagerNotice({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final String time;
  final String kind;
}

class ManagerReportSelection {
  const ManagerReportSelection({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    this.format = 'CSV',
  });

  final String reportType;
  final DateTime startDate;
  final DateTime endDate;
  final String format;

  ManagerReportSelection copyWith({
    String? reportType,
    DateTime? startDate,
    DateTime? endDate,
    String? format,
  }) {
    return ManagerReportSelection(
      reportType: reportType ?? this.reportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      format: format ?? this.format,
    );
  }
}

const managerReservations = [
  ManagerReservation(
    id: 'RES-1024',
    book: 'Clean Code',
    student: 'Neranjala Gunarathne',
    studentId: 'IT23801234',
    date: '02 Oct 2026',
    time: '10:00 - 12:00',
    status: ManagerReservationStatus.confirmed,
    seat: 'A04',
  ),
  ManagerReservation(
    id: 'RES-1023',
    book: 'Database Systems',
    student: 'Hanse Perera',
    studentId: 'IT23801234',
    date: '02 Oct 2026',
    time: '11:00 AM - 01:00 PM',
    status: ManagerReservationStatus.conflict,
    seat: 'B12',
  ),
  ManagerReservation(
    id: 'RES-1022',
    book: 'Flutter in Action',
    student: 'Tharindu Silva',
    studentId: 'IT23807890',
    date: '01 Oct 2026',
    time: '02:00 - 04:00',
    status: ManagerReservationStatus.pending,
    seat: 'A08',
  ),
  ManagerReservation(
    id: 'RES-1021',
    book: 'Design Patterns',
    student: 'Sasindu Fernando',
    studentId: 'IT23804567',
    date: '01 Oct 2026',
    time: '09:00 - 11:00',
    status: ManagerReservationStatus.confirmed,
    seat: 'B03',
  ),
];

const managerUsers = [
  ManagerUser(
    name: 'Neranjala Gunarathne',
    id: 'IT23801234',
    role: 'Student',
    email: 'neranjala@libmate.com',
  ),
  ManagerUser(
    name: 'Hanse Perera',
    id: 'LIB001',
    role: 'Librarian',
    email: 'hanse@libmate.com',
  ),
  ManagerUser(
    name: 'Sasindu Fernando',
    id: 'IT23804567',
    role: 'Student',
    email: 'sasindu@libmate.com',
  ),
  ManagerUser(
    name: 'Tharindu Silva',
    id: 'IT23807890',
    role: 'Student',
    email: 'tharindu@libmate.com',
  ),
  ManagerUser(
    name: 'Admin',
    id: 'ADMIN001',
    role: 'Manager',
    email: 'admin@libmate.com',
  ),
];

const managerNotices = [
  ManagerNotice(
    title: 'Reservation conflict detected',
    subtitle: 'Seat B12 · 10:00 AM',
    time: '2h ago',
    kind: 'error',
  ),
  ManagerNotice(
    title: 'Reading room occupancy high',
    subtitle: 'Floor 2 · 92%',
    time: '3h ago',
    kind: 'error',
  ),
  ManagerNotice(
    title: '12 books are overdue',
    subtitle: 'Reminder sent to students',
    time: '5h ago',
    kind: 'warning',
  ),
  ManagerNotice(
    title: 'Reservation conflict resolved',
    subtitle: 'RES-1023 · Seat A08',
    time: '1d ago',
    kind: 'success',
  ),
  ManagerNotice(
    title: 'New user registered',
    subtitle: 'Tharindu Silva (Student)',
    time: '1d ago',
    kind: 'info',
  ),
];

const popularBooks = [
  ('Clean Code', '128 reservations'),
  ('Database Systems', '96 reservations'),
  ('Flutter in Action', '84 reservations'),
];

const overdueBooks = [
  ('12 books are overdue', 'Reminder sent to students'),
  ('Clean Code', '3 days overdue · 4 copies'),
  ('Design Patterns', '1 day overdue · 2 copies'),
];

const monthlyReservationCounts = [
  18, 27, 20, 36, 24, 42, 31, 26, 45, 38, 29, 48, 33, 22, 40, 35,
  47, 28, 37, 44, 30, 49, 34, 25, 41, 32, 46, 39, 27, 43, 35,
];
