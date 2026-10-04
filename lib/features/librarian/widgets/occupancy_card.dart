import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/seat_record.dart';
import '../theme/librarian_theme.dart';
import 'status_chip.dart';

/// Reading-room occupancy: a ring showing the occupied percentage and a
/// legend with the number of seats in each state.
class OccupancyCard extends StatelessWidget {
  const OccupancyCard({
    super.key,
    required this.occupancyRate,
    required this.available,
    required this.reserved,
    required this.occupied,
    required this.maintenance,
    this.onTap,
  });

  /// 0.0 - 1.0
  final double occupancyRate;
  final int available;
  final int reserved;
  final int occupied;
  final int maintenance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (occupancyRate * 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
        side: BorderSide(
          color: LibrarianColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LibrarianSpacing.lg),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 120,
                child: CustomPaint(
                  painter: _RingPainter(occupancyRate),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: LibrarianColors.text,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'OCCUPIED',
                          style: TextStyle(
                            color: LibrarianColors.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: LibrarianSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    for (final (status, count) in [
                      (SeatStatus.available, available),
                      (SeatStatus.reserved, reserved),
                      (SeatStatus.occupied, occupied),
                      if (maintenance > 0) (SeatStatus.maintenance, maintenance),
                    ])
                      _LegendRow(
                        status.label,
                        count,
                        StatusChip.seatColor(status),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LibrarianColors.secondaryText,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(color: LibrarianColors.text, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Draws a grey background ring and a green arc for the occupied share.
class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      ringRect,
      0,
      2 * math.pi,
      false,
      paint..color = LibrarianColors.border,
    );
    canvas.drawArc(
      ringRect,
      -math.pi / 2, // start at 12 o'clock
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      paint..color = LibrarianColors.available,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.value != value;
}
