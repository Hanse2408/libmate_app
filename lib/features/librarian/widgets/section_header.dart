import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Section title with an optional link on the right, e.g. "See all".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: LibrarianSpacing.lg,
        bottom: LibrarianSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: LibrarianColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: LibrarianColors.link,
                textStyle: Theme.of(context).textTheme.bodyLarge,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
