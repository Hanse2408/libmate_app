import 'package:flutter/material.dart';

import '../../../core/widgets/stored_image.dart';
import '../theme/librarian_theme.dart';

/// Book cover: the bundled cover image when there is one ([coverAsset]),
/// otherwise a generated cover (coloured block + title). The colour is
/// picked from the title, so the same book always gets the same cover.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.width = 64,
    this.height = 88,
    this.coverAsset,
  });

  /// Cover image path in the project, e.g. "assets/images/books/book1.jpg".
  final String? coverAsset;

  final String title;
  final double width;
  final double height;

  // Covers are artwork: the same colours in light and dark mode.
  static final List<Color> _palette = [
    LibrarianPalette.light.navy,
    LibrarianPalette.light.primary,
    LibrarianPalette.light.text,
    Color.lerp(LibrarianPalette.light.available, LibrarianPalette.light.text, 0.35)!,
    Color.lerp(LibrarianPalette.light.unavailable, LibrarianPalette.light.text, 0.3)!,
  ];

  @override
  Widget build(BuildContext context) {
    final generated = _generated();
    if (coverAsset == null || coverAsset!.isEmpty) return generated;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: StoredImage(url: coverAsset, fallback: generated),
      ),
    );
  }

  Widget _generated() {
    // Sum of character codes: a simple hash that is the same on every run.
    final hash = title.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final color = _palette[hash % _palette.length];
    final fontSize = (width / 7).clamp(7.0, 14.0);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.08),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book, color: Colors.white70, size: width * 0.25),
          const Spacer(),
          Text(
            title.isEmpty ? 'Book title' : title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
