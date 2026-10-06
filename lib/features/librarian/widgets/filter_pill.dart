import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Outlined blue pill such as "Status: All". Tapping it opens a menu of
/// [options]; the chosen option's index is passed to [onSelected].
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedIndex != 0;

    return PopupMenuButton<int>(
      tooltip: 'Filter by $label',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (var i = 0; i < options.length; i++)
          CheckedPopupMenuItem<int>(
            value: i,
            checked: i == selectedIndex,
            child: Text(options[i]),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
        decoration: BoxDecoration(
          color: isFiltered ? LibrarianColors.lightBlue : LibrarianColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LibrarianColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '$label: ${options[selectedIndex]}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: LibrarianColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: LibrarianColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
