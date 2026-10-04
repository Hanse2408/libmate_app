import 'package:flutter/material.dart';

/// Shows an image from an asset path bundled with the app (e.g.
/// "assets/images/books/book1.jpg") or a download URL.
///
/// While it loads, and if it is missing or fails to load, [fallback] is shown
/// instead (e.g. the generated book cover), so screens never show a broken
/// image.
class StoredImage extends StatelessWidget {
  const StoredImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return fallback;
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        // e.g. the file was renamed or is not in this copy of the project yet.
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      // On the web, fall back to an <img> element if the Storage bucket has
      // no CORS configuration, so the image still shows.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            fallback,
            const Positioned.fill(
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
