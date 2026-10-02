import 'package:flutter/material.dart';

import '../models/book_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';

/// Small coloured pill showing a status (reservation, seat or availability).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.reservation(ReservationStatus status) {
    return StatusChip(label: status.label, color: reservationColor(status));
  }

  factory StatusChip.seat(SeatStatus status) {
    return StatusChip(label: status.label, color: seatColor(status));
  }

  factory StatusChip.bookStock(BookStock stock) {
    return StatusChip(label: stock.label, color: bookStockColor(stock));
  }

  static Color bookStockColor(BookStock stock) {
    return switch (stock) {
      BookStock.available => LibrarianColors.available,
      BookStock.lowStock => LibrarianColors.gold,
      BookStock.notAvailable => LibrarianColors.unavailable,
    };
  }

  /// Colour for each reservation status, also used for card accents.
  static Color reservationColor(ReservationStatus status) {
    return switch (status) {
      ReservationStatus.pending => LibrarianColors.gold,
      ReservationStatus.approved => LibrarianColors.available,
      ReservationStatus.rejected => LibrarianColors.unavailable,
      ReservationStatus.completed => LibrarianColors.primary,
      ReservationStatus.cancelled => LibrarianColors.secondaryText,
    };
  }

  /// Seat colours follow the Figma seat map legend.
  static Color seatColor(SeatStatus status) {
    return switch (status) {
      SeatStatus.available => LibrarianColors.available,
      SeatStatus.reserved => LibrarianColors.gold,
      SeatStatus.occupied => LibrarianColors.primary,
      SeatStatus.maintenance => LibrarianColors.secondaryText,
    };
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Text is the status colour slightly darkened, so light colours such as
    // gold stay readable on the tinted background.
    final textColor = Color.lerp(color, LibrarianColors.text, 0.3)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
