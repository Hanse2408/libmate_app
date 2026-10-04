import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _createTheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    background: AppColors.background,
    card: AppColors.lightCard,
    text: AppColors.text,
    secondaryText: AppColors.secondaryText,
    border: AppColors.border,
    navy: AppColors.navy,
    lightBlue: AppColors.lightBlue,
  );

  static ThemeData get dark => _createTheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    background: AppColors.darkBackground,
    card: AppColors.darkCard,
    text: AppColors.darkText,
    secondaryText: AppColors.darkSecondaryText,
    border: Colors.transparent,
    navy: AppColors.navy,
    lightBlue: AppColors.navy.withValues(alpha: 0.35),
  );

  static ThemeData _createTheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color card,
    required Color text,
    required Color secondaryText,
    required Color border,
    required Color navy,
    required Color lightBlue,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: AppColors.gold,
      surface: card,
      onSurface: text,
      error: AppColors.error,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: border),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: secondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: border == Colors.transparent ? navy : border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: border == Colors.transparent ? navy : border,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 48),
          shape: shape,
          side: BorderSide(
            color: border == Colors.transparent ? secondaryText : border,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : secondaryText,
            fontSize: 10,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBlue,
        selectedColor: primary,
        side: BorderSide(color: border),
      ),
    );
  }
}