import 'package:flutter/material.dart';

/// Agreed LibMate colours, used by every Librarian screen and widget.
/// Kept inside the Librarian feature until the team fills in the shared
/// app_theme.dart, so other modules are not affected.
class LibrarianColors {
  const LibrarianColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color navy = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF172033);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color gold = Color(0xFFF2B84B);
  static const Color available = Color(0xFF22A06B);
  static const Color unavailable = Color(0xFFDC4C4C);

  static const Color border = Color(0xFFE2E8F0);

  /// The Figma uses the green for text links ("See all") and the active tab.
  static const Color link = available;
}

/// Shared spacing and radius values so screens stay visually consistent.
class LibrarianSpacing {
  const LibrarianSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double radius = 16;

  /// Content is centred and capped at this width on wide (web) screens.
  static const double maxContentWidth = 960;
}

/// ThemeData applied to the Librarian area only (see LibrarianShell).
class LibrarianTheme {
  const LibrarianTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LibrarianColors.primary,
      primary: LibrarianColors.primary,
      secondary: LibrarianColors.gold,
      surface: LibrarianColors.card,
      onSurface: LibrarianColors.text,
      error: LibrarianColors.unavailable,
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LibrarianColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: LibrarianColors.background,
        foregroundColor: LibrarianColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Title style comes from textTheme.titleLarge below.
      ),
      cardTheme: CardThemeData(
        color: LibrarianColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
          side: const BorderSide(color: LibrarianColors.border),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: LibrarianColors.text,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: LibrarianColors.text,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: LibrarianColors.text),
        bodySmall: TextStyle(color: LibrarianColors.secondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LibrarianColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LibrarianColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LibrarianColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LibrarianColors.primary,
          minimumSize: const Size(0, 48),
          shape: roundedShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: roundedShape,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LibrarianColors.card,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? LibrarianColors.link
                : LibrarianColors.secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? LibrarianColors.link
                : LibrarianColors.secondaryText,
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: LibrarianColors.card,
        selectedColor: LibrarianColors.lightBlue,
        side: BorderSide(color: LibrarianColors.border),
      ),
    );
  }
}
