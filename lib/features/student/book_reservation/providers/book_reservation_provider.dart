import 'package:flutter/foundation.dart';

import '../../../../models/book_reservation.dart';
import '../../../../repositories/book_reservation_repository.dart';

class BookReservationProvider extends ChangeNotifier {
  BookReservationProvider({
    BookReservationRepository? reservationRepository,
  }) : _reservationRepository =
            reservationRepository ?? BookReservationRepository();

  final BookReservationRepository _reservationRepository;

  List<BookReservation> _reservations = [];
  bool _isLoading = false;
  String? _error;

  List<BookReservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String?> createReservation(
    BookReservation reservation,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reservationId =
          await _reservationRepository.createReservation(reservation);

      return reservationId;
    } catch (e) {
      _error = 'Failed to create reservation.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserReservations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservations =
          await _reservationRepository.getUserReservations(userId);
    } catch (e) {
      _error = 'Failed to load reservations.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}