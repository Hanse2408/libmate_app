import 'package:flutter/material.dart';

/// Displays the book mark from the original splash artwork, without repeating
/// its embedded wordmark beside the page's LibMate heading.
class LibMateLogo extends StatelessWidget {
  const LibMateLogo({super.key, this.size = 48});
  static const assetPath = 'assets/logos/libmate_logo.png';
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageSize = size / .42;
    return Semantics(label: 'LibMate logo', image: true,
      child: SizedBox(width: size, height: size * .77,
        child: ClipRect(child: ColorFiltered(
          // Drop the near-white canvas at render time so the same original
          // artwork sits cleanly on both light and dark backgrounds.
          colorFilter: const ColorFilter.matrix([
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            -3, -3, -3, 0, 2295,
          ]),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: -.29 * imageSize, top: -.25 * imageSize,
              width: imageSize, height: imageSize,
              child: Image.asset(assetPath, fit: BoxFit.fill,
                filterQuality: FilterQuality.high, excludeFromSemantics: true)),
          ]),
        ))),
    );
  }
}
