import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';

/// Bottom navigation for the four main Librarian tabs.
class LibrarianBottomNav extends StatelessWidget {
  const LibrarianBottomNav({super.key, required this.currentPath});

  final String currentPath;

  static const List<_NavItem> _items = [
    _NavItem('Dashboard', Icons.grid_view_outlined, Icons.grid_view, LibrarianRoutes.dashboard),
    _NavItem('Reservations', Icons.event_available_outlined, Icons.event_available, LibrarianRoutes.reservations),
    _NavItem('Books', Icons.book_outlined, Icons.book, LibrarianRoutes.books),
    _NavItem('Seats', Icons.chair_outlined, Icons.chair, LibrarianRoutes.seats),
  ];

  /// The tab that owns [path], e.g. /librarian/books/add -> Books.
  /// Pages outside the three sections (like Notifications) belong to the
  /// Dashboard, where they are opened from.
  static int selectedIndexFor(String path) {
    for (var i = 1; i < _items.length; i++) {
      final tab = _items[i].path;
      if (path == tab || path.startsWith('$tab/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndexFor(currentPath),
      onDestinationSelected: (index) => context.go(_items[index].path),
      destinations: [
        for (final item in _items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon, this.path);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
