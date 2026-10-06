import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Bell icon with a red badge showing the number of unread notifications.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        backgroundColor: LibrarianColors.unavailable,
        label: Text('$unreadCount'),
        child: Icon(
          Icons.notifications_none_outlined,
          size: 28,
          color: LibrarianColors.text,
        ),
      ),
    );
  }
}
