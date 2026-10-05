import 'package:flutter/material.dart';

import '../providers/seat_booking_provider.dart';
import 'seat_booking_colors.dart';

/// "Mon, 5 Oct 2026".
String formatBookingDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Date, start time and end time of the booking. Each row opens a picker.
class BookingDetailsCard extends StatelessWidget {
  const BookingDetailsCard({
    super.key,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.isClosed,
    required this.hoursNote,
    required this.onPickDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime date;
  final int startHour;
  final int endHour;

  /// No bookable hour is left on the chosen day.
  final bool isClosed;

  /// e.g. "Open 08:00 – 20:00 · up to 2 hours per booking".
  final String hoursNote;
  final VoidCallback onPickDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SeatColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SeatColors.gold, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PickerTile(
            icon: Icons.calendar_month_rounded,
            label: 'Select Date',
            value: formatBookingDate(date),
            onTap: onPickDate,
          ),
          const SizedBox(height: 10),
          if (isClosed)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'The library is closed for the rest of today. Please choose another day.',
                style: TextStyle(color: SeatColors.red, fontSize: 13),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_rounded,
                    label: 'Start Time',
                    value: SeatBookingProvider.hourLabel(startHour),
                    onTap: onPickStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.timer_outlined,
                    label: 'End Time',
                    value: SeatBookingProvider.hourLabel(endHour),
                    onTap: onPickEnd,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            hoursNote,
            style: const TextStyle(color: SeatColors.secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: SeatColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SeatColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: SeatColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(color: SeatColors.secondary, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SeatColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: SeatColors.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
