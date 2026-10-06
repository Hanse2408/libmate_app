import 'package:cloud_firestore/cloud_firestore.dart';

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

/// A reading-room seat, stored in Firestore at `seats/{id}`.
///
/// [status] is the seat's state right now, set by the librarian (e.g.
/// maintenance). Bookings for a date and time are checked separately with
/// the `seatSlots` documents (see SeatSlots).
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
    this.imageUrl,
    this.imagePath,
    this.imagePublicId,
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

  /// HTTPS delivery URL of the uploaded seat photo, if any.
  final String? imageUrl;

  /// Legacy Firebase Storage path, read for older seat documents only.
  final String? imagePath;
  final String? imagePublicId;

  /// Seat numbers are unique within a reading room. Stored as `seatKey` so
  /// a duplicate can be found with a Firestore query.
  static String seatKeyOf(String seatNumber, String readingRoom) =>
      '${readingRoom.trim().toLowerCase()}|${seatNumber.trim().toUpperCase()}';

  List<String> get features => [
    if (hasPowerOutlet) 'Power outlet',
    if (hasReadingLamp) 'Reading lamp',
    if (isAccessible) 'Accessible',
    if (isNearWindow) 'Near window',
  ];

  factory SeatRecord.fromMap(String id, Map<String, dynamic> map) {
    return SeatRecord(
      id: id,
      seatNumber: map['seatNumber'] as String? ?? '',
      zone: map['zone'] as String? ?? '',
      readingRoom: map['readingRoom'] as String? ?? '',
      type: _byName(SeatType.values, map['type'], SeatType.individualDesk),
      status: _byName(SeatStatus.values, map['status'], SeatStatus.available),
      hasPowerOutlet: map['hasPowerOutlet'] as bool? ?? false,
      hasReadingLamp: map['hasReadingLamp'] as bool? ?? false,
      isAccessible: map['isAccessible'] as bool? ?? false,
      isNearWindow: map['isNearWindow'] as bool? ?? false,
      note: map['note'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      imagePublicId: map['imagePublicId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seatNumber': seatNumber,
      'zone': zone,
      'readingRoom': readingRoom,
      'seatKey': seatKeyOf(seatNumber, readingRoom),
      'type': type.name,
      'status': status.name,
      'hasPowerOutlet': hasPowerOutlet,
      'hasReadingLamp': hasReadingLamp,
      'isAccessible': isAccessible,
      'isNearWindow': isNearWindow,
      'note': note,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'imagePublicId': imagePublicId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SeatRecord copyWith({
    String? seatNumber,
    String? zone,
    String? readingRoom,
    SeatType? type,
    SeatStatus? status,
    bool? hasPowerOutlet,
    bool? hasReadingLamp,
    bool? isAccessible,
    bool? isNearWindow,
    String? note,
    String? imageUrl,
    String? imagePath,
    String? imagePublicId,
    bool clearImage = false,
    bool clearLegacyImagePath = false,
  }) {
    return SeatRecord(
      id: id,
      seatNumber: seatNumber ?? this.seatNumber,
      zone: zone ?? this.zone,
      readingRoom: readingRoom ?? this.readingRoom,
      type: type ?? this.type,
      status: status ?? this.status,
      hasPowerOutlet: hasPowerOutlet ?? this.hasPowerOutlet,
      hasReadingLamp: hasReadingLamp ?? this.hasReadingLamp,
      isAccessible: isAccessible ?? this.isAccessible,
      isNearWindow: isNearWindow ?? this.isNearWindow,
      note: note ?? this.note,
      imageUrl: clearImage ? null : imageUrl ?? this.imageUrl,
      imagePath: clearImage || clearLegacyImagePath
          ? null
          : imagePath ?? this.imagePath,
      imagePublicId: clearImage ? null : imagePublicId ?? this.imagePublicId,
    );
  }
}

/// One hour of one seat on one day is a document `seatSlots/{seatId}_{yyyyMMdd}_{HH}`.
///
/// A seat booking creates one slot document per hour inside the same
/// Firestore transaction as the reservation. If any of those documents
/// already exists, another booking overlaps and the transaction is refused,
/// so two students can never hold the same seat at the same time.
class SeatSlots {
  const SeatSlots._();

  static String id(String seatId, DateTime date, int hour) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${seatId}_${date.year}${two(date.month)}${two(date.day)}_${two(hour)}';
  }

  /// Slot ids for a booking from [startHour] up to (not including) [endHour].
  static List<String> ids(
    String seatId,
    DateTime date,
    int startHour,
    int endHour,
  ) {
    return [for (var h = startHour; h < endHour; h++) id(seatId, date, h)];
  }
}

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
