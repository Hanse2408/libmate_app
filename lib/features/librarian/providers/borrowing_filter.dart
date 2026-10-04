import '../models/borrowing_record.dart';

/// Search text + status tab on the Borrowing Management screen.
/// A null [status] means "All".
class BorrowingFilter {
  const BorrowingFilter({this.query = '', this.status});

  final String query;
  final BorrowingStatus? status;

  /// Matching loans: overdue first (they need action), then by due date;
  /// returned loans last, most recent first.
  List<BorrowingRecord> apply(List<BorrowingRecord> loans) {
    final text = query.trim().toLowerCase();
    final results = loans.where((loan) {
      if (status != null && loan.status != status) return false;
      if (text.isEmpty) return true;
      return [
        loan.id,
        loan.memberName,
        loan.memberId,
        loan.bookTitle,
        loan.isbn,
      ].any((field) => field.toLowerCase().contains(text));
    }).toList();

    int rank(BorrowingRecord b) => switch (b.status) {
      BorrowingStatus.overdue => 0,
      BorrowingStatus.dueToday => 1,
      BorrowingStatus.active => 2,
      BorrowingStatus.returned => 3,
    };
    results.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      if (a.isReturned) return b.returnedAt!.compareTo(a.returnedAt!);
      return a.dueDate.compareTo(b.dueDate);
    });
    return results;
  }

  /// Number of loans in each status, for the summary cards and tabs.
  static Map<BorrowingStatus, int> countByStatus(List<BorrowingRecord> loans) {
    return {
      for (final status in BorrowingStatus.values)
        status: loans.where((loan) => loan.status == status).length,
    };
  }
}
