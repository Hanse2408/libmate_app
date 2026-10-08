import 'package:flutter/material.dart';

import '../models/reservation_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import 'librarian_accent_card.dart';
import 'status_chip.dart';

/// One reservation row: student initials, name, item, time and status.
/// The card's accent colour follows the reservation status.
class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    this.showDate = true,
    this.onTap,
  });

  final ReservationRecord reservation;

  /// The Dashboard only lists today's reservations, so it hides the date.
  /// The date is shown under the item; the time stays on the right (Figma).
  final bool showDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LibrarianAccentCard(
      accentColor: StatusChip.reservationColor(reservation.status),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: LibrarianColors.avatar,
            child: Text(
              LibrarianFormatters.initials(reservation.studentName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.studentName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${reservation.itemName} · ${reservation.type.cardLabel}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: LibrarianColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(reservation.displayReference, style: textTheme.bodySmall),
                if (showDate) ...[
                  const SizedBox(height: 2),
                  Text(
                    LibrarianFormatters.date(reservation.date),
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: LibrarianSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (reservation.timeSlot != null)
                Text(
                  LibrarianFormatters.startTime(reservation.timeSlot!),
                  style: textTheme.bodySmall,
                ),
              const SizedBox(height: LibrarianSpacing.xs + 2),
              // "Ready for Pickup" is the longest label: on narrow phones it
              // shrinks a little instead of overflowing the row.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 108),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatusChip.forReservation(reservation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
