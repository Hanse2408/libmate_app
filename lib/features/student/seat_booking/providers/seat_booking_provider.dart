import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../models/action_result.dart';
import '../../../../models/reservation.dart';
import '../../../../models/seat.dart';
import '../../common/data/student_library_repository.dart';

/// What a seat looks like for the selected date and time.
enum SeatAvailability { available, reserved, occupied, maintenance }

/// State of the Book a Seat screen: the chosen date, time and seat, and which
/// seats are free. Seats and settings come live from [library] (Firestore);
/// the hours already taken on the chosen day come from `seatSlots`.
///
/// Pass [editing] to modify an existing seat booking: the date, times and seat
/// start as that booking, and its own seat-hours never count as taken.
class SeatBookingProvider extends ChangeNotifier {
  SeatBookingProvider(this.library, {this.editing}) {
    final original = editing;
    if (original != null) {
      _date = DateTime(original.date.year, original.date.month, original.date.day);
      _startHour = original.startHour ?? 0;
      _endHour = original.endHour ?? 1;
      _selectedSeatId = original.itemId;
    }
    _fixTimes();
    library.addListener(_onLibraryChanged);
    _watchSlots();
  }

  final StudentLibraryRepository library;

  /// The booking being modified, or null when booking a new seat.
  final ReservationRecord? editing;

  late DateTime _date = today;
  int _startHour = 0;
  int _endHour = 1;
  String? _selectedSeatId;
  Set<String>? _booked;
  bool _slotsFailed = false;
  bool _isBooking = false;
  bool _disposed = false;
  String? _error;
  StreamSubscription<Set<String>>? _slotsSubscription;

  DateTime get date => _date;
  int get startHour => _startHour;
  int get endHour => _endHour;
  bool get isBooking => _isBooking;
  bool get slotsFailed => _slotsFailed;

  /// Why the last booking attempt failed, or null.
  String? get error => _error;

  /// False until the taken hours for the chosen day have arrived.
  bool get slotsLoaded => _booked != null;

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Students can book today and the next 6 days.
  DateTime get lastBookableDay => today.add(const Duration(days: 6));

  // ---------------- Time rules ----------------

  /// Earliest bookable hour on [day]: opening time, or the next hour today.
  int _firstStartHour(DateTime day) {
    final settings = library.settings;
    final next = day == today ? DateTime.now().hour + 1 : settings.openingHour;
    return next < settings.openingHour ? settings.openingHour : next;
  }

  List<int> get startHours => [
    for (var h = _firstStartHour(_date); h < library.settings.closingHour; h++) h,
  ];

  /// End times allowed for the chosen start: within the library's maximum
  /// booking length and closing time.
  List<int> get endHours {
    final settings = library.settings;
    final longest = settings.seatBookingHours < 1 ? 1 : settings.seatBookingHours;
    return [
      for (var e = _startHour + 1; e <= _startHour + longest && e <= settings.closingHour; e++) e,
    ];
  }

  /// No bookable hour left on the chosen day.
  bool get isClosed => startHours.isEmpty;

  static String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  /// The times are still exactly those of the booking being modified (kept
  /// even if its start has already passed).
  bool get _isOriginalTime {
    final original = editing;
    return original != null &&
        _date == DateTime(original.date.year, original.date.month, original.date.day) &&
        _startHour == original.startHour &&
        _endHour == original.endHour;
  }

  void _fixTimes() {
    if (_isOriginalTime) return;
    final starts = startHours;
    if (starts.isEmpty) return;
    if (!starts.contains(_startHour)) _startHour = starts.first;
    final ends = endHours;
    if (!ends.contains(_endHour)) _endHour = ends.first;
  }

  // ---------------- Changing the booking ----------------

  void setDate(DateTime day) {
    final picked = DateTime(day.year, day.month, day.day);
    if (picked == _date) return;
    _date = picked;
    _error = null;
    _fixTimes();
    _watchSlots();
    _selectionChanged(clear: true);
  }

  void setStartHour(int hour) {
    _startHour = hour;
    _error = null;
    _fixTimes();
    _selectionChanged();
  }

  void setEndHour(int hour) {
    _endHour = hour;
    _error = null;
    _selectionChanged();
  }

  void _watchSlots() {
    _slotsSubscription?.cancel();
    _booked = null;
    _slotsFailed = false;
    _slotsSubscription = library.bookedSlotIds(_date).listen(
      (ids) {
        _booked = ids;
        _slotsFailed = false;
        _selectionChanged();
      },
      onError: (Object _) {
        _slotsFailed = true;
        _notify();
      },
    );
  }

  void _onLibraryChanged() {
    _fixTimes();
    _selectionChanged();
  }

  // ---------------- Seats ----------------

  /// Seat groups for the map: reading room, then row/zone, in seat order.
  List<SeatRoomGroup> get rooms {
    final byRoom = <String, Map<String, List<SeatRecord>>>{};
    for (final seat in library.seats) {
      final room = seat.readingRoom.trim().isEmpty ? 'Reading Room' : seat.readingRoom.trim();
      final zone = seat.zone.trim().isEmpty ? 'Seats' : seat.zone.trim();
      byRoom.putIfAbsent(room, () => {}).putIfAbsent(zone, () => []).add(seat);
    }
    final roomNames = byRoom.keys.toList()..sort(_compareNatural);
    return [
      for (final room in roomNames)
        SeatRoomGroup(
          name: room,
          zones: [
            for (final zone in (byRoom[room]!.keys.toList()..sort(_compareNatural)))
              SeatZoneGroup(
                name: zone,
                seats: byRoom[room]![zone]!
                  ..sort((a, b) => _compareNatural(a.seatNumber, b.seatNumber)),
              ),
          ],
        ),
    ];
  }

