enum SeatStatus {
  available('Available'),
  reserved('Reserved'),
  occupied('Occupied'),
  maintenance('Maintenance');

  const SeatStatus(this.label);
  final String label;
}

enum SeatType {
  individualDesk('Individual Desk'),
  groupStudy('Group Study'),
  quietZone('Quiet Zone');

  const SeatType(this.label);
  final String label;
}

/// A reading-room seat managed by the Librarian.
/// Local model used with mock data until the shared Seat model is integrated.
class SeatRecord {
  const SeatRecord({
    required this.id,
    required this.seatNumber,
    required this.zone,
    required this.readingRoom,
    required this.type,
    required this.status,
    this.hasPowerOutlet = false,
    this.hasReadingLamp = false,
    this.isAccessible = false,
    this.isNearWindow = false,
    this.note = '',
  });

  final String id;

  /// e.g. "A01"
  final String seatNumber;

  /// Row on the seat map, e.g. "Row A".
  final String zone;
  final String readingRoom;
  final SeatType type;
  final SeatStatus status;
  final bool hasPowerOutlet;
  final bool hasReadingLamp;
  final bool isAccessible;
  final bool isNearWindow;
  final String note;

  SeatRecord copyWith({SeatStatus? status}) {
    return SeatRecord(
      id: id,
      seatNumber: seatNumber,
      zone: zone,
      readingRoom: readingRoom,
      type: type,
      status: status ?? this.status,
      hasPowerOutlet: hasPowerOutlet,
      hasReadingLamp: hasReadingLamp,
      isAccessible: isAccessible,
      isNearWindow: isNearWindow,
      note: note,
    );
  }
}
