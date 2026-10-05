import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Centres page content and caps its width, so screens look right on phones
/// and do not stretch edge-to-edge on wide Chrome windows.
class LibrarianPageBody extends StatelessWidget {
  const LibrarianPageBody({
    super.key,
    required this.child,
    this.maxWidth = LibrarianSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
