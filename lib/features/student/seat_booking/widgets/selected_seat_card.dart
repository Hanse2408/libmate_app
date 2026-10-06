import 'package:flutter/material.dart';

import '../../../../core/widgets/stored_image.dart';
import '../../../../models/seat.dart';
import 'seat_booking_colors.dart';

/// Compact details of the chosen seat. Optional fields are only shown when set.
class SelectedSeatCard extends StatelessWidget {
  const SelectedSeatCard({super.key, required this.seat});

  final SeatRecord seat;

  @override
  Widget build(BuildContext context) {
    final features = seat.features;
    final zone = seat.zone.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SeatColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SeatColors.primary, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seat.imageUrl != null && seat.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 84,
                height: 84,
                child: StoredImage(
                  url: seat.imageUrl,
                  fallback: const ColoredBox(color: SeatColors.lightBlue),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat ${seat.seatNumber}',
                  style: const TextStyle(
                    color: SeatColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [seat.readingRoom, if (zone.isNotEmpty) zone].join(' · '),
                  style: const TextStyle(color: SeatColors.secondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(seat.type.label, filled: true),
                    for (final feature in features) _Chip(feature),
                  ],
                ),
                if (seat.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    seat.note.trim(),
                    style: const TextStyle(color: SeatColors.secondary, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? SeatColors.lightBlue : SeatColors.greyFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? SeatColors.primary : SeatColors.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
