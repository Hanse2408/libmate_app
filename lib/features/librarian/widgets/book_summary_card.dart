import 'package:flutter/material.dart';

import '../models/book_record.dart';
import '../theme/librarian_theme.dart';
import 'book_cover.dart';
import 'info_section_card.dart';

/// Book cover, title, author, category pill and ISBN, as on the Book
/// Reservation Details design. Also used on Borrowing Details.
class BookSummaryCard extends StatelessWidget {
  const BookSummaryCard({
    super.key,
    required this.book,
    required this.fallbackTitle,
    this.fallbackIsbn,
    this.coverAsset,
  });

  /// Null if the book was removed from the catalogue.
  final BookRecord? book;
  final String fallbackTitle;
  final String? fallbackIsbn;

  /// The book's cover (Cloudinary URL or bundled asset). Without one, or if
  /// it cannot be loaded, the generated cover is shown.
  final String? coverAsset;

  @override
  Widget build(BuildContext context) {
    final title = book?.title ?? fallbackTitle;
    final isbn = book?.isbn ?? fallbackIsbn;

    return InfoSectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              title: title,
              width: 92,
              height: 124,
              coverAsset: coverAsset,
            ),
            const SizedBox(width: LibrarianSpacing.md + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: LibrarianColors.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (book != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      book!.author,
                      style: TextStyle(
                        color: LibrarianColors.secondaryText,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: LibrarianSpacing.sm + 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: LibrarianColors.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        book!.category,
                        style: TextStyle(
                          color: LibrarianColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'This book is no longer in the catalogue.',
                      style: TextStyle(color: LibrarianColors.unavailable),
                    ),
                  if (isbn != null) ...[
                    const SizedBox(height: LibrarianSpacing.sm + 4),
                    Text(
                      'ISBN: $isbn',
                      style: TextStyle(color: LibrarianColors.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
