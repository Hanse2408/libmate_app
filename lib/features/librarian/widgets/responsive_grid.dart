import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Lays children out in equal columns: as many as fit (each at least
/// [minItemWidth] wide), wrapping onto more rows on narrow phones.
/// Used for count tiles, stat cards and report sections.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 90,
  });

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = LibrarianSpacing.md;
        final columns = ((constraints.maxWidth + gap) ~/ (minItemWidth + gap))
            .clamp(1, children.length);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
