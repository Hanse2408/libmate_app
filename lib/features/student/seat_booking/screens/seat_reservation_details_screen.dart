import '../../../../models/reservation_display_reference.dart';
import 'package:flutter/material.dart';

import '../../../../models/reservation.dart';
import '../../../../models/seat.dart';
import '../../common/data/student_library_repository.dart';
import '../providers/seat_booking_provider.dart';
import '../widgets/booking_details_card.dart';
import '../widgets/seat_booking_colors.dart';
import '../widgets/seat_reservation_info_card.dart';
import 'modify_seat_reservation_screen.dart';

/// H04 – details of one of the student's seat reservations.
///
/// The selected [reservation] is passed in. While the screen is open it
/// follows the live copy in [library], so a cancellation shows at once.
/// Cancelling uses the repository; this screen never touches Firestore.
class SeatReservationDetailsScreen extends StatefulWidget {
  const SeatReservationDetailsScreen({
    super.key,
    required this.library,
    required this.reservation,
  });

  final StudentLibraryRepository library;
  final ReservationRecord reservation;

  @override
  State<SeatReservationDetailsScreen> createState() => _SeatReservationDetailsScreenState();
}

class _SeatReservationDetailsScreenState extends State<SeatReservationDetailsScreen> {
  bool _isCancelling = false;
  bool _cancelled = false;

  /// The latest copy of the reservation (falls back to the one passed in).
  ReservationRecord get _reservation {
    final live = widget.library.myReservations
        .where((r) => r.id == widget.reservation.id)
        .firstOrNull;
    final current = live ?? widget.reservation;
    return _cancelled ? current.copyWith(status: ReservationStatus.cancelled) : current;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Opens H05. H04 follows the live reservation, so it shows the changes
  /// as soon as it is back on screen.
  void _openModify() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModifySeatReservationScreen(
          library: widget.library,
          reservation: _reservation,
        ),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SeatColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancel Reservation?',
          style: TextStyle(color: SeatColors.text, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel ${widget.reservation.itemName}? '
          'The seat will be free for other students.',
          style: const TextStyle(color: SeatColors.secondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Keep',
              style: TextStyle(color: SeatColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Cancel Reservation',
              style: TextStyle(color: SeatColors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _cancel();
  }

  Future<void> _cancel() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    final result = await widget.library.cancelReservation(widget.reservation.id);
    if (!mounted) return;
    setState(() {
      _isCancelling = false;
      _cancelled = result.success;
    });
    _showMessage(result.success ? 'Seat reservation cancelled.' : result.message!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeatColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.library,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final reservation = _reservation;
    final seat = widget.library.seatById(reservation.itemId);
    final canChange = reservation.isActive && !reservation.hasEnded;
    final (statusLabel, statusColor, statusFill) = _statusStyle(reservation);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SeatStatusChip(label: statusLabel, color: statusColor, fill: statusFill),
          ),
          const SizedBox(height: 18),
          SeatReservationInfoCard(
            title: 'Seat Reservation',
            rows: _buildRows(reservation, seat, statusLabel, statusColor),
          ),
          if (reservation.isActive && reservation.hasEnded) ...[
            const SizedBox(height: 14),
            const _Notice('This booking time has already passed.'),
          ],
          if (canChange) ...[
            const SizedBox(height: 24),
            if (reservation.canModifySeat) ...[
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _openModify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SeatColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text(
                    'Modify Reservation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _isCancelling ? null : _confirmCancel,
                style: OutlinedButton.styleFrom(
                  backgroundColor: SeatColors.card,
                  foregroundColor: SeatColors.red,
                  side: const BorderSide(color: SeatColors.red, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text(
                  _isCancelling ? 'Cancelling…' : 'Cancel Reservation',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seat bookings are confirmed at once, so "approved" reads as Confirmed.
  (String, Color, Color) _statusStyle(ReservationRecord r) {
    return switch (r.status) {
      ReservationStatus.approved => ('Confirmed', SeatColors.green, SeatColors.greenFill),
      ReservationStatus.cancelled => ('Cancelled', SeatColors.red, SeatColors.redFill),
      ReservationStatus.rejected => ('Rejected', SeatColors.red, SeatColors.redFill),
      ReservationStatus.completed => ('Completed', SeatColors.primary, SeatColors.lightBlue),
      ReservationStatus.pending => ('Pending', SeatColors.secondary, SeatColors.greyFill),
    };
  }

  List<SeatInfoRow> _buildRows(
    ReservationRecord r,
    SeatRecord? seat,
    String statusLabel,
    Color statusColor,
  ) {
    final start = r.startHour;
    final end = r.endHour;
    final time = start != null && end != null
        ? '${SeatBookingProvider.hourLabel(start)} – ${SeatBookingProvider.hourLabel(end)}'
        : r.timeSlot;
    final room = seat?.readingRoom.trim() ?? '';
    final zone = seat?.zone.trim() ?? '';
    final note = seat?.note.trim() ?? '';
    final features = seat?.features ?? const <String>[];

    return [
      SeatInfoRow(
        icon: Icons.event_seat_outlined,
        label: 'Seat Number',
        value: seat?.seatNumber ?? r.itemName,
      ),
      SeatInfoRow(
        icon: Icons.meeting_room_outlined,
        label: 'Reading Room',
        value: room.isEmpty ? 'Reading Room' : room,
      ),
      if (zone.isNotEmpty)
        SeatInfoRow(icon: Icons.grid_view_rounded, label: 'Row / Zone', value: zone),
      SeatInfoRow(
        icon: Icons.calendar_today_outlined,
        label: 'Date',
        value: formatBookingDate(r.date),
      ),
      if (time != null && time.isNotEmpty)
        SeatInfoRow(icon: Icons.access_time_rounded, label: 'Time', value: time),
      if (seat != null)
        SeatInfoRow(icon: Icons.chair_alt_outlined, label: 'Seat Type', value: seat.type.label),
      if (features.isNotEmpty)
        SeatInfoRow(icon: Icons.bolt_outlined, label: 'Features', value: features.join(', ')),
      if (note.isNotEmpty)
        SeatInfoRow(icon: Icons.notes_rounded, label: 'Note', value: note),
      SeatInfoRow(
        icon: Icons.confirmation_number_outlined,
        label: 'Reservation Reference',
        value: ReservationDisplayReference.forId(r.id),
      ),
      SeatInfoRow(
        icon: Icons.check_circle_outline_rounded,
        label: 'Status',
        value: statusLabel,
        valueColor: statusColor,
      ),
    ];
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
                'Reservation Details',
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

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SeatColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8D3FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: SeatColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: SeatColors.secondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
