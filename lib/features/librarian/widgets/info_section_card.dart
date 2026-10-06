import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Rounded white card with a light blue outline and an optional bold title,
/// used for the detail, form and summary sections in the Figma.
class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    super.key,
    this.title,
    required this.children,
    this.borderColor,
  });

  final String? title;
  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: LibrarianSpacing.md + 4),
      padding: const EdgeInsets.all(LibrarianSpacing.md + 4),
      decoration: BoxDecoration(
        color: LibrarianColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? LibrarianColors.primary.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                color: LibrarianColors.text,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: LibrarianSpacing.md),
          ],
          ...children,
        ],
      ),
    );
  }
}
