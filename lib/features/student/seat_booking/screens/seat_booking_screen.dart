import 'package:flutter/material.dart';

import '../../book_reservation/screens/my_reservations_screen.dart';
import '../../common/data/student_library_repository.dart';
import '../providers/seat_booking_provider.dart';
import '../widgets/book_seat_bar.dart';
import '../widgets/booking_details_card.dart';
import '../widgets/booking_pickers.dart';
import '../widgets/seat_booking_colors.dart';
import '../widgets/seat_map.dart';
import '../widgets/seat_tile.dart';
import '../widgets/selected_seat_card.dart';

/// Book a reading-room seat: choose a date and time, then a free seat.
///
/// Seats are the ones librarians manage (Firestore `seats`, live). Seat
/// bookings are confirmed immediately: no librarian approval is needed.
class SeatBookingScreen extends StatefulWidget {
  const SeatBookingScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  late final SeatBookingProvider _provider = SeatBookingProvider(widget.library);

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _pickDate() async {
    final day = await pickBookingDate(
      context,
      selected: _provider.date,
      first: _provider.today,
      last: _provider.lastBookableDay,
    );
    if (day != null) _provider.setDate(day);
  }

  Future<void> _pickStart() async {
    final hour = await pickBookingHour(
      context,
      title: 'Start Time',
      hours: _provider.startHours,
      selected: _provider.startHour,
    );
    if (hour != null) _provider.setStartHour(hour);
  }

  Future<void> _pickEnd() async {
    final hour = await pickBookingHour(
      context,
      title: 'End Time',
      hours: _provider.endHours,
      selected: _provider.endHour,
    );
    if (hour != null) _provider.setEndHour(hour);
  }

  Future<void> _book() async {
    final result = await _provider.book();
    if (!mounted || !result.success) return;
    _showMessage(
      'Seat booked successfully.',
      action: SnackBarAction(
        label: 'View',
        textColor: Colors.white,
        onPressed: _openMyBookings,
      ),
    );
  }

  void _openMyBookings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyReservationsScreen(library: widget.library, showSeats: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final seat = _provider.selectedSeat;
        final settings = widget.library.settings;
        return Scaffold(
          backgroundColor: SeatColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      BookingDetailsCard(
                        date: _provider.date,
                        startHour: _provider.startHour,
                        endHour: _provider.endHour,
                        isClosed: _provider.isClosed,
                        hoursNote:
                            'Open ${SeatBookingProvider.hourLabel(settings.openingHour)} – '
                            '${SeatBookingProvider.hourLabel(settings.closingHour)} · '
                            'up to ${settings.seatBookingHours} hour'
                            '${settings.seatBookingHours == 1 ? '' : 's'} per booking',
                        onPickDate: _pickDate,
                        onPickStart: _pickStart,
                        onPickEnd: _pickEnd,
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Choose a Seat',
                        style: TextStyle(
                          color: SeatColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SeatLegend(),
                      const SizedBox(height: 16),
                      ..._buildSeats(),
                      if (seat != null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Selected Seat',
                          style: TextStyle(
                            color: SeatColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectedSeatCard(seat: seat),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BookSeatBar(
            summary: seat == null
                ? 'Select an available seat to continue.'
                : 'Seat ${seat.seatNumber} · ${formatBookingDate(_provider.date)} · '
                      '${SeatBookingProvider.hourLabel(_provider.startHour)} – '
                      '${SeatBookingProvider.hourLabel(_provider.endHour)}',
            message:
                _provider.error ??
                (_provider.hasOwnBooking ? 'You already have a seat booked at this time.' : null),
            enabled: _provider.canBook,
            isBooking: _provider.isBooking,
            onBook: _book,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Book a Seat',
                style: TextStyle(
                  color: SeatColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.calendar_month_rounded,
            tooltip: 'My seat bookings',
            onPressed: _openMyBookings,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeats() {
    final library = widget.library;
    if (library.isLoading && library.seats.isEmpty) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (library.seats.isEmpty) {
      return [
        _InfoText(library.loadError ?? 'No reading-room seats have been added yet.'),
      ];
    }
    if (_provider.isClosed) {
      return const [_InfoText('Choose another day to see the seats.')];
    }
    if (_provider.slotsFailed) {
      return const [
        _InfoText('Could not check which seats are free. Please try again.', isError: true),
      ];
    }
    if (!_provider.slotsLoaded) {
      return const [Center(child: CircularProgressIndicator())];
    }
    return [
      SeatMap(
        provider: _provider,
        onBlockedSeatTap: (message) => _showMessage(message),
      ),
    ];
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: SeatColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: SeatColors.border),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: SeatColors.text, size: 19),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError ? SeatColors.red : SeatColors.secondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
