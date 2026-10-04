import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        body: ManagerPagePadding(
          child: ListView(
            children: [
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                      Text(
                        'Library Manager',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Text(
                    'LM',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _DashboardStatGrid(),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Recent Notifications',
              actionText: 'View all',
              onAction: () => context.go(AppRoutes.managerNotifications),
            ),
            const SizedBox(height: 5),
            for (final notice in managerNotices.take(3))
              _dashboardNotification(context, notice),
            const SizedBox(height: 12),
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.event_note_outlined,
                    label: 'Reservations',
                    onTap: () => context.go(AppRoutes.managerReservations),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.event_seat_outlined,
                    label: 'Reading Room',
                    onTap: () => context.go(AppRoutes.managerReadingRoom),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    onTap: () => context.go(AppRoutes.managerReports),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
        bottomNavigationBar: const ManagerBottomNav(currentIndex: 0),
      ),
    );
  }
}

Widget _dashboardNotification(BuildContext context, ManagerNotice notice) {
  final isOccupancyAlert = notice.title == 'Reading room occupancy high';
  final isOverdueAlert = notice.title == '12 books are overdue';
  if (!isOccupancyAlert && !isOverdueAlert) {
    return NotificationTile.fromNotice(context, notice);
  }
  return NotificationTile(
    icon: isOccupancyAlert
        ? Icons.notifications_active_outlined
        : Icons.menu_book_outlined,
    color: isOccupancyAlert ? AppColors.gold : AppColors.error,
    title: notice.title,
    subtitle: notice.subtitle,
    time: notice.time,
  );
}

class _DashboardStatGrid extends StatelessWidget {
  const _DashboardStatGrid();

  @override
  Widget build(BuildContext context) => GridView(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
    ),
    children: [
      StatCard(
        icon: Icons.event_note_outlined,
        title: 'Total Reservations',
        value: '128',
        trend: '+12%',
      ),
      StatCard(
        icon: Icons.event_seat_outlined,
        title: 'Active Seats',
        value: '84 / 120',
        trend: '70%',
        trendColor: AppColors.primary,
      ),
      StatCard(
        icon: Icons.menu_book_outlined,
        title: 'Overdue Books',
        value: '19',
        trend: '+3',
        trendColor: AppColors.error,
      ),
      StatCard(
        icon: Icons.warning_amber_rounded,
        title: 'Active Conflicts',
        value: '3',
        trend: '-1',
        trendColor: AppColors.gold,
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );
}
