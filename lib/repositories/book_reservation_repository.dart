import '../core/services/book_reservation_service.dart';
import '../models/book_reservation.dart';

class BookReservationRepository {
  BookReservationRepository({
    BookReservationService? reservationService,
  }) : _reservationService =
            reservationService ?? BookReservationService();

  final BookReservationService _reservationService;

  Future<String> createReservation(
    BookReservation reservation,
  ) {
    return _reservationService.createReservation(reservation);
  }

  Future<List<BookReservation>> getUserReservations(
    String userId,
  ) {
    return _reservationService.getUserReservations(userId);
  }
}