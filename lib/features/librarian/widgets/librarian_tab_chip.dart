import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Rounded tab chip from the Notifications design: solid blue when
/// selected, white with an outline otherwise. Used for All / Unread /
/// Active / Overdue style tabs.
class LibrarianTabChip extends StatelessWidget {
  const LibrarianTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? LibrarianColors.primary : LibrarianColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? LibrarianColors.primary : LibrarianColors.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : LibrarianColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of tab chips that scrolls sideways on narrow screens.
class LibrarianTabChipBar extends StatelessWidget {
  const LibrarianTabChipBar({super.key, required this.chips});

  final List<LibrarianTabChip> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: LibrarianSpacing.sm),
            chips[i],
          ],
        ],
      ),
    );
  }
}
