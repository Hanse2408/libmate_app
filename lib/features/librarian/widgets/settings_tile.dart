import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// One settings row from the Profile design: tinted icon square, title,
/// small subtitle and a trailing value / switch / chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.iconColor = LibrarianColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short value shown on the right, e.g. "14 days".
  final String? value;

  /// Custom trailing widget (e.g. a Switch). Defaults to a chevron when the
  /// tile is tappable.
  final Widget? trailing;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LibrarianSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: Color.lerp(iconColor, LibrarianColors.text, 0.2)),
            ),
            const SizedBox(width: LibrarianSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LibrarianColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: LibrarianColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: LibrarianSpacing.sm),
              Text(
                value!,
                style: const TextStyle(
                  color: LibrarianColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: LibrarianColors.secondaryText),
          ],
        ),
      ),
    );
  }
}

/// A group of settings tiles separated by dividers, inside the same
/// rounded outlined card used across the Librarian screens.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: LibrarianSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: LibrarianColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: LibrarianSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: LibrarianSpacing.md,
            vertical: LibrarianSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: LibrarianColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: LibrarianColors.gold.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: LibrarianColors.border),
                tiles[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
