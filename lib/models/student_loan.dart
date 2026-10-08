import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only view of the librarian's loan. Missing dates are never invented.
class StudentLoan {
  const StudentLoan({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.issuedAt,
    this.dueDate,
    this.returnedAt,
    this.reservationId,
  });
  final String id;
  final String bookId;
  final String bookTitle;
  final String? reservationId;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final DateTime? returnedAt;
  bool get isReturned => returnedAt != null;

  factory StudentLoan.fromMap(String id, Map<String, dynamic> data) =>
      StudentLoan(
        id: id,
        bookId: data['bookId'] as String? ?? '',
        bookTitle: data['bookTitle'] as String? ?? 'Book',
        reservationId: data['reservationId'] as String?,
        issuedAt: (data['issuedAt'] as Timestamp?)?.toDate(),
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        returnedAt: (data['returnedAt'] as Timestamp?)?.toDate(),
      );

  /// Calendar days, without daylight-saving hour differences. The due day is free.
  int? daysOverdueOn(DateTime now) {
    final due = dueDate;
    if (due == null) return null;
    final end = returnedAt ?? now;
    final days = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(due.year, due.month, due.day)).inDays;
    return days > 0 ? days : 0;
  }

  int? estimatedFineOn(DateTime now, {required int dailyRate}) {
    final days = daysOverdueOn(now);
    return days == null ? null : days * (dailyRate < 0 ? 0 : dailyRate);
  }
}
