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

/// The signed-in student's notifications (live from Firestore): reservation
/// requests, approvals, rejections, cancellations and loan updates.
class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  StudentLibraryRepository get library => widget.library;
  bool _opening = false;

  /// Runs a Firestore action and shows its error, if it fails.
  Future<void> _run(BuildContext context, Future<ActionResult> Function() action) async {
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
          .where((r) => r.id == notification.reservationId).firstOrNull;
      final book = library.bookById(notification.itemId ?? '');
      if (notification.type == StudentNotificationType.bookAvailable) {
        if (book == null) {
          await showReservationNotice(context, title: 'Book unavailable',
            message: 'This book is no longer in the catalogue, or is still loading.');
          return;
        }
        destination = book.isAvailable
            ? ReserveBookScreen(library: library, bookId: book.id)
            : BookDetailsScreen(library: library, bookId: book.id);
      } else if (reservation != null) {
        destination = reservation.type == ReservationType.seat
            ? SeatReservationDetailsScreen(library: library, reservation: reservation)
            : ReservationDetailsScreen(library: library, reservationId: reservation.id);
      } else if (book != null) {
        destination = BookDetailsScreen(library: library, bookId: book.id);
      }
      final result = await library.dismissNotification(notification.id);
      if (!mounted) return;
      if (!result.success) {
        await showReservationNotice(context, title: 'Could not open notification',
          message: result.message ?? 'Please try again.');
        return;
      }
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => destination));
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: library,
          builder: (context, _) {
            final notifications = library.notifications.where((n) => !n.isRead).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 21,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (library.unreadNotificationCount > 0)
                        TextButton(
                          onPressed: () => _run(context, library.markAllNotificationsRead),
                          child: const Text('Mark all read'),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _buildList(context, notifications)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<StudentNotification> notifications) {
    if (library.isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            library.loadError ?? 'You have no new notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final n = notifications[index];
        final (icon, color) = _style(context, n.type);
        return InkWell(
          onTap: () => _openNotification(n),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color.alphaBlend(color.withValues(alpha: .08), Theme.of(context).colorScheme.surface), Theme.of(context).colorScheme.surface]),
              color: n.isRead
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .35 : .22)),
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
                      Text(
                        n.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ago(n.createdAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss notification',
                  key: ValueKey('dismiss-${n.id}'),
                  onPressed: () => _run(context, () => library.dismissNotification(n.id)),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
                if (!n.isRead)
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
        );
      },
    );
  }

  (IconData, Color) _style(
    BuildContext context,
    StudentNotificationType type,
  ) {
    final colors = Theme.of(context).colorScheme;
    return switch (type) {
      StudentNotificationType.bookAvailable => (Icons.notifications_active_rounded, colors.primary),
      StudentNotificationType.reservationApproved => (Icons.check_circle_rounded, const Color(0xFF22A06B)),
      StudentNotificationType.reservationRejected => (Icons.cancel_rounded, const Color(0xFFDC4C4C)),
      StudentNotificationType.reservationCancelled => (Icons.event_busy_rounded, colors.onSurfaceVariant),
      StudentNotificationType.reservationRequested => (Icons.hourglass_top_rounded, const Color(0xFFE78A00)),
      StudentNotificationType.bookCollected => (Icons.menu_book_rounded, colors.primary),
      StudentNotificationType.bookReturned => (Icons.assignment_return_rounded, const Color(0xFF22A06B)),
      StudentNotificationType.loanRenewed => (Icons.update_rounded, colors.primary),
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
