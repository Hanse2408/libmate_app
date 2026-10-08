import '../models/book_record.dart';
import '../models/borrowing_record.dart';
import '../models/librarian_notification.dart';
import '../models/member_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';

/// Sample data for the Librarian module while Firebase is not connected.
/// Dates are relative to "now" so the data always looks current.
///
/// Covers every case the screens need: available / low-stock / no-copy books,
/// available / reserved / occupied / maintenance seats, pending requests that
/// can and cannot be approved, and approved / rejected / completed /
/// cancelled reservations.
class LibrarianMockData {
  const LibrarianMockData._();

  static List<BookRecord> books() => const [
    BookRecord(
      id: 'B001',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'SE-01-A',
      totalCopies: 5,
      availableCopies: 2,
      description: 'A handbook of agile software craftsmanship.',
    ),
    BookRecord(
      id: 'B002',
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      isbn: '9780262046305',
      category: 'Computer Science',
      language: 'English',
      shelfLocation: 'CS-02-B',
      totalCopies: 4,
      availableCopies: 0,
      description: 'Comprehensive coverage of modern algorithms.',
    ),
    BookRecord(
      id: 'B003',
      title: 'Database System Concepts',
      author: 'Abraham Silberschatz',
      isbn: '9780078022159',
      category: 'Computer Science',
      language: 'English',
      shelfLocation: 'DB-01-C',
      totalCopies: 3,
      availableCopies: 1,
    ),
    BookRecord(
      id: 'B004',
      title: 'Human-Computer Interaction',
      author: 'Alan Dix',
      isbn: '9780130461094',
      category: 'HCI',
      language: 'English',
      shelfLocation: 'HCI-03-A',
      totalCopies: 6,
      availableCopies: 4,
      description: 'Core principles of interaction design and usability.',
    ),
    BookRecord(
      id: 'B005',
      title: 'Computer Networking: A Top-Down Approach',
      author: 'James F. Kurose',
      isbn: '9780133594140',
      category: 'Networking',
      language: 'English',
      shelfLocation: 'NW-02-D',
      totalCopies: 3,
      availableCopies: 3,
    ),
    BookRecord(
      id: 'B006',
      title: 'Design Patterns',
      author: 'Erich Gamma',
      isbn: '9780201633610',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'SE-01-B',
      totalCopies: 2,
      availableCopies: 0,
    ),
    BookRecord(
      id: 'B007',
      title: 'Operating System Concepts',
      author: 'Abraham Silberschatz',
      isbn: '9781119800361',
      category: 'Computer Science',
      language: 'English',
      shelfLocation: 'CS-14-B',
      totalCopies: 4,
      availableCopies: 2,
    ),
    BookRecord(
      id: 'B008',
      title: 'Madol Doova',
      author: 'Martin Wickramasinghe',
      isbn: '9789552101012',
      category: 'Novel',
      language: 'Sinhala',
      shelfLocation: 'LIT-02-A',
      totalCopies: 3,
      availableCopies: 2,
    ),
    BookRecord(
      id: 'B009',
      title: 'Financial Accounting',
      author: 'Jerry J. Weygandt',
      isbn: '9781119594604',
      category: 'Business',
      language: 'English',
      shelfLocation: 'BUS-05-C',
      totalCopies: 2,
      availableCopies: 0,
    ),
  ];

  static List<SeatRecord> seats() => [
    _seat('S001', 'A01', SeatStatus.available, power: true, lamp: true),
    _seat('S002', 'A02', SeatStatus.available),
    _seat('S003', 'A03', SeatStatus.occupied),
    _seat('S004', 'A04', SeatStatus.occupied),
    _seat('S005', 'A05', SeatStatus.reserved, power: true),
    _seat('S006', 'A06', SeatStatus.available, window: true),
    _seat('S007', 'B01', SeatStatus.reserved, power: true),
    _seat('S008', 'B02', SeatStatus.available),
    _seat('S009', 'B03', SeatStatus.occupied),
    _seat('S010', 'B04', SeatStatus.available),
    _seat('S011', 'B05', SeatStatus.maintenance, note: 'Broken chair, repair requested.'),
    _seat('S012', 'B06', SeatStatus.reserved, window: true),
    _seat('S013', 'C01', SeatStatus.available, power: true, accessible: true),
    _seat('S014', 'C02', SeatStatus.occupied),
    _seat('S015', 'C03', SeatStatus.available),
    _seat('S016', 'C04', SeatStatus.available, power: true),
    _seat('S017', 'C05', SeatStatus.occupied),
    _seat('S018', 'C06', SeatStatus.available, window: true),
  ];

