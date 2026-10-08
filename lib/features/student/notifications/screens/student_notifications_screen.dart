import 'package:flutter/material.dart';

import '../../book_reservation/screens/reserve_book_screen.dart';
import '../../book_reservation/screens/book_details_screen.dart';
import '../../book_reservation/screens/reservation_details_screen.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';
import '../../seat_booking/screens/seat_reservation_details_screen.dart';
import '../../../../models/reservation.dart';
import '../../book_reservation/widgets/reservation_notice.dart';

import '../../../../models/action_result.dart';
import '../../../../models/notification.dart';
import '../../common/data/student_library_repository.dart';

enum _TypeFilter { all, books, seats }

enum _StatusFilter { all, unread, read }

/// The signed-in student's notifications (live from Firestore): reservation
/// requests, approvals, rejections, cancellations and loan updates.
class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  StudentLibraryRepository get library => widget.library;
  bool _opening = false;
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  bool _searching = false;
  String _query = '';
  _TypeFilter _typeFilter = _TypeFilter.all;
  _StatusFilter _statusFilter = _StatusFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Seat types are seats, the shared "cancelled" type follows the referenced
  /// reservation (or seat), and every other type is about books.
  bool _isSeat(StudentNotification n) {
    switch (n.type) {
      case StudentNotificationType.seatBookingConfirmed:
      case StudentNotificationType.seatReservationUpdated:
        return true;
      case StudentNotificationType.reservationCancelled:
        final reservation = library.myReservations
            .where((r) => r.id == n.reservationId)
            .firstOrNull;
        if (reservation != null) {
          return reservation.type == ReservationType.seat;
        }
        return library.seatById(n.itemId ?? '') != null;
      default:
        return false;
    }
  }

  List<StudentNotification> _visible(List<StudentNotification> all) {
    final q = _query.trim().toLowerCase();
    return all.where((n) {
      if (_typeFilter == _TypeFilter.seats && !_isSeat(n)) return false;
      if (_typeFilter == _TypeFilter.books && _isSeat(n)) return false;
      if (_statusFilter == _StatusFilter.unread && n.isRead) return false;
      if (_statusFilter == _StatusFilter.read && !n.isRead) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.message.toLowerCase().contains(q);
    }).toList();
  }

  void _changeFilters(VoidCallback change) => setState(() {
    _selected.clear();
    change();
  });

  Widget _chips<T>(
    String label,
    List<(T, String)> options,
    T current,
    void Function(T) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          for (final (value, text) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: ValueKey('filter-$label-$text'),
                label: Text(text),
                selected: value == current,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _changeFilters(() => onSelected(value)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() => Column(
    children: [
      _chips<_TypeFilter>(
        'Type',
        const [
          (_TypeFilter.all, 'All'),
          (_TypeFilter.books, 'Books'),
          (_TypeFilter.seats, 'Seats'),
        ],
        _typeFilter,
        (v) => _typeFilter = v,
      ),
      _chips<_StatusFilter>(
        'Status',
        const [
          (_StatusFilter.all, 'All'),
          (_StatusFilter.unread, 'Unread'),
          (_StatusFilter.read, 'Read'),
        ],
        _statusFilter,
        (v) => _statusFilter = v,
      ),
    ],
  );

  String _emptyText() {
    if (library.notifications.isEmpty) return 'No notifications yet';
    if (_query.trim().isNotEmpty) return 'No matching notifications';
    if (_statusFilter == _StatusFilter.unread) return 'No unread notifications';
    if (_statusFilter == _StatusFilter.read) return 'No read notifications';
    if (_typeFilter == _TypeFilter.books) return 'No book notifications';
    return 'No seat notifications';
  }

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  /// Runs a Firestore action and shows its error, if it fails.
  Future<void> _run(
    BuildContext context,
    Future<ActionResult> Function() action,
  ) async {
    final result = await action();
    if (!context.mounted || result.success) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message!)));
  }

  Future<void> _openNotification(StudentNotification notification) async {
    if (_opening) return;
    _opening = true;
    try {
      Widget destination = MyReservationsScreen(library: library);
      final reservation = library.myReservations
          .where((r) => r.id == notification.reservationId)
          .firstOrNull;
      final book = library.bookById(notification.itemId ?? '');
      if (notification.type == StudentNotificationType.bookAvailable) {
        if (book == null) {
          await showReservationNotice(
            context,
            title: 'Book unavailable',
            message:
                'This book is no longer in the catalogue, or is still loading.',
          );
          return;
        }
        destination = book.isAvailable
            ? ReserveBookScreen(library: library, bookId: book.id)
            : BookDetailsScreen(library: library, bookId: book.id);
      } else if (reservation != null) {
        destination = reservation.type == ReservationType.seat
            ? SeatReservationDetailsScreen(
                library: library,
                reservation: reservation,
              )
            : ReservationDetailsScreen(
                library: library,
                reservationId: reservation.id,
              );
      } else if (book != null) {
        destination = BookDetailsScreen(library: library, bookId: book.id);
      }
      final missing =
          reservation == null &&
          book == null &&
          (notification.reservationId ?? '').isNotEmpty;
      final result = await library.markNotificationRead(notification.id);
      if (!mounted) return;
      if (!result.success) {
        await showReservationNotice(
          context,
          title: 'Could not open notification',
          message: result.message ?? 'Please try again.',
        );
        return;
      }
      if (missing) {
        await showReservationNotice(
          context,
          title: 'Not available',
          message: 'This reservation is no longer available.',
        );
        return;
      }
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => destination));
    } finally {
      _opening = false;
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected notifications?'),
        content: const Text(
          'These notifications will be removed from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ids = {..._selected};
    final result = await library.deleteNotifications(ids);
    if (!mounted) return;
    if (result.success) {
      setState(_selected.clear);
    } else {
      await _run(context, () async => result);
    }
  }

  Widget _header(
    BuildContext context,
    List<StudentNotification> notifications,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (_selecting) {
      final allSelected = notifications.every((n) => _selected.contains(n.id));
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Cancel selection',
              onPressed: () => setState(_selected.clear),
              icon: Icon(Icons.close_rounded, color: onSurface),
            ),
            Expanded(
              child: Text(
                '${_selected.length} selected',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: allSelected ? 'Clear selection' : 'Select all',
              onPressed: () => setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll(notifications.map((n) => n.id));
                }
              }),
              icon: Icon(Icons.select_all_rounded, color: onSurface),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: _deleteSelected,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC4C4C),
              ),
            ),
          ],
        ),
      );
    }
    if (_searching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close search',
              onPressed: () => _changeFilters(() {
                _searching = false;
                _query = '';
                _searchController.clear();
              }),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: onSurface,
                size: 21,
              ),
            ),
            Expanded(
              child: TextField(
                key: const ValueKey('notification-search'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notifications',
                  border: InputBorder.none,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _changeFilters(() {
                            _query = '';
                            _searchController.clear();
                          }),
                        ),
                ),
                onChanged: (value) => _changeFilters(() => _query = value),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: onSurface,
              size: 21,
            ),
          ),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: () => setState(() => _searching = true),
            icon: Icon(Icons.search_rounded, color: onSurface),
          ),
          if (library.unreadNotificationCount > 0)
            TextButton(
              onPressed: () => _run(context, library.markAllNotificationsRead),
              child: const Text('Mark all read'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: library,
          builder: (context, _) {
            final notifications = _visible(library.notifications);
            return Column(
              children: [
                _header(context, notifications),
                _filters(),
                Expanded(child: _buildList(context, notifications)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<StudentNotification> notifications,
  ) {
    if (library.isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            library.loadError ?? _emptyText(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
    final items = _grouped(notifications);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) return _sectionHeader(context, item);
        final n = item as StudentNotification;
        final (icon, color) = _style(context, n.type);
        final selected = _selected.contains(n.id);
        final primary = Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _selecting ? _toggle(n.id) : _openNotification(n),
            onLongPress: () => _toggle(n.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDBEAFE)
                    : n.isRead
                    ? Colors.white
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? primary
                      : n.isRead
                      ? const Color(0xFFE2E8F0)
                      : primary.withValues(alpha: 0.35),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontSize: 15,
                                  fontWeight: n.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _categoryBadge(_isSeat(n)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          n.message,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _ago(n.createdAt),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selecting)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _selected.contains(n.id)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        key: ValueKey(
                          _selected.contains(n.id)
                              ? 'selected-'
                              : 'unselected-',
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else if (!n.isRead)
                    Container(
                      key: const ValueKey('unread-dot'),
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryBadge(bool seat) {
    const color = Color(0xFF64748B);
    return Container(
      key: ValueKey(seat ? 'badge-seat' : 'badge-book'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        seat ? 'SEAT' : 'BOOK',
        style: const TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Flat list of section titles (String) and notifications, in the given
  /// (newest first) order.
  List<Object> _grouped(List<StudentNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String section(DateTime t) {
      final day = DateTime(t.year, t.month, t.day);
      if (!day.isBefore(today)) return 'Today';
      if (!day.isBefore(today.subtract(const Duration(days: 1)))) {
        return 'Yesterday';
      }
      return 'Earlier';
    }

    final items = <Object>[];
    String? last;
    for (final n in notifications) {
      final s = section(n.createdAt);
      if (s != last) {
        items.add(s);
        last = s;
      }
      items.add(n);
    }
    return items;
  }

  (IconData, Color) _style(BuildContext context, StudentNotificationType type) {
    final colors = Theme.of(context).colorScheme;
    return switch (type) {
      StudentNotificationType.bookAvailable => (
        Icons.notifications_active_rounded,
        colors.primary,
      ),
      StudentNotificationType.reservationApproved => (
        Icons.check_circle_rounded,
        const Color(0xFF22A06B),
      ),
      StudentNotificationType.reservationRejected => (
        Icons.cancel_rounded,
        const Color(0xFFDC4C4C),
      ),
      StudentNotificationType.reservationCancelled => (
        Icons.event_busy_rounded,
        const Color(0xFFDC4C4C),
      ),
      StudentNotificationType.reservationRequested => (
        Icons.hourglass_top_rounded,
        const Color(0xFFF2B84B),
      ),
      StudentNotificationType.bookCollected => (
        Icons.menu_book_rounded,
        colors.primary,
      ),
      StudentNotificationType.bookReturned => (
        Icons.assignment_return_rounded,
        const Color(0xFF22A06B),
      ),
      StudentNotificationType.loanRenewed => (
        Icons.update_rounded,
        colors.primary,
      ),
      StudentNotificationType.seatBookingConfirmed => (
        Icons.event_seat_rounded,
        const Color(0xFF22A06B),
      ),
      StudentNotificationType.seatReservationUpdated => (
        Icons.edit_calendar_rounded,
        colors.primary,
      ),
    };
  }

  static String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}
