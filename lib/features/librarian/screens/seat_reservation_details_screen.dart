import 'package:flutter/material.dart';

import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/reservation_actions_card.dart';
import '../widgets/reservation_detail_sections.dart';
import '../widgets/reservation_status_banner.dart';
import '../widgets/status_chip.dart';

/// Seat Reservation Details (Figma): status banner, student info,
/// reservation info (seat, date, start/end), notes and actions.
class SeatReservationDetailsScreen extends StatelessWidget {
  const SeatReservationDetailsScreen({
    super.key,
    required this.reservation,
    required this.seat,
    this.blocker,
    this.onBack,
  });

  final ReservationRecord reservation;

  /// Null if the seat was removed.
  final SeatRecord? seat;
  final String? blocker;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final slot = reservation.timeSlot?.split('-');
    final start = slot == null ? '-' : LibrarianFormatters.startTime(slot.first);
    final end = (slot == null || slot.length < 2)
        ? '-'
        : LibrarianFormatters.startTime(slot.last);

    return LibrarianPage(
      maxWidth: 760,
      children: [
        LibrarianPageHeader(
          title: 'Seat Reservation Details',
          subtitle: 'Reservation / Seats',
          trailing: StatusChip.reservation(reservation.status),
          onBack: onBack,
        ),
        ReservationReference(reservationId: reservation.id),
        ReservationStatusBanner(reservation: reservation, blocker: blocker),
        StudentInfoCard(reservation: reservation),
        InfoSectionCard(
          title: 'Reservation Information',
          children: [
            InfoGrid(
              items: [
                InfoItem('Type', seat == null ? 'Reading Room Seat' : '${seat!.type.label} Seat'),
                InfoItem(
                  'Seat',
                  seat == null
                      ? reservation.itemName
                      : '${seat!.seatNumber} · ${seat!.readingRoom}',
                ),
                InfoItem('Date', LibrarianFormatters.date(reservation.date)),
                InfoItem(
                  'Status',
                  reservation.status.label,
                  valueColor: StatusChip.reservationColor(reservation.status),
                ),
                InfoItem('Start', start),
                InfoItem('End', end),
                if (seat != null)
                  InfoItem(
                    'Seat Now',
                    seat!.status.label,
                    valueColor: seat!.status == SeatStatus.available
                        ? null
                        : LibrarianColors.unavailable,
                  ),
              ],
            ),
          ],
        ),
        AdditionalInfoCard(note: reservation.note),
        ReservationActionsCard(reservation: reservation),
      ],
    );
  }
}
