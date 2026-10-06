import 'package:flutter/material.dart';

/// One set of Librarian colours. [light] is the agreed LibMate palette;
/// [dark] follows the Librarian dark-mode designs (deep navy background,
/// raised navy cards, soft borders, brighter accents for contrast).
class LibrarianPalette {
  const LibrarianPalette({
    required this.isDark,
    required this.primary,
    required this.navy,
    required this.lightBlue,
    required this.background,
    required this.card,
    required this.text,
    required this.secondaryText,
    required this.gold,
    required this.available,
    required this.unavailable,
    required this.border,
    required this.inputFill,
    required this.navBar,
    required this.avatar,
    required this.emphasis,
  });

  final bool isDark;
  final Color primary;
  final Color navy;

  /// Tinted background for icons, selected chips and highlights.
  final Color lightBlue;
  final Color background;

  /// Cards, sheets and dialogs.
  final Color card;
  final Color text;
  final Color secondaryText;
  final Color gold;
  final Color available;
  final Color unavailable;
  final Color border;

  /// Text field background.
  final Color inputFill;

  /// Bottom navigation background.
  final Color navBar;

  /// Background of initials avatars (white initials on top).
  final Color avatar;

  /// Navy accents drawn as text or thin bars (lighter in dark mode, so they
  /// stay readable on dark cards).
  final Color emphasis;

  static const LibrarianPalette light = LibrarianPalette(
    isDark: false,
    primary: Color(0xFF2563EB),
    navy: Color(0xFF1E3A8A),
    lightBlue: Color(0xFFEFF6FF),
    background: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF172033),
    secondaryText: Color(0xFF64748B),
    gold: Color(0xFFF2B84B),
    available: Color(0xFF22A06B),
    unavailable: Color(0xFFDC4C4C),
    border: Color(0xFFE2E8F0),
    inputFill: Color(0xFFFFFFFF),
    navBar: Color(0xFFFFFFFF),
    avatar: Color(0xFF172033),
    emphasis: Color(0xFF1E3A8A),
  );

  static const LibrarianPalette dark = LibrarianPalette(
    isDark: true,
    primary: Color(0xFF3B82F6),
    navy: Color(0xFF1E3A8A),
    lightBlue: Color(0xFF1B2B4B),
    background: Color(0xFF0B1220),
    card: Color(0xFF162033),
    text: Color(0xFFF1F5F9),
    secondaryText: Color(0xFF94A3B8),
    gold: Color(0xFFF5B942),
    available: Color(0xFF2BC37F),
    unavailable: Color(0xFFF05252),
    border: Color(0xFF2A3A57),
    inputFill: Color(0xFF0F1A2C),
    navBar: Color(0xFF111A2B),
    avatar: Color(0xFF3B82F6),
    emphasis: Color(0xFF93B4F8),
  );
}

/// Colours used by every Librarian screen and widget.
///
/// The values come from the current [LibrarianPalette], so the same screens
/// draw in light or dark mode. LibrarianShell selects the palette (from the
/// Settings switch) and rebuilds the Librarian widgets when it changes.
/// Kept inside the Librarian feature, so other modules are not affected.
class LibrarianColors {
  const LibrarianColors._();

  /// The palette in use (set by LibrarianShell).
  static LibrarianPalette palette = LibrarianPalette.light;
  static LibrarianPalette get _palette => palette;

  static bool get isDark => _palette.isDark;

  static Color get primary => _palette.primary;
  static Color get navy => _palette.navy;
  static Color get lightBlue => _palette.lightBlue;
  static Color get background => _palette.background;
  static Color get card => _palette.card;
  static Color get text => _palette.text;
  static Color get secondaryText => _palette.secondaryText;
  static Color get gold => _palette.gold;
  static Color get available => _palette.available;
  static Color get unavailable => _palette.unavailable;
  static Color get border => _palette.border;
  static Color get inputFill => _palette.inputFill;
  static Color get navBar => _palette.navBar;
  static Color get avatar => _palette.avatar;
  static Color get emphasis => _palette.emphasis;

  /// The Figma uses the green for text links ("See all") and the active tab.
  static Color get link => available;
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

  static ThemeData get light => of(LibrarianPalette.light);
  static ThemeData get dark => of(LibrarianPalette.dark);

  /// Builds the Librarian theme from [p]. The light theme is exactly the
  /// original one; the dark theme also styles dialogs, sheets, menus,
  /// snackbars, switches and other Material components for dark surfaces.
  static ThemeData of(LibrarianPalette p) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primary: p.primary,
      secondary: p.gold,
      surface: p.card,
      onSurface: p.text,
      error: p.unavailable,
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Title style comes from textTheme.titleLarge below.
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
          side: BorderSide(color: p.border),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: p.text, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: p.text, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: p.text),
        bodySmall: TextStyle(color: p.secondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
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
        backgroundColor: p.navBar,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.available
                : p.secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? p.available
                : p.secondaryText,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.lightBlue,
        side: BorderSide(color: p.border),
      ),
    );
    if (!p.isDark) return base;

    // Dark only: the light theme above stays exactly as it was.
    final textOnDark = TextStyle(color: p.text);
    return base.copyWith(
      brightness: Brightness.dark,
      canvasColor: p.background,
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border),
      iconTheme: IconThemeData(color: p.secondaryText),
      textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text).copyWith(
        titleLarge: base.textTheme.titleLarge,
        titleMedium: base.textTheme.titleMedium,
        bodyMedium: base.textTheme.bodyMedium,
        bodySmall: base.textTheme.bodySmall,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: p.secondaryText.withValues(alpha: 0.8)),
        labelStyle: TextStyle(color: p.secondaryText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.35),
        selectionHandleColor: p.primary,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: roundedShape,
          foregroundColor: p.text,
          side: BorderSide(color: p.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textOnDark.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: p.secondaryText, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
          side: BorderSide(color: p.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.secondaryText,
        modalBackgroundColor: p.card,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        textStyle: textOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(backgroundColor: WidgetStatePropertyAll(p.card)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFE2E8F0),
        contentTextStyle: const TextStyle(color: Color(0xFF172033)),
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        textColor: p.text,
        iconColor: p.secondaryText,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : p.secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.inputFill,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: p.secondaryText, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.lightBlue,
        side: BorderSide(color: p.border),
        labelStyle: textOnDark,
        secondaryLabelStyle: TextStyle(color: p.primary),
        checkmarkColor: p.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: p.text,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.card,
        dialBackgroundColor: p.inputFill,
      ),
    );
  }
}