  /// Row A = Quiet Zone, Row B = Group Study, Row C = Individual Desks.
  static SeatRecord _seat(
    String id,
    String number,
    SeatStatus status, {
    bool power = false,
    bool lamp = false,
    bool accessible = false,
    bool window = false,
    String note = '',
  }) {
    final row = number[0];
    final type = switch (row) {
      'A' => SeatType.quietZone,
      'B' => SeatType.groupStudy,
      _ => SeatType.individualDesk,
    };
    return SeatRecord(
      id: id,
      seatNumber: number,
      zone: 'Row $row',
      readingRoom: 'Reading Room A',
      type: type,
      status: status,
      hasPowerOutlet: power,
      hasReadingLamp: lamp,
      isAccessible: accessible,
      isNearWindow: window,
      note: note,
    );
  }

  static List<ReservationRecord> reservations() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final membersById = {for (final member in members()) member.id: member};
    final seatsById = {for (final seat in seats()) seat.id: seat};
    Duration days(int n) => Duration(days: n);

    ReservationRecord reservation({
      required String id,
      required ReservationType type,
      required ReservationStatus status,
      required String studentId,
      required String itemId,
      required String itemName,
      required DateTime requestedAt,
      required DateTime date,
      String? timeSlot,
      String? note,
      String? rejectionReason,
    }) {
      final member = membersById[studentId];
      final seat = seatsById[itemId];
      final resolvedName = member?.name ?? 'Student';
      final resolvedEmail = member?.email ?? 'student@library.local';
      final resolvedItemName = seat != null ? 'Seat ${seat.seatNumber}' : itemName;

      return ReservationRecord(
        id: id,
        type: type,
        status: status,
        studentId: studentId,
        studentName: resolvedName,
        studentEmail: resolvedEmail,
        itemId: itemId,
        itemName: resolvedItemName,
        requestedAt: requestedAt,
        date: date,
        timeSlot: timeSlot,
        note: note,
        rejectionReason: rejectionReason,
      );
    }

