import 'package:flutter/material.dart';

import '../providers/seat_booking_provider.dart';
import 'seat_booking_colors.dart';
import 'seat_tile.dart';

/// Seats grouped by reading room and row/zone, built from the live seat list.
/// Each group wraps onto as many lines as it needs, so any number of seats fits.
class SeatMap extends StatelessWidget {
  const SeatMap({super.key, required this.provider, required this.onBlockedSeatTap});

  final SeatBookingProvider provider;

  /// Called when an unavailable seat is tapped (to explain why).
  final void Function(String message) onBlockedSeatTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final room in provider.rooms) ...[
          _RoomHeader(
            name: room.name,
            freeSeats: [
              for (final zone in room.zones)
                for (final seat in zone.seats)
                  if (provider.availabilityOf(seat) == SeatAvailability.available) seat,
            ].length,
          ),
          const SizedBox(height: 10),
          for (final zone in room.zones) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                zone.name,
                style: const TextStyle(
                  color: SeatColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final seat in zone.seats)
                  SeatTile(
                    key: ValueKey('seat-${seat.id}'),
                    seat: seat,
                    availability: provider.availabilityOf(seat),
                    selected: provider.selectedSeatId == seat.id,
                    onTap: () {
                      if (provider.availabilityOf(seat) == SeatAvailability.available) {
                        provider.selectSeat(seat);
                      } else {
                        onBlockedSeatTap(
                          provider.blockerFor(seat) ?? 'Seat ${seat.seatNumber} is not available.',
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.name, required this.freeSeats});

  final String name;
  final int freeSeats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SeatColors.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.meeting_room_outlined, color: SeatColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SeatColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SeatColors.greenFill,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$freeSeats free',
            style: const TextStyle(
              color: SeatColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
