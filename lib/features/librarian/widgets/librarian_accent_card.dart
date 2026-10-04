import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// White card with a coloured outline and a thicker coloured bar on the left,
/// used for attention alerts and reservation rows (see Figma).
class LibrarianAccentCard extends StatelessWidget {
  const LibrarianAccentCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.onTap,
  });

  final Color accentColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
        side: BorderSide(color: accentColor.withValues(alpha: 0.7), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        // IntrinsicHeight lets the left bar stretch to the content's height.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(LibrarianSpacing.md),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