  /// Status of [seat] for the chosen date and time (its own state and the
  /// hours other students already hold).
  SeatAvailability availabilityOf(SeatRecord seat) {
    if (seat.status == SeatStatus.maintenance) return SeatAvailability.maintenance;
    if (_date == today && seat.status == SeatStatus.occupied) return SeatAvailability.occupied;
    final wanted = SeatSlots.ids(seat.id, _date, _startHour, _endHour);
    if (wanted.any(_takenSlots.contains)) return SeatAvailability.reserved;
    return SeatAvailability.available;
  }

  /// Slots held by other bookings: the booking being modified never blocks itself.
  Set<String> get _takenSlots {
    final booked = _booked ?? const <String>{};
    final original = editing;
    final startHour = original?.startHour;
    final endHour = original?.endHour;
    if (original == null || startHour == null || endHour == null) return booked;
    return booked.difference(
      SeatSlots.ids(original.itemId, original.date, startHour, endHour).toSet(),
    );
  }

  /// Why [seat] cannot be booked now, or null.
  String? blockerFor(SeatRecord seat) {
    if (isClosed) return 'The library is closed on this day.';
    return library.seatBookingBlocker(
      seat,
      _date,
      _startHour,
      _endHour,
      bookedSlots: _takenSlots,
      ignoreReservationId: editing?.id,
    );
  }

  /// The student already holds a seat at the chosen time.
  bool get hasOwnBooking =>
      !isClosed &&
      library.hasSeatBookingAt(
        _date,
        _startHour,
        _endHour,
        ignoreReservationId: editing?.id,
      );

  String? get selectedSeatId => _selectedSeatId;

  /// The chosen seat, only while it is still free for the chosen time.
  SeatRecord? get selectedSeat {
    final id = _selectedSeatId;
    return id == null ? null : library.seatById(id);
  }

  bool get canBook {
    final seat = selectedSeat;
    return !_isBooking && slotsLoaded && seat != null && blockerFor(seat) == null;
  }

  /// Modifying: the date, times or seat differ from the original booking.
  bool get hasChanges {
    final original = editing;
    return original == null ||
        !_isOriginalTime ||
        _selectedSeatId != original.itemId;
  }

  /// Modifying: a valid, changed booking can be saved.
  bool get canSave {
    final seat = selectedSeat;
    return !_isBooking &&
        slotsLoaded &&
        seat != null &&
        hasChanges &&
        blockerFor(seat) == null;
  }

  void selectSeat(SeatRecord seat) {
    if (_isBooking || availabilityOf(seat) != SeatAvailability.available) return;
    _selectedSeatId = _selectedSeatId == seat.id ? null : seat.id;
    _error = null;
    _notify();
  }

  /// Drops the chosen seat if it was removed or is no longer free.
  void _selectionChanged({bool clear = false}) {
    final seat = selectedSeat;
    if (editing != null) {
      // Modifying keeps the chosen seat across date and time changes while
      // it is still free; it is dropped once the new availability says no.
      final gone = seat == null && !library.isLoading;
      final taken = seat != null &&
          slotsLoaded &&
          availabilityOf(seat) != SeatAvailability.available;
      if (gone || taken) _selectedSeatId = null;
    } else if (clear ||
        seat == null ||
        !slotsLoaded ||
        availabilityOf(seat) != SeatAvailability.available) {
      _selectedSeatId = null;
    }
    _notify();
  }

  // ---------------- Booking ----------------

  /// Books the chosen seat. The repository re-checks everything in a
  /// transaction, so a seat taken a moment ago is refused.
  Future<ActionResult> book() async {
    final seat = selectedSeat;
    if (seat == null || !canBook) {
      return const ActionResult.failure('Please choose an available seat first.');
    }
    _isBooking = true;
    _error = null;
    _notify();
    final result = await library.bookSeat(
      seat: seat,
      date: _date,
      startHour: _startHour,
      endHour: _endHour,
    );
    _isBooking = false;
    if (result.success) {
      _selectedSeatId = null;
    } else {
      _error = result.message;
    }
    _notify();
    return result;
  }

  /// Modifying: saves the changes to the same reservation.
  Future<ActionResult> save() async {
    final seat = selectedSeat;
    final original = editing;
    if (original == null || seat == null || !canSave) {
      return const ActionResult.failure('Please change the seat or time first.');
    }
    _isBooking = true;
    _error = null;
    _notify();
    final result = await library.modifySeatReservation(
      reservationId: original.id,
      seat: seat,
      date: _date,
      startHour: _startHour,
      endHour: _endHour,
    );
    _isBooking = false;
    if (!result.success) _error = result.message;
    _notify();
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _slotsSubscription?.cancel();
    library.removeListener(_onLibraryChanged);
    super.dispose();
  }

  /// "A2" before "A10": compares text, then the number inside it.
  static int _compareNatural(String a, String b) {
    final pattern = RegExp(r'^(\D*)(\d*)(.*)$');
    final x = pattern.firstMatch(a.toUpperCase())!;
    final y = pattern.firstMatch(b.toUpperCase())!;
    final text = x.group(1)!.compareTo(y.group(1)!);
    if (text != 0) return text;
    final numberA = int.tryParse(x.group(2)!) ?? 0;
    final numberB = int.tryParse(y.group(2)!) ?? 0;
    if (numberA != numberB) return numberA.compareTo(numberB);
    return x.group(3)!.compareTo(y.group(3)!);
  }
}

class SeatRoomGroup {
  const SeatRoomGroup({required this.name, required this.zones});

  final String name;
  final List<SeatZoneGroup> zones;
}

class SeatZoneGroup {
  const SeatZoneGroup({required this.name, required this.seats});

  final String name;
  final List<SeatRecord> seats;
}
