/// Small date helpers for Librarian screens (avoids adding the intl package).
class LibrarianFormatters {
  const LibrarianFormatters._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "2 Oct 2026"
  static String date(DateTime value) {
    return '${value.day} ${_months[value.month - 1]} ${value.year}';
  }

  /// e.g. "Just now", "25 min ago", "3 h ago", "2 d ago"
  static String timeAgo(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} h ago';
    if (difference.inDays < 7) return '${difference.inDays} d ago';
    return date(value);
  }

  /// First letter of the first and last name, e.g. "Nethmi Perera" -> "NP".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// Start of a time slot in 12-hour format: "13:00 - 15:00" -> "01:00 PM".
  static String startTime(String timeSlot) {
    final start = timeSlot.split('-').first.trim();
    final pieces = start.split(':');
    final hour = int.tryParse(pieces.first);
    if (hour == null) return start;
    final minutes = pieces.length > 1 ? pieces[1] : '00';
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minutes $period';
  }

  /// Whole slot in 12-hour format: "10:00 - 14:00" -> "10:00 AM - 02:00 PM".
  static String timeRange(String timeSlot) {
    final parts = timeSlot.split('-');
    if (parts.length < 2) return startTime(timeSlot);
    return '${startTime(parts[0])} - ${startTime(parts[1])}';
  }

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// e.g. "Sun, 13 Sep 2026"
  static String weekdayDate(DateTime value) {
    return '${_weekdays[value.weekday - 1]}, ${date(value)}';
  }

  /// "Good morning" / "Good afternoon" / "Good evening".
  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
