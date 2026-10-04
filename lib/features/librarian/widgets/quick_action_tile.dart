import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Dashboard shortcut button with an icon and label, e.g. "Add New Book".
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LibrarianSpacing.md,
            vertical: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: LibrarianColors.link),
              const SizedBox(width: LibrarianSpacing.sm + 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: LibrarianColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
