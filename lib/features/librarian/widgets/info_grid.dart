import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

class InfoItem {
  const InfoItem(this.label, this.value, {this.valueColor, this.wide = false});

  final String label;
  final String value;
  final Color? valueColor;

  /// Takes the whole row, for long values such as e-mail addresses.
  final bool wide;
}

/// Label/value pairs in two columns (one column on very narrow screens),
/// e.g. "NAME / Nimali Perera" and "STUDENT ID / IT23865894".
class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key, required this.items});

  final List<InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = LibrarianSpacing.md;
        final columns = constraints.maxWidth < 260 ? 1 : 2;
        final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: LibrarianSpacing.md + 4,
          children: [
            for (final item in items)
              SizedBox(
                width: item.wide ? constraints.maxWidth : itemWidth,
                child: _InfoCell(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.item});

  final InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label.toUpperCase(),
          style: TextStyle(
            color: LibrarianColors.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: TextStyle(
            // Status colours are darkened slightly so light ones stay readable.
            color: item.valueColor == null
                ? LibrarianColors.text
                : Color.lerp(item.valueColor, LibrarianColors.text, 0.25),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
