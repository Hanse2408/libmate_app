import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// LibMate start-up splash: the LibMate logo on white (the logo's own
/// background) with a slim loading bar. Always light, whatever the device
/// theme, like the rest of the Student-facing start-up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.animate = true, this.errorMessage});

  static const String logoAsset = 'assets/logos/libmate_logo.png';

  /// Fade / scale the logo in. Off when the splash is already on screen
  /// (the router's splash continues the one shown while Firebase starts).
  final bool animate;

  /// Shown instead of the loading bar when start-up failed.
  final String? errorMessage;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.94, end: 1)
      .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // The logo image has wide white margins; this keeps the artwork about
    // 60% of a phone's width and at most ~330 px wide on desktop / web.
    final logoSize = (size.shortestSide * 0.8).clamp(220.0, 440.0);
    final error = widget.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.lightCard, // the logo's white background
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Image.asset(
                    SplashScreen.logoAsset,
                    key: const ValueKey('libmate-splash-logo'),
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'LibMate',
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 56,
              child: Center(
                child: error != null
                    ? Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      )
                    : FadeTransition(
                        opacity: _fade,
                        child: SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              minHeight: 3,
                              color: AppColors.primary,
                              backgroundColor: AppColors.lightBlue,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
