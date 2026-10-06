import 'package:flutter/material.dart';

import '../providers/librarian_report.dart';
import '../theme/librarian_theme.dart';

/// Horizontal bars (label, bar, count), e.g. "Most borrowed books".
/// Built from plain widgets, so no chart package is needed.
class ReportBarList extends StatelessWidget {
  const ReportBarList({
    super.key,
    required this.entries,
    this._color,
    this.colors,
    this.emptyText = 'No data for this period.',
  });

  final List<ReportEntry> entries;

  /// Bar colour; defaults to the palette's primary blue (light / dark).
  Color get color => _color ?? LibrarianColors.primary;
  final Color? _color;

  /// Optional colour per entry (same order as [entries]).
  final List<Color>? colors;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty || entries.every((e) => e.count == 0)) {
      return Text(emptyText, style: TextStyle(color: LibrarianColors.secondaryText));
    }
    final maxCount = entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _BarRow(
              entry: entries[i],
              fraction: maxCount == 0 ? 0 : entries[i].count / maxCount,
              color: colors?[i] ?? color,
            ),
          ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.entry, required this.fraction, required this.color});

  final ReportEntry entry;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: LibrarianColors.text, fontSize: 15),
              ),
            ),
            const SizedBox(width: LibrarianSpacing.sm),
            Text(
              '${entry.count}',
              style: TextStyle(
                color: LibrarianColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 10, color: LibrarianColors.border),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(height: 10, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
