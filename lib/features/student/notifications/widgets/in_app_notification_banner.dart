import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../../models/notification.dart';
import '../../common/data/student_library_repository.dart';
import '../screens/student_notifications_screen.dart';
import 'notification_navigation.dart';

/// Shows a small top banner for each notification that arrives while the app
/// is open. Banners are queued and shown one at a time. Showing a banner does
/// not mark the notification read; only opening it does.
class InAppNotificationBanner {
  InAppNotificationBanner({
    required this.context,
    required this.library,
    this.duration = const Duration(seconds: 4),
  }) {
    _subscription = library.newNotifications.listen(_enqueue);
  }

  /// Context of a widget below the app Navigator (so the overlay is shared by
  /// every screen and navigation works from here).
  final BuildContext context;
  final StudentLibraryRepository library;
  final Duration duration;

  final Queue<StudentNotification> _queue = Queue();
  late final StreamSubscription<StudentNotification> _subscription;
  OverlayEntry? _entry;
  Timer? _timer;

  void _enqueue(StudentNotification notification) {
    _queue.add(notification);
    _showNext();
  }

  void _showNext() {
    if (_entry != null || !context.mounted) return;
    while (_queue.isNotEmpty) {
      final n = _queue.removeFirst();
      final current = library.notifications
          .where((x) => x.id == n.id)
          .firstOrNull;
      // Already read or deleted, or the list is already visible: skip.
      if (current == null || current.isRead) continue;
      if (StudentNotificationsScreen.isOpen) continue;
      _show(n);
      return;
    }
  }

  void _show(StudentNotification n) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => _BannerCard(
        notification: n,
        onClose: _dismiss,
        onView: () {
          _dismiss();
          openStudentNotification(context, library, n);
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _showNext();
  }

  void dispose() {
    _subscription.cancel();
    _timer?.cancel();
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _queue.clear();
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.notification,
    required this.onClose,
    required this.onView,
    this.local = false,
  });

  final StudentNotification notification;
  final VoidCallback onClose;
  final VoidCallback onView;
  final bool local;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = studentNotificationStyle(context, notification.type);
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Material(
        key: ValueKey(local ? 'local-top-notice' : 'in-app-banner'),
        color: colors.surface,
        elevation: 6,
        shadowColor: colors.shadow.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!local)
                        Text(
                          'View',
                          style: TextStyle(
                            color: primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A transient confirmation using the notification card, without saving history.
void showStudentTopNotice(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late final OverlayEntry entry;
  void close() {
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (_) =>
        _LocalNotice(title: title, message: message, onClose: close),
  );
  overlay.insert(entry);
}

class _LocalNotice extends StatefulWidget {
  const _LocalNotice({
    required this.title,
    required this.message,
    required this.onClose,
  });
  final String title;
  final String message;
  final VoidCallback onClose;
  @override
  State<_LocalNotice> createState() => _LocalNoticeState();
}

class _LocalNoticeState extends State<_LocalNotice> {
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), widget.onClose);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _BannerCard(
    local: true,
    notification: StudentNotification(
      id: '',
      recipientUid: '',
      type: StudentNotificationType.bookReservationUpdated,
      title: widget.title,
      message: widget.message,
      createdAt: DateTime.now(),
    ),
    onClose: widget.onClose,
    onView: widget.onClose,
  );
}
