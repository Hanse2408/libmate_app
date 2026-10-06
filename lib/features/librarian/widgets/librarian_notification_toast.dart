import 'package:flutter/material.dart';

import '../models/librarian_notification.dart';
import '../providers/librarian_toast_controller.dart';
import '../theme/librarian_theme.dart';
import 'notification_tile.dart';

/// In-app notification banner (messaging-app style) shown at the top of
/// every Librarian page when a new notification arrives (see
/// LibrarianToastController).
///
/// - Slides down from the top, below the status bar, and slides back up
///   after about 2 seconds.
/// - Swipe it up (or tap ×) to dismiss it at once; while a finger is on it,
///   it stays.
/// - Only the banner takes touches; the page underneath stays usable.
/// - Uses the Librarian palette, so it follows light / dark mode.
class LibrarianNotificationToast extends StatelessWidget {
  const LibrarianNotificationToast({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final LibrarianToastController controller;
  final ValueChanged<LibrarianNotification> onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final notification = controller.current;
        final visible = controller.isVisible;
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, -1.6),
                // Slight overshoot coming in, quick ease going out.
                duration: visible ? const Duration(milliseconds: 380) : controller.animationDuration,
                curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: controller.animationDuration,
                  child: notification == null
                      ? const SizedBox.shrink()
                      : Dismissible(
                          // One key per notification: a swiped banner never returns.
                          key: ValueKey('toast-${notification.id}'),
                          direction: DismissDirection.up,
                          onDismissed: (_) => controller.removeNow(),
                          // While a finger is on it, it stays; letting go
                          // continues the timer.
                          child: Listener(
                            onPointerDown: (_) => controller.hold(),
                            onPointerUp: (_) => controller.resume(),
                            onPointerCancel: (_) => controller.resume(),
                            child: _Banner(
                              notification: notification,
                              onTap: () => onTap(notification),
                              onClose: controller.dismiss,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.notification, required this.onTap, required this.onClose});

  final LibrarianNotification notification;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = NotificationTile.styleFor(notification.type);
    final radius = BorderRadius.circular(20);
    final muted = LibrarianColors.secondaryText;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Semantics(
            liveRegion: true,
            button: true,
            label: 'New notification: ${notification.title}. ${notification.message}. '
                'Swipe up to dismiss.',
            child: Material(
              key: const ValueKey('librarian-toast'),
              color: LibrarianColors.card,
              elevation: 10,
              shadowColor: LibrarianColors.isDark
                  ? const Color(0xCC000000)
                  : LibrarianColors.text.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: LibrarianColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Notification type icon (same as the Notifications screen).
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Color.lerp(color, LibrarianColors.text, 0.15), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // App line, as on phone notifications.
                                Row(
                                  children: [
                                    Icon(Icons.menu_book_rounded, size: 13, color: LibrarianColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LibMate · now',
                                      style: TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  notification.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: LibrarianColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  notification.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: muted, fontSize: 13.5, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dismiss notification',
                            onPressed: onClose,
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            icon: Icon(Icons.close_rounded, color: muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Grab handle: hints that the banner can be swiped up.
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: LibrarianColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
