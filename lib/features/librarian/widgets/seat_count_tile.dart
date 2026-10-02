import 'package:flutter/material.dart';

import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';
import 'status_chip.dart';

/// Tinted count box on Seat Management, e.g. "18 Available".
class SeatCountTile extends StatelessWidget {
  const SeatCountTile({super.key, required this.status, required this.count});

  final SeatStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = StatusChip.seatColor(status);
    final textColor = Color.lerp(color, LibrarianColors.text, 0.25)!;
    final style = TextStyle(
      color: textColor,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LibrarianSpacing.md,
        vertical: LibrarianSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count', style: style),
            Text(status.label, style: style),
          ],
        ),
      ),
    );
  }
}
