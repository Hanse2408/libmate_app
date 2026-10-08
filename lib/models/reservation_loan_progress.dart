import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only student view of the loan linked to a specific reservation.
class ReservationLoanProgress {
  const ReservationLoanProgress({required this.issuedAt, this.returnedAt});
  final DateTime issuedAt;
  final DateTime? returnedAt;

  factory ReservationLoanProgress.fromMap(Map<String, dynamic> data) =>
      ReservationLoanProgress(
        issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
        returnedAt: (data['returnedAt'] as Timestamp?)?.toDate(),
      );
}
