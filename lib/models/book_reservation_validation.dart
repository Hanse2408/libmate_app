/// Shared rules for creating and modifying book reservations.
class BookReservationValidation {
  static String? error({
    required DateTime pickupDate,
    required int loanPeriodDays,
    required String pickupLocation,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final pickup = DateTime(pickupDate.year, pickupDate.month, pickupDate.day);
    if (pickup.isBefore(today)) return 'Pickup date cannot be in the past.';
    if (pickup.isAfter(DateTime(today.year, today.month, today.day + 30))) {
      return 'Choose a pickup date within the next 30 days.';
    }
    if (loanPeriodDays < 1 || loanPeriodDays > 30) {
      return 'Choose a loan period between 1 and 30 days.';
    }
    if (pickupLocation.trim().isEmpty)
      return 'Please select a pickup location.';
    return null;
  }
}
