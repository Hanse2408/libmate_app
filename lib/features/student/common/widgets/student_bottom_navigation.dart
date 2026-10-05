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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
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
                icon: Icons.home_outlined,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: onHome,
              ),
              _buildNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                selected: selectedIndex == 1,
                onTap: onSearch,
              ),
              _buildNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Reservations',
                selected: selectedIndex == 2,
                onTap: onReservations,
              ),
              _buildNavItem(
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
                  ? const Color(0xFF1267D9)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1267D9)
                    : const Color(0xFF94A3B8),
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