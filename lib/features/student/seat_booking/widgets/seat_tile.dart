import 'package:flutter/material.dart';

import '../../../../models/seat.dart';
import '../providers/seat_booking_provider.dart';
import 'seat_booking_colors.dart';

/// One seat on the map. Colour and icon show its state; only an available
/// (or the selected) seat can be chosen.
class SeatTile extends StatelessWidget {
  const SeatTile({
    super.key,
    required this.seat,
    required this.availability,
    required this.selected,
    required this.onTap,
  });

  final SeatRecord seat;
  final SeatAvailability availability;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fill, line, iconColor, icon) = switch (availability) {
      _ when selected => (SeatColors.primary, SeatColors.primary, Colors.white, Icons.event_seat_rounded),
      SeatAvailability.available =>
        (SeatColors.greenFill, SeatColors.green, SeatColors.green, Icons.event_seat_rounded),
      SeatAvailability.reserved =>
        (SeatColors.greyFill, SeatColors.greyLine, SeatColors.secondary, Icons.lock_outline_rounded),
      SeatAvailability.occupied =>
        (SeatColors.redFill, SeatColors.red, SeatColors.red, Icons.person_rounded),
      SeatAvailability.maintenance =>
        (SeatColors.greyFill, SeatColors.greyLine, SeatColors.secondary, Icons.build_rounded),
    };
    final disabled = availability != SeatAvailability.available;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Seat ${seat.seatNumber}, ${selected ? 'selected' : availability.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 66,
          height: 60,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: line, width: selected ? 2 : 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 2),
              Text(
                seat.seatNumber,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : disabled
                      ? SeatColors.secondary
                      : SeatColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small key explaining the seat colours and icons.
class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color fill, Color line, IconData icon, Color iconColor, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: line, width: 1.2),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: SeatColors.secondary, fontSize: 12)),
      ],
    );

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        item(SeatColors.greenFill, SeatColors.green, Icons.event_seat_rounded, SeatColors.green, 'Available'),
        item(SeatColors.primary, SeatColors.primary, Icons.event_seat_rounded, Colors.white, 'Selected'),
        item(SeatColors.greyFill, SeatColors.greyLine, Icons.lock_outline_rounded, SeatColors.secondary, 'Reserved'),
        item(SeatColors.redFill, SeatColors.red, Icons.person_rounded, SeatColors.red, 'Occupied'),
        item(SeatColors.greyFill, SeatColors.greyLine, Icons.build_rounded, SeatColors.secondary, 'Maintenance'),
      ],
    );
  }
}
