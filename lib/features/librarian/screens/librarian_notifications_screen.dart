import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/librarian_notification.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_search_field.dart';
import '../widgets/librarian_tab_chip.dart';
import '../widgets/notification_tile.dart';

enum _NotificationFilter { all, unread, reservations, books }

/// Notifications (Figma): filter chips, search, and Today / Earlier groups.
/// Tapping a notification marks it read and opens the related reservation.
class LibrarianNotificationsScreen extends StatefulWidget {
  const LibrarianNotificationsScreen({super.key});

  @override
  State<LibrarianNotificationsScreen> createState() =>
      _LibrarianNotificationsScreenState();
}

class _LibrarianNotificationsScreenState
    extends State<LibrarianNotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;
  String _query = '';

  bool _matches(LibrarianNotification n) {
    final filterOk = switch (_filter) {
      _NotificationFilter.all => true,
      _NotificationFilter.unread => !n.isRead,
      _NotificationFilter.reservations => n.type.category == NotificationCategory.reservations,
      _NotificationFilter.books => n.type.category == NotificationCategory.books,
    };
    final text = _query.trim().toLowerCase();
    return filterOk &&
        (text.isEmpty ||
            n.title.toLowerCase().contains(text) ||
            n.message.toLowerCase().contains(text));
  }

  Future<void> _open(LibrarianNotification notification) async {
    await LibrarianScope.read(context).repository.markNotificationRead(notification.id);
    if (!mounted || notification.reservationId == null) return;
    context.go(
      Uri(
        path: LibrarianRoutes.reservationDetails(notification.reservationId!),
        queryParameters: {'from': LibrarianRoutes.notifications},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final unread = repository.unreadNotificationCount;
        final results = repository.notifications.where(_matches).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final now = DateTime.now();
        bool isToday(DateTime d) =>
            d.year == now.year && d.month == now.month && d.day == now.day;
        final today = results.where((n) => isToday(n.createdAt)).toList();
        final earlier = results.where((n) => !isToday(n.createdAt)).toList();

        return LibrarianPage(
          maxWidth: 760,
          children: [
            LibrarianPageHeader(
              title: 'Notifications',
              trailing: unread == 0
                  ? null
                  : TextButton(
                      onPressed: repository.markAllNotificationsRead,
                      child: const Text('Mark all as read'),
                    ),
            ),
            Wrap(
              spacing: LibrarianSpacing.sm,
              runSpacing: LibrarianSpacing.sm,
              children: [
                for (final filter in _NotificationFilter.values)
                  LibrarianTabChip(
                    label: switch (filter) {
                      _NotificationFilter.all => 'All',
                      _NotificationFilter.unread => 'Unread ($unread)',
                      _NotificationFilter.reservations => 'Reservations',
                      _NotificationFilter.books => 'Books',
                    },
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            LibrarianSearchField(
              hint: 'Search notifications',
              onChanged: (value) => setState(() => _query = value),
            ),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: LibrarianSpacing.lg),
                child: LibrarianEmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: _filter == _NotificationFilter.unread && _query.isEmpty
                      ? "You're all caught up"
                      : 'No notifications found',
                ),
              ),
            ..._section('Today', today),
            ..._section('Earlier', earlier),
          ],
        );
      },
    );
  }

  List<Widget> _section(String title, List<LibrarianNotification> items) {
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(
          top: LibrarianSpacing.lg,
          bottom: LibrarianSpacing.md,
        ),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: LibrarianColors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      for (final notification in items)
        Padding(
          padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
          child: NotificationTile(
            notification: notification,
            onTap: () => _open(notification),
          ),
        ),
    ];
  }
}
