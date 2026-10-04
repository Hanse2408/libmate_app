import 'package:flutter/material.dart';

import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  State<ManagerNotificationsScreen> createState() =>
      _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState
    extends State<ManagerNotificationsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final notices = _tab == 0
        ? managerNotices
        : managerNotices.take(3).toList();
    return ManagerScaffold(
      title: 'Notifications',
      currentIndex: 3,
      fourthItem: ManagerFourthNav.notifications,
      body: ManagerPagePadding(
        child: Column(
          children: [
            FilterChipsRow(
              labels: const ['All', 'Unread'],
              selectedIndex: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 11),
            Expanded(
              child: ListView(
                children: [
                  for (final notice in notices)
                    NotificationTile.fromNotice(context, notice),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
