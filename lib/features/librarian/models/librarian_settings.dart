/// Librarian / library preferences shown on the Settings screen.
/// Kept as one small object so it can later be saved as a single Firestore
/// document (e.g. settings/{librarianId}).
class LibrarianSettings {
  const LibrarianSettings({
    this.openingHour = 8,
    this.closingHour = 20,
    this.maxBorrowLimit = 5,
    this.loanPeriodDays = 14,
    this.seatBookingHours = 2,
    this.reservationNotifications = true,
    this.overdueReminders = true,
    this.availabilityNotifications = false,
  });

  /// Library opening hours, whole hours in 24h time (8 = 08:00).
  final int openingHour;
  final int closingHour;

  /// Books one member may have on loan at the same time.
  final int maxBorrowLimit;

  /// Default loan period; also used when a loan is renewed.
  final int loanPeriodDays;

  /// Maximum length of one reading-room seat booking.
  final int seatBookingHours;

  final bool reservationNotifications;
  final bool overdueReminders;
  final bool availabilityNotifications;

  static const int maxRenewals = 2;

  LibrarianSettings copyWith({
    int? openingHour,
    int? closingHour,
    int? maxBorrowLimit,
    int? loanPeriodDays,
    int? seatBookingHours,
    bool? reservationNotifications,
    bool? overdueReminders,
    bool? availabilityNotifications,
  }) {
    return LibrarianSettings(
      openingHour: openingHour ?? this.openingHour,
      closingHour: closingHour ?? this.closingHour,
      maxBorrowLimit: maxBorrowLimit ?? this.maxBorrowLimit,
      loanPeriodDays: loanPeriodDays ?? this.loanPeriodDays,
      seatBookingHours: seatBookingHours ?? this.seatBookingHours,
      reservationNotifications:
          reservationNotifications ?? this.reservationNotifications,
      overdueReminders: overdueReminders ?? this.overdueReminders,
      availabilityNotifications:
          availabilityNotifications ?? this.availabilityNotifications,
    );
  }
}
