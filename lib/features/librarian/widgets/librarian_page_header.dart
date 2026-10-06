import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../theme/librarian_theme.dart';

/// Page title block from the Figma: round back button, bold title and a grey
/// subtitle, with an optional widget on the right (e.g. a status chip).
class LibrarianPageHeader extends StatelessWidget {
  const LibrarianPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Defaults to going back one page, or to the Dashboard if there is none.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LibrarianSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack ?? () => _defaultBack(context)),
          const SizedBox(width: LibrarianSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: LibrarianColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: LibrarianColors.secondaryText,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: LibrarianSpacing.sm),
            Padding(padding: const EdgeInsets.only(top: 6), child: trailing),
          ],
        ],
      ),
    );
  }

  static void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(LibrarianRoutes.dashboard);
    }
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LibrarianColors.card,
      shape: CircleBorder(side: BorderSide(color: LibrarianColors.border)),
      child: IconButton(
        tooltip: 'Back',
        onPressed: onPressed,
        icon: Icon(Icons.chevron_left, color: LibrarianColors.text),
      ),
    );
  }
}
