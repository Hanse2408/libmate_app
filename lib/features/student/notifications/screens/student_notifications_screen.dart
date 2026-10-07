import 'package:flutter/material.dart';

import '../../../../models/action_result.dart';
import '../../../../models/notification.dart';
import '../../common/data/student_library_repository.dart';

/// The signed-in student's notifications (live from Firestore): reservation
/// requests, approvals, rejections, cancellations and loan updates.
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  /// Runs a Firestore action and shows its error, if it fails.
  Future<void> _run(BuildContext context, Future<ActionResult> Function() action) async {
    final result = await action();
    if (!context.mounted || result.success) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: library,
          builder: (context, _) {
            final notifications = library.notifications;
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
                            fontWeight: FontWeight.w700,
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
            library.loadError ?? 'You have no notifications yet.',
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
          onTap: n.isRead ? null : () => _run(context, () => library.markNotificationRead(n.id)),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.isRead
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E3F2)),
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
