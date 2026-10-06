import 'package:flutter/material.dart';

import '../../../../models/reservation.dart';
import '../../common/data/student_library_repository.dart';
import '../providers/seat_booking_provider.dart';
import '../widgets/book_seat_bar.dart';
import '../widgets/booking_details_card.dart';
import '../widgets/booking_pickers.dart';
import '../widgets/seat_booking_colors.dart';
import '../widgets/seat_map.dart';
import '../widgets/seat_tile.dart';
import '../widgets/selected_seat_card.dart';

/// H05 – change the date, time or seat of an existing confirmed seat booking.
///
/// Works like Book a Seat (same rules, same seat map) but starts from the
/// booking being modified and saves to that SAME reservation.
class ModifySeatReservationScreen extends StatefulWidget {
  const ModifySeatReservationScreen({
    super.key,
    required this.library,
    required this.reservation,
  });

  final StudentLibraryRepository library;
  final ReservationRecord reservation;

  @override
  State<ModifySeatReservationScreen> createState() => _ModifySeatReservationScreenState();
}

class _ModifySeatReservationScreenState extends State<ModifySeatReservationScreen> {
  late final SeatBookingProvider _provider = SeatBookingProvider(
    widget.library,
    editing: widget.reservation,
  );
  bool _saving = false;

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    final result = await _provider.save();
    if (!mounted) return;
    if (!result.success) {
      _saving = false;
      return;
    }
    // The reservation ID is unchanged, so going back shows the same booking
    // (H04 or My Reservations) with its new data.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Reservation updated successfully.')));
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
                      _CurrentBookingBanner(reservation: widget.reservation),
                      const SizedBox(height: 16),
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
                      const _SectionTitle('Choose a Seat'),
                      const SizedBox(height: 10),
                      const SeatLegend(),
                      const SizedBox(height: 16),
                      ..._buildSeats(),
                      if (seat != null) ...[
                        const SizedBox(height: 4),
                        const _SectionTitle('Selected Seat'),
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
            label: 'Save Changes',
            summary: seat == null
                ? 'Select an available seat to continue.'
                : 'Seat ${seat.seatNumber} · ${formatBookingDate(_provider.date)} · '
                      '${SeatBookingProvider.hourLabel(_provider.startHour)} – '
                      '${SeatBookingProvider.hourLabel(_provider.endHour)}',
            message:
                _provider.error ??
                (_provider.hasChanges && _provider.hasOwnBooking
                    ? 'You already have a seat booked at this time.'
                    : null),
            enabled: _provider.canSave,
            isBooking: _provider.isBooking,
            onBook: _save,
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: SeatColors.text, size: 19),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Modify Reservation',
                style: TextStyle(color: SeatColors.text, fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 38),
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
      return [_InfoText(library.loadError ?? 'No reading-room seats have been added yet.')];
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
        onBlockedSeatTap: _showMessage,
      ),
    ];
  }
}

/// Shows which booking is being modified.
class _CurrentBookingBanner extends StatelessWidget {
  const _CurrentBookingBanner({required this.reservation});

  final ReservationRecord reservation;

  @override
  Widget build(BuildContext context) {
    final start = reservation.startHour;
    final end = reservation.endHour;
    final time = start != null && end != null
        ? '${SeatBookingProvider.hourLabel(start)} – ${SeatBookingProvider.hourLabel(end)}'
        : reservation.timeSlot ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SeatColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8D3FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_calendar_outlined, color: SeatColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modifying your current booking',
                  style: TextStyle(
                    color: SeatColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${reservation.itemName} · ${formatBookingDate(reservation.date)} · $time',
                  style: const TextStyle(color: SeatColors.secondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: SeatColors.text, fontSize: 15, fontWeight: FontWeight.w700),
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
