import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Dashboard summary card, e.g. "TODAY 24". The [highlighted] version is the
/// solid blue card used for the most important number (pending requests).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.subtitleIcon,
    this.subtitleColor,
    this.highlighted = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final IconData? subtitleIcon;
  final Color? subtitleColor;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? Colors.white : LibrarianColors.text;
    final muted = highlighted
        ? Colors.white.withValues(alpha: 0.85)
        : LibrarianColors.secondaryText;

    return Card(
      color: highlighted ? LibrarianColors.primary : LibrarianColors.card,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LibrarianSpacing.md + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(icon, size: 22, color: highlighted ? Colors.white : muted),
                ],
              ),
              const SizedBox(height: LibrarianSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: LibrarianSpacing.sm),
                Row(
                  children: [
                    if (subtitleIcon != null) ...[
                      Icon(subtitleIcon, size: 16, color: subtitleColor ?? muted),
                      const SizedBox(width: LibrarianSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: subtitleColor ?? muted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
