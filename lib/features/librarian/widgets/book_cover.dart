import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Generated book cover (coloured block + title) used until real cover
/// images can be uploaded. The colour is picked from the title, so the same
/// book always gets the same cover.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.width = 64,
    this.height = 88,
  });

  final String title;
  final double width;
  final double height;

  static final List<Color> _palette = [
    LibrarianColors.navy,
    LibrarianColors.primary,
    LibrarianColors.text,
    Color.lerp(LibrarianColors.available, LibrarianColors.text, 0.35)!,
    Color.lerp(LibrarianColors.unavailable, LibrarianColors.text, 0.3)!,
  ];

  @override
  Widget build(BuildContext context) {
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
