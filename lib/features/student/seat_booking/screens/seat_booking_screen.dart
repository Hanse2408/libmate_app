import 'package:flutter/material.dart';

import '../../../../core/widgets/stored_image.dart';
import '../../../../models/seat.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';
import '../../common/data/student_library_repository.dart';
import '../providers/seat_booking_provider.dart';
import 'seat_booking_confirmation_screen.dart';
import '../widgets/book_seat_bar.dart';
import '../widgets/booking_details_card.dart';
import '../widgets/booking_pickers.dart';
import '../widgets/seat_booking_colors.dart';
import '../widgets/seat_map.dart';
import '../widgets/seat_tile.dart';
import '../widgets/selected_seat_card.dart';

/// Book a reading-room seat: choose a day and time, then a free seat.
///
/// Seats are the ones librarians manage (Firestore `seats`, live). A booking
/// is confirmed at once (no librarian approval) and opens the H02
/// confirmation screen.
class SeatBookingScreen extends StatefulWidget {
  const SeatBookingScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  late final SeatBookingProvider _provider = SeatBookingProvider(widget.library);
  bool _handlingBooking = false;

  late DateTime _date = _today();
  late int _startHour = _firstStartHour(_date);
  int _hours = 1;

  /// Taken seat-hours for the selected day (re-created when the day changes).
  late Stream<Set<String>> _bookedSlots = widget.library.bookedSlotIds(_date);

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Earliest bookable hour on [day]: opening time, or the next hour today.
  int _firstStartHour(DateTime day) {
    final settings = widget.library.settings;
    final now = DateTime.now();
    final isToday = day == _today();
    final next = isToday ? now.hour + 1 : settings.openingHour;
    return next < settings.openingHour ? settings.openingHour : next;
  }

  List<int> get _startHours {
    final settings = widget.library.settings;
    return [
      for (var h = _firstStartHour(_date); h < settings.closingHour; h++) h,
    ];
  }

