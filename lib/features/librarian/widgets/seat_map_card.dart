import 'package:flutter/material.dart';

import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';
import 'info_section_card.dart';
import 'seat_tile.dart';
import 'status_chip.dart';

/// "Reading Room A — Seat Map": a legend, then one labelled row of seat
/// tiles per zone (e.g. "ROW A — QUIET ZONE").
class SeatMapCard extends StatelessWidget {
  const SeatMapCard({
    super.key,
    required this.readingRoom,
    required this.seats,
    required this.selectedSeatId,
    required this.onSeatSelected,
  });

  final String readingRoom;
  final List<SeatRecord> seats;
  final String? selectedSeatId;
  final ValueChanged<SeatRecord> onSeatSelected;

  @override
  Widget build(BuildContext context) {
    // Group seats by zone, keeping zones in alphabetical order.
    final zones = <String, List<SeatRecord>>{};
    final sorted = [...seats]..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    for (final seat in sorted) {
      zones.putIfAbsent(seat.zone, () => []).add(seat);
    }
    final zoneNames = zones.keys.toList()..sort();

    return InfoSectionCard(
      title: '$readingRoom — Seat Map',
      children: [
        const _Legend(),
        for (final zone in zoneNames) ...[
          const SizedBox(height: LibrarianSpacing.md + 4),
          Text(
            '${zone.toUpperCase()} — ${zones[zone]!.first.type.label.toUpperCase()}',
            style: TextStyle(
              color: LibrarianColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LibrarianSpacing.sm),
          _SeatRow(
            seats: zones[zone]!,
            selectedSeatId: selectedSeatId,
            onSeatSelected: onSeatSelected,
          ),
        ],
      ],
    );
  }
}

/// Seat tiles that wrap to the available width (6 per row on phones).
class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.seats,
    required this.selectedSeatId,
    required this.onSeatSelected,
  });

  final List<SeatRecord> seats;
  final String? selectedSeatId;
  final ValueChanged<SeatRecord> onSeatSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = LibrarianSpacing.sm;
        const minTileWidth = 42.0;
        final columns = ((constraints.maxWidth + gap) ~/ (minTileWidth + gap))
            .clamp(3, 8);
        final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final seat in seats)
              SizedBox(
                width: tileWidth,
                child: SeatTile(
                  seat: seat,
                  selected: seat.id == selectedSeatId,
                  onTap: () => onSeatSelected(seat),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LibrarianSpacing.md,
      runSpacing: LibrarianSpacing.xs,
      children: [
        for (final status in SeatStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: StatusChip.seatColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: StatusChip.seatColor(status).withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status == SeatStatus.maintenance ? 'Maint.' : status.label,
                style: TextStyle(
                  color: LibrarianColors.secondaryText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
