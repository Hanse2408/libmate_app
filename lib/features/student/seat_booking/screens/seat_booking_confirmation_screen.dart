import 'package:flutter/material.dart';

import '../../../../models/seat.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';
import '../../common/data/student_library_repository.dart';
import '../providers/seat_booking_provider.dart';
import '../widgets/booking_details_card.dart';
import '../widgets/seat_booking_colors.dart';

/// H02 – shown right after a seat booking succeeded. Seat bookings need no
/// librarian approval, so the seat is already confirmed.
///
/// Everything shown is passed in from the booking that just succeeded; this
/// screen never writes to Firestore.
class SeatBookingConfirmationScreen extends StatelessWidget {
  const SeatBookingConfirmationScreen({
    super.key,
    required this.library,
    required this.seat,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.reservationId,
  });

  final StudentLibraryRepository library;
  final SeatRecord seat;
  final DateTime date;
  final int startHour;
  final int endHour;
  final String reservationId;

  /// H03/H04 will replace this destination with the dedicated seat
  /// reservation screen.
  void _openReservation(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MyReservationsScreen(library: library, showSeats: true),
      ),
    );
  }

  void _backToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final room = seat.readingRoom.trim().isEmpty ? 'Reading Room' : seat.readingRoom.trim();
    final time =
        '${SeatBookingProvider.hourLabel(startHour)} – ${SeatBookingProvider.hourLabel(endHour)}';

    return Scaffold(
      backgroundColor: SeatColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    const _SuccessIcon(),
                    const SizedBox(height: 24),
                    const Text(
                      'Seat booked successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SeatColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Your reading-room seat is reserved for the selected time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SeatColors.secondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ReceiptCard(
                      rows: [
                        _ReceiptRow(
                          icon: Icons.event_seat_outlined,
                          label: 'Seat Number',
                          value: seat.seatNumber,
                        ),
                        _ReceiptRow(
                          icon: Icons.meeting_room_outlined,
                          label: 'Reading Room',
                          value: room,
                        ),
                        _ReceiptRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: formatBookingDate(date),
                        ),
                        _ReceiptRow(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: time,
                        ),
                        _ReceiptRow(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Booking ID',
                          value: reservationId,
                        ),
                        const _ReceiptRow(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Status',
                          value: 'Confirmed',
                          valueColor: SeatColors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => _openReservation(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SeatColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'View Reservation',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => _backToHome(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: SeatColors.card,
                          foregroundColor: SeatColors.text,
                          side: const BorderSide(color: SeatColors.gold, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SeatColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: SeatColors.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: SeatColors.text,
                size: 19,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Booking Confirmed',
                style: TextStyle(
                  color: SeatColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              color: SeatColors.greenFill,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(top: 12, right: 18, child: _Dot(color: SeatColors.gold, size: 11)),
          const Positioned(bottom: 14, left: 18, child: _Dot(color: SeatColors.primary, size: 9)),
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: SeatColors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: SeatColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SeatColors.gold, width: 1.2),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Booking Receipt',
              style: TextStyle(
                color: SeatColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: SeatColors.border),
          const SizedBox(height: 5),
          ...rows,
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = SeatColors.text,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, color: SeatColors.text, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: SeatColors.secondary, fontSize: 12.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