    return [
      reservation(
        id: 'RSV-1001',
        type: ReservationType.book,
        status: ReservationStatus.pending,
        studentId: 'IT23004512',
        itemId: 'B001',
        itemName: 'Clean Code',
        requestedAt: now.subtract(const Duration(minutes: 25)),
        date: today.add(days(1)),
        timeSlot: '10:00',
        note: 'Needed for the SE group assignment.',
      ),
      reservation(
        id: 'RSV-1002',
        type: ReservationType.seat,
        status: ReservationStatus.pending,
        studentId: 'IT23007789',
        itemId: 'S001',
        itemName: 'Seat A01',
        requestedAt: now.subtract(const Duration(hours: 1)),
        date: today,
        timeSlot: '13:00 - 15:00',
        note: 'Requested a quiet-zone seat for exam preparation.',
      ),
      reservation(
        id: 'RSV-1003',
        type: ReservationType.book,
        status: ReservationStatus.pending,
        studentId: 'IT23003341',
        itemId: 'B004',
        itemName: 'Human-Computer Interaction',
        requestedAt: now.subtract(const Duration(hours: 3)),
        date: today.add(days(2)),
        timeSlot: '14:30',
      ),
      reservation(
        id: 'RSV-1004',
        type: ReservationType.seat,
        status: ReservationStatus.approved,
        studentId: 'IT23817194',
        itemId: 'S005',
        itemName: 'Seat A05',
        requestedAt: now.subtract(const Duration(hours: 5)),
        date: today,
        timeSlot: '10:00 - 14:00',
      ),
      reservation(
        id: 'RSV-1005',
        type: ReservationType.book,
        status: ReservationStatus.approved,
        studentId: 'IT23001178',
        itemId: 'B003',
        itemName: 'Database System Concepts',
        requestedAt: now.subtract(days(1)),
        date: today,
        timeSlot: '10:30',
      ),
      reservation(
        id: 'RSV-1006',
        type: ReservationType.seat,
        status: ReservationStatus.pending,
        studentId: 'IT23006654',
        itemId: 'S016',
        itemName: 'Seat C04',
        requestedAt: now.subtract(const Duration(minutes: 10)),
        date: today.add(days(1)),
        timeSlot: '10:00 - 12:00',
        note: 'Needs a desk with a power outlet for a laptop.',
      ),
      reservation(
        id: 'RSV-1007',
        type: ReservationType.book,
        status: ReservationStatus.rejected,
        studentId: 'IT23002267',
        itemId: 'B002',
        itemName: 'Introduction to Algorithms',
        requestedAt: now.subtract(days(2)),
        date: today.subtract(days(1)),
        timeSlot: '09:00',
        rejectionReason: 'No copies available on the requested date.',
      ),
      reservation(
        id: 'RSV-1008',
        type: ReservationType.seat,
        status: ReservationStatus.completed,
        studentId: 'IT23008831',
        itemId: 'S008',
        itemName: 'Seat B02',
        requestedAt: now.subtract(days(3)),
        date: today.subtract(days(1)),
        timeSlot: '14:00 - 16:00',
      ),
      reservation(
        id: 'RSV-1009',
        type: ReservationType.book,
        status: ReservationStatus.cancelled,
        studentId: 'IT23005590',
        itemId: 'B006',
        itemName: 'Design Patterns',
        requestedAt: now.subtract(days(4)),
        date: today.subtract(days(3)),
        timeSlot: '11:00',
      ),
      // Cannot be approved: no copies of this book are available.
      reservation(
        id: 'RSV-1010',
        type: ReservationType.book,
        status: ReservationStatus.pending,
        studentId: 'IT23826854',
        itemId: 'B002',
        itemName: 'Introduction to Algorithms',
        requestedAt: now.subtract(const Duration(minutes: 15)),
        date: today,
        timeSlot: '09:30',
        note: 'Requested for course project reference.',
      ),
      // Cannot be approved: the seat is under maintenance.
      reservation(
        id: 'RSV-1011',
        type: ReservationType.seat,
        status: ReservationStatus.pending,
        studentId: 'IT23865894',
        itemId: 'S011',
        itemName: 'Seat B05',
        requestedAt: now.subtract(const Duration(hours: 2)),
        date: today.add(days(1)),
        timeSlot: '15:00 - 17:00',
        note: 'Requested a group-study seat for exam preparation.',
      ),
      reservation(
        id: 'RSV-1012',
        type: ReservationType.seat,
        status: ReservationStatus.approved,
        studentId: 'IT23010045',
        itemId: 'S007',
        itemName: 'Seat B01',
        requestedAt: now.subtract(const Duration(hours: 4)),
        date: today,
        timeSlot: '14:00 - 16:00',
      ),
      reservation(
        id: 'RSV-1013',
        type: ReservationType.seat,
        status: ReservationStatus.approved,
        studentId: 'IT23011237',
        itemId: 'S012',
        itemName: 'Seat B06',
        requestedAt: now.subtract(const Duration(hours: 6)),
        date: today,
        timeSlot: '15:00 - 17:00',
      ),
    ];
  }

  static List<LibrarianNotification> notifications() {
    final now = DateTime.now();
    Duration minutes(int n) => Duration(minutes: n);
    Duration hours(int n) => Duration(hours: n);

    return [
      LibrarianNotification(
        id: 'N001',
        type: LibrarianNotificationType.approved,
        title: 'Reservation Approved',
        message: 'Seat B01, Reading Room A — Hansi Wijesinghe',
        createdAt: now.subtract(minutes(2)),
        reservationId: 'RSV-1012',
        isRead: true,
      ),
      LibrarianNotification(
        id: 'N002',
        type: LibrarianNotificationType.newRequest,
        title: 'New Reservation Request',
        message: 'Dilshan Rathnayake — Seat C04, tomorrow 10:00 - 12:00',
        createdAt: now.subtract(minutes(10)),
        reservationId: 'RSV-1006',
      ),
      LibrarianNotification(
        id: 'N003',
        type: LibrarianNotificationType.awaitingApproval,
        title: 'Reservation Pending',
        message:
            'Janith Gunasekara requested "Introduction to Algorithms", but no copies are available. Review before approving.',
        createdAt: now.subtract(minutes(15)),
        reservationId: 'RSV-1010',
      ),
      LibrarianNotification(
        id: 'N004',
        type: LibrarianNotificationType.newRequest,
        title: 'New Reservation Request',
        message: 'Nethmi Perera — Clean Code',
        createdAt: now.subtract(minutes(25)),
        reservationId: 'RSV-1001',
      ),
      LibrarianNotification(
        id: 'N005',
        type: LibrarianNotificationType.newRequest,
        title: 'New Reservation Request',
        message: 'Kavindu Silva — Seat A01, today 13:00 - 15:00',
        createdAt: now.subtract(hours(1)),
        reservationId: 'RSV-1002',
      ),
      LibrarianNotification(
        id: 'N006',
        type: LibrarianNotificationType.awaitingApproval,
        title: 'Reservation Pending',
        message: 'Nimali Perera requested Seat B05, which is under maintenance.',
        createdAt: now.subtract(hours(2)),
        reservationId: 'RSV-1011',
        isRead: true,
      ),
      LibrarianNotification(
        id: 'N007',
        type: LibrarianNotificationType.bookReturned,
        title: 'Book Returned',
        message: 'Pasan Gunawardena returned "Computer Networking".',
        createdAt: now.subtract(hours(26)),
        isRead: true,
      ),
      LibrarianNotification(
        id: 'N008',
        type: LibrarianNotificationType.dueReminder,
        title: 'Due Date Reminder',
        message: '2 books are due for return tomorrow.',
        createdAt: now.subtract(hours(28)),
        isRead: true,
      ),
      LibrarianNotification(
        id: 'N009',
        type: LibrarianNotificationType.bookAdded,
        title: 'New Book Added',
        message: '"Financial Accounting" was added to the catalogue.',
        createdAt: now.subtract(hours(50)),
        isRead: true,
      ),
      LibrarianNotification(
        id: 'N010',
        type: LibrarianNotificationType.cancelled,
        title: 'Reservation Cancelled',
        message: 'Ruwani Dissanayake cancelled the reservation for "Design Patterns".',
        createdAt: now.subtract(hours(74)),
        reservationId: 'RSV-1009',
        isRead: true,
      ),
      LibrarianNotification(
        id: 'N011',
        type: LibrarianNotificationType.seatUpdate,
        title: 'Seat B05 under maintenance',
        message: 'Seat B05 was marked for maintenance and is hidden from students.',
        createdAt: now.subtract(hours(98)),
        isRead: true,
      ),
    ];
  }

  /// Loans: active, due today, overdue and returned. Some active loans are
  /// for books another student has reserved, so they cannot be renewed.
  static List<BorrowingRecord> borrowings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime day(int offset) => today.add(Duration(days: offset));

    // (book id, title, ISBN) of the books on loan.
    const cleanCode = ('B001', 'Clean Code', '9780132350884');
    const algorithms = ('B002', 'Introduction to Algorithms', '9780262046305');
    const databases = ('B003', 'Database System Concepts', '9780078022159');
    const hci = ('B004', 'Human-Computer Interaction', '9780130461094');
    const networking = ('B005', 'Computer Networking: A Top-Down Approach', '9780133594140');
    const patterns = ('B006', 'Design Patterns', '9780201633610');
    const os = ('B007', 'Operating System Concepts', '9781119800361');
    const madolDoova = ('B008', 'Madol Doova', '9789552101012');
    const accounting = ('B009', 'Financial Accounting', '9781119594604');

    /// [issued], [due] and [returned] are day offsets from today.
    BorrowingRecord loan(
      String id,
      String memberId,
      String memberName,
      (String, String, String) book,
      int issued,
      int due, {
      int? returned,
      int renewals = 0,
    }) {
      return BorrowingRecord(
        id: id,
        memberId: memberId,
        memberName: memberName,
        bookId: book.$1,
        bookTitle: book.$2,
        isbn: book.$3,
        issuedAt: day(issued),
        dueDate: day(due),
        returnedAt: returned == null ? null : day(returned),
        renewals: renewals,
      );
    }

    return [
      loan('LN-2001', 'IT23004512', 'Nethmi Perera', cleanCode, -10, 4),
      loan('LN-2002', 'IT23007789', 'Kavindu Silva', cleanCode, -14, 0),
      loan('LN-2003', 'IT23003341', 'Sachini Fernando', algorithms, -20, -6),
      loan('LN-2004', 'IT23817194', 'Tharindu Jayasinghe', algorithms, -12, 2),
      loan('LN-2005', 'IT23002267', 'Hiruni Bandara', algorithms, -16, -2),
      loan('LN-2006', 'IT23008831', 'Pasan Gunawardena', algorithms, -5, 9),
      loan('LN-2007', 'IT23001178', 'Ishara Wickramasinghe', databases, -14, 0),
      loan('LN-2008', 'IT23006654', 'Dilshan Rathnayake', hci, -3, 11),
      loan('LN-2009', 'IT23005590', 'Ruwani Dissanayake', hci, -21, 7, renewals: 1),
      loan('LN-2010', 'IT23826854', 'Janith Gunasekara', patterns, -18, -4),
      loan('LN-2011', 'IT23865894', 'Nimali Perera', patterns, -9, 5),
      loan('LN-2012', 'IT23010045', 'Hansi Wijesinghe', os, -8, 6),
      loan('LN-2013', 'IT23011237', 'Ruwan Darshana', os, -15, -1),
      loan('LN-2014', 'IT23004512', 'Nethmi Perera', madolDoova, -4, 10),
      loan('LN-2015', 'IT23007789', 'Kavindu Silva', accounting, -11, 3),
      loan('LN-2016', 'IT23003341', 'Sachini Fernando', accounting, -13, 1),
      loan('LN-1990', 'IT23008831', 'Pasan Gunawardena', networking, -20, -6, returned: -1),
      loan('LN-1991', 'IT23004512', 'Nethmi Perera', cleanCode, -40, -26, returned: -27),
      loan('LN-1992', 'IT23006654', 'Dilshan Rathnayake', networking, -30, -16, returned: -15),
      loan('LN-1993', 'IT23010045', 'Hansi Wijesinghe', hci, -25, -11, returned: -12),
    ];
  }

  /// Members are the students who appear in the reservations and loans,
  /// plus one member with no activity and one suspended account.
  static List<MemberRecord> members() {
    DateTime since(int year, int month) => DateTime(year, month);
    const it = 'BSc (Hons) Information Technology';
    const se = 'BSc (Hons) Software Engineering';
    const ds = 'BSc (Hons) Data Science';

    MemberRecord member(
      String id,
      String name,
      String email,
      String phone,
      String programme,
      DateTime memberSince, {
      MemberStatus status = MemberStatus.active,
    }) {
      return MemberRecord(
        id: id,
        name: name,
        email: email,
        phone: phone,
        programme: programme,
        memberSince: memberSince,
        status: status,
      );
    }

    return [
      member('IT23004512', 'Nethmi Perera', 'nethmi.p@gmail.com', '077 123 4512', it, since(2023, 2)),
      member('IT23007789', 'Kavindu Silva', 'kavindu.s@gmail.com', '071 555 7789', se, since(2023, 2)),
      member('IT23003341', 'Sachini Fernando', 'sachini.f@gmail.com', '076 220 3341', it, since(2023, 3)),
      member('IT23817194', 'Tharindu Jayasinghe', 'tharindu.j@gmail.com', '070 817 1940', ds, since(2023, 6)),
      member('IT23001178', 'Ishara Wickramasinghe', 'ishara.w@gmail.com', '077 900 1178', se, since(2023, 2)),
      member('IT23006654', 'Dilshan Rathnayake', 'dilshan.r@gmail.com', '072 410 6654', it, since(2024, 1)),
      member('IT23002267', 'Hiruni Bandara', 'hiruni.b@gmail.com', '075 330 2267', ds, since(2023, 9)),
      member('IT23008831', 'Pasan Gunawardena', 'pasan.g@gmail.com', '071 908 8831', se, since(2023, 2)),
      member('IT23005590', 'Ruwani Dissanayake', 'ruwani.d@gmail.com', '077 645 5590', it, since(2024, 2)),
      member('IT23826854', 'Janith Gunasekara', 'janith.s@gmail.com', '070 382 6854', it, since(2023, 2)),
      member('IT23865894', 'Nimali Perera', 'nimali.p@gmail.com', '076 386 5894', se, since(2023, 7)),
      member('IT23010045', 'Hansi Wijesinghe', 'hansi.w@gmail.com', '072 101 0045', ds, since(2024, 3)),
      member('IT23011237', 'Ruwan Darshana', 'ruwan.d@gmail.com', '075 111 1237', it, since(2024, 3)),
      member('IT23514658', 'Nilumi Dakshika', 'it23514658@my.sliit.lk', '071 351 4658', it, since(2023, 2)),
      member('IT23012876', 'Amaya Senanayake', 'amaya.s@gmail.com', '077 128 7600', se, since(2024, 1), status: MemberStatus.suspended),
    ];
  }
}
