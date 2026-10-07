/// Shared pickup choices for book reservations.
class BookPickupLocations {
  BookPickupLocations._();

  static const defaultLocation = 'Main Desk (Floor 1)';
  static const all = [
    defaultLocation,
    'Main Desk (Floor 2)',
    'Library Counter',
  ];

  /// Keep an older reservation's saved location until the student changes it.
  static List<String> including(String current) => {...all, current}.toList();
}