import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';
import 'librarian_page_body.dart';

/// Standard scrolling Librarian page: safe area, centred width-limited
/// content and consistent padding. Screens pass their header and sections.
class LibrarianPage extends StatelessWidget {
  const LibrarianPage({
    super.key,
    required this.children,
    this.maxWidth = LibrarianSpacing.maxContentWidth,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LibrarianPageBody(
          maxWidth: maxWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              LibrarianSpacing.md + 4,
              LibrarianSpacing.md,
              LibrarianSpacing.md + 4,
              LibrarianSpacing.lg,
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
