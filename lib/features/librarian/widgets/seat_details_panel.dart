import 'package:flutter/material.dart';

import '../models/reservation_record.dart';
import '../../../core/widgets/stored_image.dart';
import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import 'info_section_card.dart';
import 'status_chip.dart';

/// Details of the seat selected on the seat map. Shows who reserved it when
/// there is an approved booking, otherwise the seat's own information.
class SeatDetailsPanel extends StatelessWidget {
  const SeatDetailsPanel({
    super.key,
    required this.seat,
    required this.reservation,
    required this.onUpdateStatus,
    this.onEdit,
  });

  final SeatRecord seat;
  final ReservationRecord? reservation;
  final VoidCallback onUpdateStatus;

  /// Opens the Edit Seat form (details, photo, delete).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (reservation != null) ...[
        ('Reserved By', reservation!.studentName),
        if (reservation!.timeSlot != null)
          ('Time Slot', LibrarianFormatters.timeRange(reservation!.timeSlot!)),
        ('Student ID', reservation!.studentId),
        ('Date', LibrarianFormatters.date(reservation!.date)),
      ] else ...[
        ('Zone', '${seat.zone} · ${seat.readingRoom}'),
        ('Seat Type', seat.type.label),
        ('Features', _features()),
        if (seat.note.isNotEmpty) ('Note', seat.note),
      ],
    ];

    return InfoSectionCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Seat ${seat.seatNumber}',
                style: TextStyle(
                  color: LibrarianColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            StatusChip.seat(seat.status),
          ],
        ),
        const SizedBox(height: LibrarianSpacing.sm),
        if (seat.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: LibrarianSpacing.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: StoredImage(
                  url: seat.imageUrl,
                  fallback: ColoredBox(color: LibrarianColors.lightBlue),
                ),
              ),
            ),
          ),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: LibrarianColors.secondaryText,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: LibrarianSpacing.md),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: LibrarianColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: LibrarianSpacing.md),
        FilledButton(
          onPressed: onUpdateStatus,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          child: const Text('Update Seat Status'),
        ),
        if (onEdit != null) ...[
          const SizedBox(height: LibrarianSpacing.sm),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Seat'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
          ),
        ],
      ],
    );
  }

  String _features() {
    final features = seat.features;
    return features.isEmpty ? 'None' : features.join(', ');
  }
}
