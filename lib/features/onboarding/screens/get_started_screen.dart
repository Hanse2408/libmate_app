import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../splash/screens/splash_screen.dart';

/// Get Started (Figma): shown after the splash to signed-out users.
/// "Get Started" opens the existing Login screen. Always light themed.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  static const String illustrationAsset =
      'assets/images/common/get_started_illustration.png';

  // Colours from the Figma frame.
  static const Color _topCircle = Color(0xFFEFF4FC);
  static const Color _bottomCircle = Color(0xFFF3F5FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Soft background circles (top-left, bottom-right).
          const Positioned(
            left: -90,
            top: -70,
            child: _Circle(size: 260, color: _topCircle),
          ),
          const Positioned(
            right: -103,
            bottom: 94,
            child: _Circle(size: 230, color: _bottomCircle),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      const _LogoRow(),
                      const Expanded(child: _Hero()),
                      const Text(
                        'LEARN · RESERVE · BELONG',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your library,\nwithin reach.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 37,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                          'Discover and reserve books, and book a study space—all in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 16.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          // The existing Login screen (normal history entry,
                          // so browser Back returns here).
                          onPressed: () => context.go(AppRoutes.login),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Your library companion, every day.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// LibMate book mark + wordmark, as in the Figma header.
class _LogoRow extends StatelessWidget {
  const _LogoRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LogoMark(height: 32),
        SizedBox(width: 12),
        Text(
          'LibMate',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// The book mark of the app logo, shown from the same asset the splash
/// uses (no second logo file): the 2000 px logo image is drawn scaled and
/// clipped to the region holding the book.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.height});

  final double height;

  static const double _imageSize = 2000;
  static const Rect _book = Rect.fromLTRB(596, 521, 1404, 1131);

  /// The logo image has a solid white background; on this screen's tinted
  /// background that would show as a white box. Alpha = 1.4 x (3 - R - G - B)
  /// makes white transparent and keeps the book colours fully opaque.
  static const ColorFilter _whiteToClear = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    -1.4, -1.4, -1.4, 0, 1.4 * 3 * 255,
  ]);

  @override
  Widget build(BuildContext context) {
    final scale = height / _book.height;
    final full = _imageSize * scale;
    return SizedBox(
      width: _book.width * scale,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: full,
          maxWidth: full,
          minHeight: full,
          maxHeight: full,
          child: Transform.translate(
            offset: Offset(-_book.left * scale, -_book.top * scale),
            child: ColorFiltered(
              colorFilter: _whiteToClear,
              child: Image.asset(
              SplashScreen.logoAsset,
              key: const ValueKey('get-started-logo'),
              width: full,
              height: full,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'LibMate logo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The large light-blue circle with the yellow accent and the illustration.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Figma: the circle is ~74% of the screen width.
        final d = ((constraints.maxWidth + 48) * 0.74)
            .clamp(0.0, constraints.maxHeight * 0.88)
            .toDouble();
        final accent = d * 0.3;
        // Slightly below centre, as in Figma (closer to the tagline).
        return Align(
          alignment: const Alignment(0, 0.35),
          child: SizedBox(
            width: d,
            height: d,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: _Circle(size: double.infinity, color: AppColors.lightBlue),
                ),
                Positioned(
                  left: d / 2 + d * 0.338 - accent / 2,
                  top: d / 2 + d * 0.297 - accent / 2,
                  child: _Circle(size: accent, color: const Color(0xFFFEF3C7)),
                ),
                OverflowBox(
                  maxWidth: d * 1.12,
                  maxHeight: d * 1.12,
                  child: Image.asset(
                    GetStartedScreen.illustrationAsset,
                    key: const ValueKey('get-started-illustration'),
                    width: d * 1.08,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'Students using the library app',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
