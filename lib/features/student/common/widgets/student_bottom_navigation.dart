import 'package:flutter/material.dart';

class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onHome,
    required this.onSearch,
    required this.onReservations,
    required this.onProfile,
  });

  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onSearch;
  final VoidCallback onReservations;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: onHome,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.search_rounded,
                label: 'Search',
                selected: selectedIndex == 1,
                onTap: onSearch,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.calendar_month_rounded,
                label: 'Reservations',
                selected: selectedIndex == 2,
                onTap: onReservations,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: selectedIndex == 3,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}