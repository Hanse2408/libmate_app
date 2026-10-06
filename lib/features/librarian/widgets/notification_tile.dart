import 'package:flutter/material.dart';

import '../models/librarian_notification.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import 'librarian_accent_card.dart';

/// One notification card. The icon and outline colour depend on the type;
/// unread notifications show a blue dot (see Figma).
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final LibrarianNotification notification;
  final VoidCallback? onTap;

  static (IconData, Color) styleFor(LibrarianNotificationType type) {
    return switch (type) {
      LibrarianNotificationType.newRequest => (Icons.schedule, LibrarianColors.gold),
      LibrarianNotificationType.awaitingApproval => (Icons.warning_amber_rounded, LibrarianColors.unavailable),
      LibrarianNotificationType.approved => (Icons.check, LibrarianColors.available),
      LibrarianNotificationType.rejected => (Icons.block, LibrarianColors.unavailable),
      LibrarianNotificationType.cancelled => (Icons.event_busy, LibrarianColors.secondaryText),
      LibrarianNotificationType.bookReturned => (Icons.web_asset, LibrarianColors.primary),
      LibrarianNotificationType.bookCollected => (Icons.outbox_outlined, LibrarianColors.primary),
      LibrarianNotificationType.loanRenewed => (Icons.update, LibrarianColors.primary),
      LibrarianNotificationType.dueReminder => (Icons.notifications_none, LibrarianColors.gold),
      LibrarianNotificationType.bookAdded => (Icons.add, LibrarianColors.primary),
      LibrarianNotificationType.seatUpdate => (Icons.chair_outlined, LibrarianColors.secondaryText),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = styleFor(notification.type);

    return LibrarianAccentCard(
      accentColor: color,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: Color.lerp(color, LibrarianColors.text, 0.15), size: 28),
          ),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    color: LibrarianColors.text,
                    fontSize: 17,
                    fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: LibrarianColors.secondaryText,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LibrarianFormatters.timeAgo(notification.createdAt),
                  style: TextStyle(
                    color: LibrarianColors.secondaryText.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              key: const Key('unread-dot'),
              margin: const EdgeInsets.only(left: LibrarianSpacing.sm),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: LibrarianColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
