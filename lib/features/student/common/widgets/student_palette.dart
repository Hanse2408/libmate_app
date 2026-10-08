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
  Color get border => isDark
      ? const Color(0xFF30436B) : const Color(0xFFDDE5F1);

  /// Shared surface treatment keeps the student screens visually consistent.
  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, Color.alphaBlend(primary.withValues(alpha: isDark ? .07 : .025), card)],
  );
  List<BoxShadow> get cardShadow => [
    BoxShadow(color: (isDark ? Colors.black : const Color(0xFF1E3A8A))
      .withValues(alpha: isDark ? .12 : .045), blurRadius: 18, offset: const Offset(0, 5)),
  ];
  LinearGradient get actionGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, isDark ? const Color(0xFF2563EB) : const Color(0xFF1E40AF)],
  );
  List<BoxShadow> get actionShadow => [
    BoxShadow(color: primary.withValues(alpha: isDark ? .14 : .16),
      blurRadius: 12, offset: const Offset(0, 4)),
  ];
  Color get field => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get blueTint => primary.withValues(alpha: isDark ? 0.18 : 0.055);
  Color get blueBorder => primary.withValues(alpha: isDark ? 0.35 : 0.25);
  Color get favorite => isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777);
  Color get gold => const Color(0xFFF2B84B);
  Color get goldTint => gold.withValues(alpha: isDark ? 0.13 : 0.16);
  Color get goldBorder => gold.withValues(alpha: isDark ? .28 : .22);
  Color get goldText => isDark ? gold : const Color(0xFF8A4B08);
  Color get success => isDark ? const Color(0xFF6EE7B7) : const Color(0xFF22A06B);
  Color get successTint => const Color(0xFF22A06B).withValues(alpha: isDark ? 0.16 : 0.10);
  Color get error => isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC4C4C);
  Color get errorTint => const Color(0xFFDC4C4C).withValues(alpha: isDark ? 0.16 : 0.10);
  Color get neutralTint => muted.withValues(alpha: 0.10);
}