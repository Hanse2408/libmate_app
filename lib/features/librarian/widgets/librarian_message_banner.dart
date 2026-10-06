import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Inline feedback box, e.g. the green '"Madol Doova" added to the
/// catalogue.' banner on Book Management.
class LibrarianMessageBanner extends StatelessWidget {
  const LibrarianMessageBanner({
    super.key,
    required this.message,
    this.title,
    this._color,
    this.icon = Icons.check,
    this.onClose,
  });

  final String message;
  final String? title;

  /// Defaults to the palette's green, read when building so it follows
  /// light / dark mode.
  Color get color => _color ?? LibrarianColors.available;
  final Color? _color;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final textColor = Color.lerp(color, LibrarianColors.text, 0.25)!;

    return Container(
      margin: const EdgeInsets.only(bottom: LibrarianSpacing.md),
      padding: const EdgeInsets.fromLTRB(
        LibrarianSpacing.md + 4,
        LibrarianSpacing.md,
        LibrarianSpacing.sm,
        LibrarianSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 26),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(message, style: TextStyle(color: textColor, fontSize: 15)),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: Icon(Icons.close, color: textColor, size: 20),
            ),
        ],
      ),
    );
  }
}
