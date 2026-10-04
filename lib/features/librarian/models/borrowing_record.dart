import 'package:cloud_firestore/cloud_firestore.dart';

enum BorrowingStatus {
  active('Active'),
  dueToday('Due Today'),
  overdue('Overdue'),
  returned('Returned');

  const BorrowingStatus(this.label);
  final String label;
}

/// A book a member has borrowed (a loan), stored in Firestore at
/// `borrowings/{id}`. Created when a librarian marks an approved book
/// reservation as collected.
///
/// The status is calculated from the dates, so a loan becomes "Due Today"
/// or "Overdue" automatically as days pass.
class BorrowingRecord {
  const BorrowingRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.bookId,
    required this.bookTitle,
    required this.isbn,
    required this.issuedAt,
    required this.dueDate,
    this.returnedAt,
    this.renewals = 0,
  });

  /// e.g. "LN-2001"
  final String id;

  /// The member's student ID.
  final String memberId;
  final String memberName;
  final String bookId;
  final String bookTitle;
  final String isbn;
  final DateTime issuedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final int renewals;

  bool get isReturned => returnedAt != null;

  factory BorrowingRecord.fromMap(String id, Map<String, dynamic> map) {
    return BorrowingRecord(
      id: id,
      memberId: map['memberId'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      bookTitle: map['bookTitle'] as String? ?? '',
      isbn: map['isbn'] as String? ?? '',
      issuedAt: (map['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnedAt: (map['returnedAt'] as Timestamp?)?.toDate(),
      renewals: (map['renewals'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'isbn': isbn,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'returnedAt': returnedAt == null ? null : Timestamp.fromDate(returnedAt!),
      'renewals': renewals,
    };
  }

  BorrowingStatus get status => statusOn(DateTime.now());

  /// Status on a given day (used by [status] and by tests).
  BorrowingStatus statusOn(DateTime now) {
    if (isReturned) return BorrowingStatus.returned;
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(today)) return BorrowingStatus.overdue;
    if (due == today) return BorrowingStatus.dueToday;
    return BorrowingStatus.active;
  }

  /// Whole days past the due date (0 if not overdue).
  int get daysOverdue {
    if (status != BorrowingStatus.overdue) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return today.difference(due).inDays;
  }

  BorrowingRecord copyWith({
    DateTime? dueDate,
    DateTime? returnedAt,
    int? renewals,
  }) {
    return BorrowingRecord(
      id: id,
      memberId: memberId,
      memberName: memberName,
      bookId: bookId,
      bookTitle: bookTitle,
      isbn: isbn,
      issuedAt: issuedAt,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
      renewals: renewals ?? this.renewals,
    );
  }
}
