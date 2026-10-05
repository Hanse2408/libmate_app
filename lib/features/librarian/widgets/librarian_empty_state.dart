import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Centred icon + message, used for empty lists and "no search results".
class LibrarianEmptyState extends StatelessWidget {
  const LibrarianEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LibrarianSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: LibrarianColors.lightBlue,
              child: Icon(icon, size: 32, color: LibrarianColors.primary),
            ),
            const SizedBox(height: LibrarianSpacing.md),
            Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: LibrarianSpacing.xs),
              Text(message!, style: textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
