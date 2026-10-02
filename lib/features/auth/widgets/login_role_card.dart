import 'package:flutter/material.dart';

import '../../librarian/theme/librarian_theme.dart';

/// One "Login as" option (Student / Librarian / Administrator).
class LoginRoleCard extends StatelessWidget {
  const LoginRoleCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? LibrarianColors.lightBlue : LibrarianColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
          side: BorderSide(
            color: selected
                ? LibrarianColors.primary
                : LibrarianColors.primary.withValues(alpha: 0.35),
            width: selected ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LibrarianSpacing.xs,
              vertical: LibrarianSpacing.md,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? LibrarianColors.primary
                      : LibrarianColors.secondaryText,
                ),
                const SizedBox(height: LibrarianSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? LibrarianColors.primary : LibrarianColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
