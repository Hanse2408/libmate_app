import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Tinted count box, e.g. "18 Available" on Seat Management or
/// "4 Overdue" on Borrowing Management.
class CountTile extends StatelessWidget {
  const CountTile({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Color.lerp(color, LibrarianColors.text, 0.25)!;
    final style = TextStyle(
      color: textColor,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );

    return Material(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LibrarianSpacing.md,
            vertical: LibrarianSpacing.sm + 4,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: style),
                Text(label, style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
