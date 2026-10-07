import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();


static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: const Color(0xFFF8FAFC),
    card: Colors.white,
    primary: const Color(0xFF2563EB),
    text: const Color(0xFF172033),
    secondaryText: const Color(0xFF64748B),
  );

static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: const Color(0xFF0F172A),
    card: const Color(0xFF172554),
    primary: const Color(0xFF3B82F6),
    text: const Color(0xFFF8FAFC),
    secondaryText: const Color(0xFFCBD5E1),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color card,
    required Color primary,
    required Color text,
    required Color secondaryText,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: const Color(0xFFF2B84B),
      surface: card,
      onSurface: text,
      error: const Color(0xFFDC4C4C),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardTheme: CardThemeData(color: card),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: secondaryText),
        titleLarge: TextStyle(color: text),
        titleMedium: TextStyle(color: text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(primary),
        trackColor: WidgetStatePropertyAll(
          brightness == Brightness.dark
              ? const Color(0xFF1E3A8A)
              : const Color(0xFFBFDBFE),
        ),
      ),
    );
  }
}

class AppThemeController extends ChangeNotifier {
  static final AppThemeController instance = AppThemeController._();

  AppThemeController._();

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void setDarkMode(bool enabled) {
    if (_isDarkMode == enabled) return;
    _isDarkMode = enabled;
    notifyListeners();
  }
}
