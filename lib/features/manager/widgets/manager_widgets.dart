import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../data/manager_mock_data.dart';

class ManagerScaffold extends StatelessWidget {
  const ManagerScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex,
    this.fourthItem,
    this.actions,
    this.leading,
  });

  final String title;
  final Widget body;
  final int? currentIndex;
  final ManagerFourthNav? fourthItem;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: leading,
          actions: actions,
        ),
        body: body,
        bottomNavigationBar: currentIndex == null
            ? null
            : ManagerBottomNav(
                currentIndex: currentIndex!,
                fourthItem: fourthItem ?? ManagerFourthNav.reports,
              ),
      ),
    );
  }
}

enum ManagerFourthNav { reports, users, notifications }

class ManagerBottomNav extends StatelessWidget {
  const ManagerBottomNav({
    super.key,
    required this.currentIndex,
    this.fourthItem = ManagerFourthNav.reports,
  });

  final int currentIndex;
  final ManagerFourthNav fourthItem;

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, String)>[
      ('Home', Icons.home_outlined, AppRoutes.managerDashboard),
      (
        'Reservations',
        Icons.event_note_outlined,
        AppRoutes.managerReservations,
      ),
      ('Seats', Icons.event_seat_outlined, AppRoutes.managerReadingRoom),
      switch (fourthItem) {
        ManagerFourthNav.reports => (
          'Reports',
          Icons.bar_chart_outlined,
          AppRoutes.managerReports,
        ),
        ManagerFourthNav.users => (
          'Users',
          Icons.groups_outlined,
          AppRoutes.managerUsers,
        ),
        ManagerFourthNav.notifications => (
          'Notifications',
          Icons.notifications_none,
          AppRoutes.managerNotifications,
        ),
      },
      ('Profile', Icons.person_outline, AppRoutes.managerProfile),
    ];
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => context.go(items[index].$3),
      destinations: [
        for (final item in items)
          NavigationDestination(icon: Icon(item.$2), label: item.$1),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text, required this.type});

  final String text;
  final String type;

  @override
  Widget build(BuildContext context) {
    final (color, alpha) = switch (type.toLowerCase()) {
      'confirmed' ||
      'available' ||
      'success' ||
      'completed' ||
      'student' => (AppColors.success, 0.12),
      'conflict' ||
      'unavailable' ||
      'error' ||
      'overdue' => (AppColors.error, 0.12),
      'pending' || 'warning' => (AppColors.gold, 0.2),
      'reserved' ||
      'info' ||
      'librarian' => (Theme.of(context).colorScheme.primary, 0.12),
      'manager' => (AppColors.navy, 0.12),
      _ => (AppColors.secondaryText, 0.12),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: type.toLowerCase() == 'pending' ? AppColors.navy : color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    this.trendColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                trend,
                style: TextStyle(
                  color: trendColor ?? AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(labels[i]),
              selected: i == selectedIndex,
              onSelected: (_) => onChanged(i),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: i == selectedIndex
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: primary,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, this.onChanged});

  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12),
      prefixIcon: const Icon(Icons.search, size: 18),
      isDense: true,
    ),
  );
}

class ReservationListCard extends StatelessWidget {
  const ReservationListCard({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  final ManagerReservation reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = reservation.status.name;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.id,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      reservation.book,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      reservation.student,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                    Text(
                      '${reservation.date} · ${reservation.time}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  StatusBadge(text: _capitalize(status), type: status),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  factory NotificationTile.fromNotice(
    BuildContext context,
    ManagerNotice notice,
  ) {
    final style = switch (notice.kind) {
      'success' => (Icons.check, AppColors.success),
      'warning' => (Icons.notifications_active_outlined, AppColors.gold),
      'info' => (Icons.person_outline, Theme.of(context).colorScheme.primary),
      _ => (Icons.warning_amber_rounded, AppColors.error),
    };
    return NotificationTile(
      icon: style.$1,
      color: style.$2,
      title: notice.title,
      subtitle: notice.subtitle,
      time: notice.time,
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 14),
        ),
      ),
      if (actionText != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionText!, style: const TextStyle(fontSize: 11)),
        ),
    ],
  );
}

class SeatChip extends StatelessWidget {
  const SeatChip({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
  });

  final String label;
  final ManagerSeatState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = switch (state) {
      ManagerSeatState.available => (
        AppColors.success,
        AppColors.success.withValues(alpha: 0.1),
      ),
      ManagerSeatState.reserved => (primary, primary.withValues(alpha: 0.1)),
      ManagerSeatState.conflict => (
        AppColors.error,
        AppColors.error.withValues(alpha: 0.12),
      ),
      ManagerSeatState.selected => (primary, primary),
    };
    final selected = state == ManagerSeatState.selected;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(
          color: colors.$2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: state == ManagerSeatState.conflict
                ? AppColors.error
                : selected
                ? primary
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.$1,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(onPressed: onPressed, child: Text(label)),
  );
}

class UserListTile extends StatelessWidget {
  const UserListTile({super.key, required this.user, required this.onTap});

  final ManagerUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      isThreeLine: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary
            .withValues(alpha: 0.12),
        child: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.primary,
          size: 19,
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${user.email}\n${user.id}',
        style: const TextStyle(fontSize: 10),
      ),
      trailing: SizedBox(
        width: 110,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                runSpacing: 4,
                spacing: 4,
                children: [
                  StatusBadge(text: user.role, type: user.role),
                  StatusBadge(
                    text: user.status,
                    type: user.isActive ? 'available' : 'inactive',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    ),
  );
}

class ManagerPagePadding extends StatelessWidget {
  const ManagerPagePadding({
    super.key,
    required this.child,
    this.includeTopSafeArea = false,
  });

  final Widget child;
  final bool includeTopSafeArea;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: includeTopSafeArea,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: child,
        ),
      ),
    ),
  );
}

void goToManagerHome(BuildContext context) {
  context.go(AppRoutes.managerDashboard);
}