  List<int> get _durations {
    final settings = widget.library.settings;
    final max = settings.seatBookingHours.clamp(1, 8);
    return [
      for (var d = 1; d <= max && _startHour + d <= settings.closingHour; d++) d,
    ];
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
    if (_handlingBooking) return;
    _handlingBooking = true;

    // book() clears the selection, so keep the booking details first.
    final seat = _provider.selectedSeat;
    final date = _provider.date;
    final startHour = _provider.startHour;
    final endHour = _provider.endHour;

    final result = await _provider.book();
    final reservationId = result.reservationId;

    if (!mounted || !result.success || seat == null || reservationId == null) {
      _handlingBooking = false;
      return;
    }

    // Replace H01 so Back cannot lead to a second booking by accident.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SeatBookingConfirmationScreen(
          library: widget.library,
          seat: seat,
          date: date,
          startHour: startHour,
          endHour: endHour,
          reservationId: reservationId,
        ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.library,
          builder: (context, _) {
            // Keep the time valid if the settings changed.
            final starts = _startHours;
            if (starts.isNotEmpty && !starts.contains(_startHour)) _startHour = starts.first;
            final durations = _durations;
            if (durations.isNotEmpty && !durations.contains(_hours)) _hours = durations.first;

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: StreamBuilder<Set<String>>(
                    stream: _bookedSlots,
                    builder: (context, snapshot) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        children: [
                          _buildDates(),
                          const SizedBox(height: 18),
                          _buildTimePicker(starts, durations),
                          const SizedBox(height: 18),
                          _buildLegend(),
                          const SizedBox(height: 12),
                          ..._buildSeatMaps(snapshot, starts.isEmpty),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 21),
          ),
          const Expanded(
            child: Text(
              'Book a Seat',
              textAlign: TextAlign.center,
              style: TextStyle(color: _text, fontSize: 21, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'My seat bookings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyReservationsScreen(library: widget.library, showSeats: true),
              ),
            ),
            icon: const Icon(Icons.calendar_month_rounded, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDates() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = _today();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = today.add(Duration(days: index));
          final selected = day == _date;
          return InkWell(
            onTap: () => _selectDate(day),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: selected ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? _primary : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    index == 0 ? 'Today' : weekdays[day.weekday - 1],
                    style: TextStyle(
                      color: selected ? Colors.white : _secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : _text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker(List<int> starts, List<int> durations) {
    if (starts.isEmpty) {
      return const Text(
        'The library is closed for the rest of today. Please choose another day.',
        style: TextStyle(color: _secondary),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: _primary, size: 20),
              const SizedBox(width: 8),
              const Text('Start time', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
              const Spacer(),
              DropdownButton<int>(
                value: _startHour,
                underline: const SizedBox.shrink(),
                items: [
                  for (final h in starts) DropdownMenuItem(value: h, child: Text(_hh(h))),
                ],
                onChanged: (h) => setState(() {
                  _startHour = h!;
                  _hours = 1;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Duration', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in durations)
                ChoiceChip(
                  label: Text('$d hour${d == 1 ? '' : 's'}'),
                  selected: d == _hours,
                  onSelected: (_) => setState(() => _hours = d),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_hh(_startHour)} – ${_hh(_startHour + _hours)}',
            style: const TextStyle(color: _secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _secondary, fontSize: 12)),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(_green, 'Available'),
        item(const Color(0xFFCBD5E1), 'Booked'),
        item(_red, 'Unavailable'),
      ],
    );
  }

  List<Widget> _buildSeatMaps(AsyncSnapshot<Set<String>> snapshot, bool closed) {
    final library = widget.library;
    if (library.isLoading && library.seats.isEmpty) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (library.seats.isEmpty) {
      return [
        Text(
          library.loadError ?? 'No reading-room seats have been added yet.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _secondary),
        ),
      ];
    }
    if (snapshot.hasError) {
      return const [
        Text(
          'Could not check which seats are free. Please try again.',
          style: TextStyle(color: _red),
        ),
      ];
    }
    final booked = snapshot.data;
    if (booked == null) return const [Center(child: CircularProgressIndicator())];

    final rooms = {for (final seat in library.seats) seat.readingRoom}.toList()..sort();
    return [
      for (final room in rooms) ...[
        Text(
          room,
          style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final seat in library.seats.where((s) => s.readingRoom == room))
              _SeatChip(
                key: ValueKey('seat-${seat.id}'),
                seat: seat,
                blocker: closed
                    ? 'The library is closed.'
                    : library.seatBookingBlocker(
                        seat,
                        _date,
                        _startHour,
                        _startHour + _hours,
                        bookedSlots: booked,
                      ),
                isBooked: SeatSlots.ids(seat.id, _date, _startHour, _startHour + _hours)
                    .any(booked.contains),
                onTap: () => _showSeat(seat, booked, closed),
              ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    ];
  }

  Future<void> _showSeat(SeatRecord seat, Set<String> booked, bool closed) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => _SeatDetailsSheet(
        library: widget.library,
        seat: seat,
        date: _date,
        startHour: _startHour,
        endHour: _startHour + _hours,
        blocker: closed
            ? 'The library is closed.'
            : widget.library.seatBookingBlocker(
                seat,
                _date,
                _startHour,
                _startHour + _hours,
                bookedSlots: booked,
              ),
      ),
    );
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _hh(int hour) => '${hour.toString().padLeft(2, '0')}:00';
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({
    super.key,
    required this.seat,
    required this.blocker,
    required this.isBooked,
    required this.onTap,
  });

  final SeatRecord seat;
  final String? blocker;
  final bool isBooked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final free = blocker == null;
    final color = free
        ? const Color(0xFF22A06B)
        : isBooked
        ? const Color(0xFFCBD5E1)
        : const Color(0xFFDC4C4C);
    return Semantics(
      button: true,
      label: 'Seat ${seat.seatNumber}, ${free ? 'available' : 'unavailable'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 58,
          decoration: BoxDecoration(
            color: free ? const Color(0xFFEAF8F1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_seat_rounded, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                seat.seatNumber,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seat photo and details, with the Book Seat button. Pops with the message
/// to show after a successful booking.
class _SeatDetailsSheet extends StatefulWidget {
  const _SeatDetailsSheet({
    required this.library,
    required this.seat,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.blocker,
  });

  final StudentLibraryRepository library;
  final SeatRecord seat;
  final DateTime date;
  final int startHour;
  final int endHour;
  final String? blocker;

  @override
  State<_SeatDetailsSheet> createState() => _SeatDetailsSheetState();
}

class _SeatDetailsSheetState extends State<_SeatDetailsSheet> {
  bool _booking = false;
  String? _error;

  Future<void> _book() async {
    setState(() {
      _booking = true;
      _error = null;
    });
    final result = await widget.library.bookSeat(
      seat: widget.seat,
      date: widget.date,
      startHour: widget.startHour,
      endHour: widget.endHour,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(
        'Seat ${widget.seat.seatNumber} requested for '
        '${_SeatBookingScreenState._hh(widget.startHour)} – '
        '${_SeatBookingScreenState._hh(widget.endHour)}. '
        'It is pending librarian approval.',
      );
    } else {
      setState(() {
        _booking = false;
        _error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final features = seat.features;
    final rows = <(String, String)>[
      ('Reading Room', seat.readingRoom),
      ('Zone', seat.zone),
      ('Seat Type', seat.type.label),
      ('Features', features.isEmpty ? 'None' : features.join(', ')),
      if (seat.note.isNotEmpty) ('Note', seat.note),
      (
        'Time',
        '${_SeatBookingScreenState._hh(widget.startHour)} – '
            '${_SeatBookingScreenState._hh(widget.endHour)}',
      ),
    ];
    final reason = _error ?? widget.blocker;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (seat.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: StoredImage(
                    url: seat.imageUrl,
                    fallback: const ColoredBox(color: Color(0xFFEFF6FF)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Seat ${seat.seatNumber}',
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (reason != null) ...[
              const SizedBox(height: 10),
              Text(reason, style: const TextStyle(color: Color(0xFFDC4C4C))),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: widget.blocker == null && !_booking ? _book : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _booking ? 'Booking…' : 'Book Seat',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
