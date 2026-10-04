import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book_reservation.dart';

class BookReservationService {
  BookReservationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _reservationsCollection =>
          _firestore.collection('bookReservations');

  Future<String> createReservation(BookReservation reservation) async {
    final doc = _reservationsCollection.doc();

    await doc.set({
      'reservationId': doc.id,
      'userId': reservation.userId,
      'bookId': reservation.bookId,
      'pickupDate': Timestamp.fromDate(reservation.pickupDate),
      'loanPeriodDays': reservation.loanPeriodDays,
      'status': reservation.status,
      'receiptCode': reservation.receiptCode,
    });

    return doc.id;
  }

  Future<List<BookReservation>> getUserReservations(
    String userId,
  ) async {
    final snapshot = await _reservationsCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return BookReservation(
        reservationId: data['reservationId'] as String,
        userId: data['userId'] as String,
        bookId: data['bookId'] as String,
        pickupDate: (data['pickupDate'] as Timestamp).toDate(),
        loanPeriodDays: data['loanPeriodDays'] as int,
        status: data['status'] as String,
        receiptCode: data['receiptCode'] as String,
      );
    }).toList();
  }
}