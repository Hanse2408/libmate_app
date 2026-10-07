import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../data/manager_mock_data.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: ManagerScaffold(
        title: 'Manager Dashboard',
        currentIndex: 0,
        actions: [
          IconButton(
            tooltip: 'My Profile',
            onPressed: () => context.go(AppRoutes.managerProfile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go(AppRoutes.managerNotifications),
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 5),
        ],
        body: ManagerPagePadding(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              const _DashboardHero(),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'People at a glance',
                actionText: 'Manage',
                onAction: () => context.go(AppRoutes.managerUsers),
              ),
              const SizedBox(height: 10),
              const _RoleSummaryGrid(),
              const SizedBox(height: 19),
              const _SystemSnapshotCard(),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Quick access',
                actionText: 'Policies',
                onAction: () => context.go(AppRoutes.managerPolicies),
              ),
              const SizedBox(height: 10),
              _QuickActionsGrid(
                actions: [
                  _DashboardAction(
                    title: 'Manage Users',
                    subtitle: 'Accounts & roles',
                    icon: Icons.groups_2_outlined,
                    tint: AppColors.primary,
                    onTap: () => context.go(AppRoutes.managerUsers),
                  ),
                  _DashboardAction(
                    title: 'Reservations',
                    subtitle: 'System overview',
                    icon: Icons.event_note_outlined,
                    tint: const Color(0xFF7C5CE7),
                    onTap: () => context.go(AppRoutes.managerReservations),
                  ),
                  _DashboardAction(
                    title: 'Reports',
                    subtitle: 'Trends & insights',
                    icon: Icons.insights_outlined,
                    tint: AppColors.success,
                    onTap: () => context.go(AppRoutes.managerReports),
                  ),
                  _DashboardAction(
                    title: 'Policy & Limits',
                    subtitle: 'Library settings',
                    icon: Icons.tune_rounded,
                    tint: const Color(0xFFE59A28),
                    onTap: () => context.go(AppRoutes.managerPolicies),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Recent activity',
                actionText: 'See all',
                onAction: () => context.go(AppRoutes.managerNotifications),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final notices = ManagerScope.of(context).repository.notices.take(4).toList();
                  return _RecentActivityCard(notices: notices);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -20,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 112,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _dateLabel(now),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF8DE1B4), size: 7),
                        SizedBox(width: 5),
                        Text(
                          'Overview',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '$greeting,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Library Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Here’s what’s happening in your library today.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _RoleSummaryGrid extends StatelessWidget {
  const _RoleSummaryGrid();

  @override
  Widget build(BuildContext context) {
    final users = ManagerScope.of(context).repository.users;
    final students = users.where((user) => user.role == 'Student').length;
    final librarians = users.where((user) => user.role == 'Librarian').length;
    final managers = users.where((user) => user.role == 'Manager').length;

    return Row(
      children: [
        Expanded(
          child: _RoleSummaryCard(
            title: 'Total users',
            value: '${users.length}',
            icon: Icons.groups_2_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RoleSummaryCard(
            title: 'Students',
            value: '$students',
            icon: Icons.school_outlined,
            color: const Color(0xFF7C5CE7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RoleSummaryCard(
            title: 'Librarians',
            value: '$librarians',
            icon: Icons.badge_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RoleSummaryCard(
            title: 'Managers',
            value: '$managers',
            icon: Icons.shield_outlined,
            color: const Color(0xFFE59A28),
          ),
        ),
      ],
    );
  }
}

class _RoleSummaryCard extends StatelessWidget {
  const _RoleSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 10, 7, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SystemSnapshotCard extends StatelessWidget {
  const _SystemSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading room',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Current occupancy',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                '70%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.7,
              minHeight: 8,
              backgroundColor: AppColors.lightBlue,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '84 occupied of 120 seats',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ),
              _SnapshotMetric(
                icon: Icons.menu_book_outlined,
                value: '12 overdue',
                color: AppColors.gold,
              ),
              const SizedBox(width: 11),
              _SnapshotMetric(
                icon: Icons.error_outline,
                value: '1 issue',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 9),
          Row(
            children: [
              for (var column = 0; column < 2; column++) ...[
                if (column > 0) const SizedBox(width: 9),
                Expanded(child: _ActionCard(action: actions[row * 2 + column])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.tint, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.notices});

  final List<ManagerNotice> notices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < notices.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _ActivityRow(notice: notices[index]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.notice});

  final ManagerNotice notice;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notice.kind) {
      'success' => (Icons.check_rounded, AppColors.success),
      'warning' => (Icons.menu_book_outlined, AppColors.gold),
      'info' => (Icons.person_add_alt_1_outlined, AppColors.primary),
      _ => (Icons.warning_amber_rounded, AppColors.error),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notice.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            notice.time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
