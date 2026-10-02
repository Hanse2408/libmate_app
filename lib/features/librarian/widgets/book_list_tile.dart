import 'package:flutter/material.dart';

import '../models/book_record.dart';
import '../theme/librarian_theme.dart';
import 'book_cover.dart';
import 'librarian_accent_card.dart';
import 'status_chip.dart';

/// One book card in Book Management: cover, title, author, stock status
/// and an Edit link. The outline colour follows the stock status.
class BookListTile extends StatelessWidget {
  const BookListTile({super.key, required this.book, required this.onEdit});

  final BookRecord book;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return LibrarianAccentCard(
      accentColor: StatusChip.bookStockColor(book.stock),
      onTap: onEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(title: book.title),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LibrarianColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: LibrarianSpacing.sm),
                    StatusChip.bookStock(book.stock),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LibrarianColors.secondaryText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: LibrarianSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${book.category} · ${book.availableCopies} of ${book.totalCopies} available',
                        maxLines: 2,
                        style: const TextStyle(
                          color: LibrarianColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        foregroundColor: LibrarianColors.secondaryText,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
