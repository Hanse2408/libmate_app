import 'package:flutter/material.dart';

/// Semantic colours shared by the student reservation screens.
class StudentPalette {
  StudentPalette.of(BuildContext context) : theme = Theme.of(context);
  final ThemeData theme;
  bool get isDark => theme.brightness == Brightness.dark;
  Color get card => theme.colorScheme.surface;
  Color get text => theme.colorScheme.onSurface;
  Color get muted => theme.colorScheme.onSurfaceVariant;
  Color get primary => theme.colorScheme.primary;
  Color get border => theme.dividerColor;
  Color get field => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get blueTint => primary.withValues(alpha: isDark ? 0.18 : 0.07);
  Color get blueBorder => primary.withValues(alpha: isDark ? 0.35 : 0.25);
  Color get gold => const Color(0xFFF2B84B);
  Color get goldTint => gold.withValues(alpha: isDark ? 0.13 : 0.16);
  Color get goldBorder => gold.withValues(alpha: 0.35);
  Color get goldText => isDark ? gold : const Color(0xFF8A4B08);
  Color get success => isDark ? const Color(0xFF6EE7B7) : const Color(0xFF22A06B);
  Color get successTint => const Color(0xFF22A06B).withValues(alpha: isDark ? 0.16 : 0.10);
  Color get error => isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC4C4C);
  Color get errorTint => const Color(0xFFDC4C4C).withValues(alpha: isDark ? 0.16 : 0.10);
  Color get neutralTint => muted.withValues(alpha: 0.10);
}