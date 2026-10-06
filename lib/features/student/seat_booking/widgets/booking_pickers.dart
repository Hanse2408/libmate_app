import 'package:flutter/material.dart';

import '../providers/seat_booking_provider.dart';
import 'seat_booking_colors.dart';

/// Opens the calendar, limited to the days a seat can be booked.
Future<DateTime?> pickBookingDate(
  BuildContext context, {
  required DateTime selected,
  required DateTime first,
  required DateTime last,
}) {
  return showDatePicker(
    context: context,
    initialDate: selected.isBefore(first) ? first : selected,
    firstDate: first,
    lastDate: last,
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: SeatColors.primary,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: SeatColors.text,
        ),
      ),
      child: child!,
    ),
  );
}

/// Bottom sheet listing whole hours to choose from.
Future<int?> pickBookingHour(
  BuildContext context, {
  required String title,
  required List<int> hours,
  required int selected,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SeatColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final hour in hours)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          SeatBookingProvider.hourLabel(hour),
                          style: TextStyle(
                            color: hour == selected ? SeatColors.primary : SeatColors.text,
                            fontWeight: hour == selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: hour == selected
                            ? const Icon(Icons.check_rounded, color: SeatColors.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(hour),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
