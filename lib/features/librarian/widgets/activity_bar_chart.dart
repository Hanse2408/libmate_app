import 'package:flutter/material.dart';

import '../providers/librarian_report.dart';
import '../theme/librarian_theme.dart';

/// Small vertical bar chart (one bar per day or week) made from plain
/// containers, so no chart package is needed.
class ActivityBarChart extends StatelessWidget {
  const ActivityBarChart({super.key, required this.entries, this.height = 140});

  final List<ReportEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxCount = entries.isEmpty
        ? 0
        : entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.count}',
                      style: const TextStyle(
                        color: LibrarianColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: maxCount == 0 ? 0.02 : (entry.count / maxCount).clamp(0.02, 1.0),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 36),
                          decoration: BoxDecoration(
                            color: LibrarianColors.primary.withValues(
                              alpha: entry.count == 0 ? 0.2 : 0.85,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        entry.label,
                        style: const TextStyle(
                          color: LibrarianColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
