import 'package:flutter/material.dart';

import 'seat_booking_colors.dart';

/// One label/value line of a seat reservation.
class SeatInfoRow {
  const SeatInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = SeatColors.text,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
}

/// White rounded card listing the details of a seat reservation.
class SeatReservationInfoCard extends StatelessWidget {
  const SeatReservationInfoCard({super.key, required this.title, required this.rows});

  final String title;
  final List<SeatInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: SeatColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SeatColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: SeatColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: SeatColors.border),
          const SizedBox(height: 5),
          for (final row in rows) _InfoLine(row: row),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.row});

  final SeatInfoRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Icon(row.icon, color: SeatColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            row.label,
            style: const TextStyle(color: SeatColors.secondary, fontSize: 12.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: row.valueColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured status pill: green Confirmed, red Cancelled/Rejected, blue Completed.
class SeatStatusChip extends StatelessWidget {
  const SeatStatusChip({super.key, required this.label, required this.color, required this.fill});

  final String label;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
