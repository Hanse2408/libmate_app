import 'package:flutter/material.dart';

import 'seat_booking_colors.dart';

/// Fixed bar at the bottom: what is chosen, any problem, and Book Seat.
class BookSeatBar extends StatelessWidget {
  const BookSeatBar({
    super.key,
    required this.summary,
    required this.message,
    required this.enabled,
    required this.isBooking,
    required this.onBook,
  });

  /// e.g. "Seat A01 · Mon, 5 Oct · 10:00 – 12:00", or a hint when nothing is chosen.
  final String summary;

  /// Why booking failed or is not possible, shown in red.
  final String? message;
  final bool enabled;
  final bool isBooking;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SeatColors.card,
        border: Border(top: BorderSide(color: SeatColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(
                  message!,
                  style: const TextStyle(color: SeatColors.red, fontSize: 13),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SeatColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: enabled && !isBooking ? onBook : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SeatColors.primary,
                    disabledBackgroundColor: SeatColors.greyLine,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isBooking
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text(
                          'Book Seat',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
