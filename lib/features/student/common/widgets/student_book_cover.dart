import 'package:flutter/material.dart';

import '../../../../core/widgets/stored_image.dart';

/// Book cover in the Student screens' style: the cover uploaded by the
/// librarian when there is one, otherwise a navy cover with the title and
/// author (the same look the screens used before).
class StudentBookCover extends StatelessWidget {
  const StudentBookCover({
    super.key,
    required this.title,
    required this.author,
    required this.width,
    required this.height,
    this.imageUrl,
    this.color = const Color(0xFF102D4D),
    this.radius = 8,
    this.fit = BoxFit.cover,
  });

  final String title;
  final String author;
  final double width;
  final double height;
  final String? imageUrl;
  final Color color;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 7, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: StoredImage(url: imageUrl, fallback: _generated(), fit: fit),
    );
  }

  Widget _generated() {
    final titleSize = (width / 7).clamp(8.0, 24.0);
    final authorSize = (width / 20).clamp(5.0, 9.0);
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(width * 0.07),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF52718F)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.all(width * 0.14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                  ),
                ),
                SizedBox(height: height * 0.08),
                Text(
                  author.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: authorSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
