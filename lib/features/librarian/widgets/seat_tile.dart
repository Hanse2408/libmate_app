import 'package:flutter/material.dart';

import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';
import 'status_chip.dart';

/// One seat on the seat map: seat number plus a status symbol
/// (✓ available, ● reserved/occupied, ✕ maintenance). The selected seat
/// gets a thick dark outline.
class SeatTile extends StatelessWidget {
  const SeatTile({
    super.key,
    required this.seat,
    this.selected = false,
    this.onTap,
  });

  final SeatRecord seat;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = StatusChip.seatColor(seat.status);
    final foreground = Color.lerp(color, LibrarianColors.text, 0.25)!;
    final symbol = switch (seat.status) {
      SeatStatus.available => Icons.check,
      SeatStatus.maintenance => Icons.close,
      _ => Icons.circle,
    };

    return Semantics(
      button: true,
      selected: selected,
      label: 'Seat ${seat.seatNumber}, ${seat.status.label}',
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected
              ? BorderSide(color: LibrarianColors.text, width: 2.5)
              : BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    seat.seatNumber,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  symbol,
                  color: foreground,
                  size: symbol == Icons.circle ? 12 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
