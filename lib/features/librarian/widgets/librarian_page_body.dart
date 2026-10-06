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
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
    // Same tree in both modes (only the backdrop changes), so switching the
    // theme keeps the page's scroll position and form fields.
    return Stack(
      children: [
        Positioned.fill(
          child: LibrarianColors.isDark ? const _DarkBackdrop() : const SizedBox.shrink(),
        ),
        content,
      ],
    );
  }
}

/// Soft navy circles behind dark-mode pages, as in the dark designs.
class _DarkBackdrop extends StatelessWidget {
  const _DarkBackdrop();

  @override
  Widget build(BuildContext context) {
    const glow = Color(0xFF13213D);
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -140,
              left: -160,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glow.withValues(alpha: 0.75),
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -180,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glow.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
