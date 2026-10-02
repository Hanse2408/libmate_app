import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';
import 'librarian_accent_card.dart';

/// Dashboard alert, e.g. "7 reservation requests are waiting for approval."
class AttentionCard extends StatelessWidget {
  const AttentionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LibrarianAccentCard(
      accentColor: color,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: Color.lerp(color, LibrarianColors.text, 0.3)),
          ),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: LibrarianColors.text,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: LibrarianSpacing.xs),
                Row(
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: LibrarianColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: LibrarianSpacing.xs),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: LibrarianColors.secondaryText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
