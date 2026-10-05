class BookReservation {
  final String reservationId;
  final String userId;
  final String bookId;
  final DateTime pickupDate;
  final int loanPeriodDays;
  final String status;
  final String receiptCode;

  const BookReservation({
    required this.reservationId,
    required this.userId,
    required this.bookId,
    required this.pickupDate,
    required this.loanPeriodDays,
    required this.status,
    required this.receiptCode,
  });
}