import 'package:flutter/material.dart';

import '../../../models/ebook.dart';
import '../theme/librarian_theme.dart';
import 'book_cover.dart';

/// One e-book card (E-book Management design): cover, title, author,
/// category, "Published · PDF" status and the Edit / PDF / Delete actions.
class EbookTile extends StatelessWidget {
  const EbookTile({
    super.key,
    required this.ebook,
    required this.onEdit,
    required this.onPdf,
    required this.onDelete,
  });

  final EbookRecord ebook;
  final VoidCallback onEdit;

  /// PDF Quick Action (open / replace / upload the PDF).
  final VoidCallback onPdf;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = ebook.isPublished ? LibrarianColors.available : LibrarianColors.gold;
    final status = '${ebook.status.label} · ${ebook.hasPdf ? 'PDF' : 'No PDF'}';

    return Container(
      margin: const EdgeInsets.only(bottom: LibrarianSpacing.md),
      padding: const EdgeInsets.all(LibrarianSpacing.md + 2),
      decoration: BoxDecoration(
        color: LibrarianColors.card,
        borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
        border: Border.all(color: LibrarianColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(title: ebook.title, coverAsset: ebook.coverAsset, width: 68, height: 92),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ebook.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: LibrarianColors.text, fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  ebook.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 16),
                ),
                Text(
                  ebook.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Action(label: 'Edit', color: LibrarianColors.primary, onTap: onEdit),
              _Action(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                color: LibrarianColors.primary,
                onTap: onPdf,
                tooltip: 'PDF quick actions',
              ),
              _Action(label: 'Delete', color: LibrarianColors.unavailable, onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.tooltip,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
    final button = icon == null
        ? TextButton(onPressed: onTap, style: style, child: Text(label))
        : TextButton.icon(onPressed: onTap, style: style, icon: Icon(icon, size: 18), label: Text(label));
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
