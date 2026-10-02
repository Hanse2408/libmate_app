/// Form validators for the Add Book and Add Seat forms.
/// Each returns an error message, or null when the value is valid.
class LibrarianValidators {
  const LibrarianValidators._();

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// ISBN-10 or ISBN-13; hyphens and spaces are allowed.
  static String? isbn(String? value) {
    final missing = required(value, 'ISBN');
    if (missing != null) return missing;
    if (!RegExp(r'^[0-9Xx\- ]+$').hasMatch(value!.trim())) {
      return 'ISBN can only contain digits and hyphens';
    }
    final digits = value.replaceAll(RegExp(r'[\- ]'), '');
    if (digits.length != 10 && digits.length != 13) {
      return 'ISBN must have 10 or 13 digits';
    }
    return null;
  }

  /// A whole number from 1 to [max].
  static String? positiveCount(String? value, String fieldName, {int max = 999}) {
    final missing = required(value, fieldName);
    if (missing != null) return missing;
    final number = int.tryParse(value!.trim());
    if (number == null) return '$fieldName must be a whole number';
    if (number < 1) return '$fieldName must be at least 1';
    if (number > max) return '$fieldName cannot be more than $max';
    return null;
  }

  /// One or two letters followed by 1-3 digits, e.g. "D09" or "AB12".
  static String? seatNumber(String? value) {
    final missing = required(value, 'Seat number');
    if (missing != null) return missing;
    if (!RegExp(r'^[A-Za-z]{1,2}\d{1,3}$').hasMatch(value!.trim())) {
      return 'Use a letter and number, e.g. D09';
    }
    return null;
  }
}
