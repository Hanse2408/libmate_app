import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// The Student side has no dark mode, so the e-book screens always use the
/// Student light theme ([AppTheme.light]), even when the device (and so
/// the app's `ThemeMode.system`) is dark.
final ThemeData _studentLight = AppTheme.light;

/// Wraps a Student e-book screen in the Student light theme, so stock
/// widgets (text fields, spinners, buttons) are light too.
class StudentEbookTheme extends StatelessWidget {
  const StudentEbookTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: _studentLight, child: child);
}

/// Colours for the Student e-book screens, from the Student light theme
/// (LibMate blue, surfaces, text).
class EbookColors {
  const EbookColors._(this._scheme, this.background);

  factory EbookColors.of(BuildContext context) => EbookColors._(
    _studentLight.colorScheme,
    _studentLight.scaffoldBackgroundColor,
  );

  final ColorScheme _scheme;
  final Color background;

  Color get primary => _scheme.primary;
  Color get onPrimary => _scheme.onPrimary;
  Color get surface => _scheme.surface;
  Color get text => _scheme.onSurface;
  Color get muted => _scheme.onSurface.withValues(alpha: 0.62);
  Color get border => _scheme.outlineVariant;
  Color get tint => _scheme.primaryContainer.withValues(alpha: 0.55);
  Color get error => _scheme.error;
  Color get success => const Color(0xFF22A06B);
}

/// Page header from the E-books design: round back button, bold title and
/// a grey subtitle.
class EbookPageHeader extends StatelessWidget {
  const EbookPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: c.surface,
            shape: CircleBorder(side: BorderSide(color: c.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox.square(
                dimension: 44,
                child: Tooltip(
                  message: 'Back',
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: c.text,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(color: c.muted, fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "E-book" badge.
class EbookBadge extends StatelessWidget {
  const EbookBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tablet_mac_rounded, size: 14, color: c.primary),
          const SizedBox(width: 4),
          Text(
            'E-book',
            style: TextStyle(
              color: c.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
