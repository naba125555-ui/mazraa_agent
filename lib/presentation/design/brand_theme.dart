import 'package:flutter/material.dart';

abstract final class Brand {
  static const forest = Color(0xFF146046);
  static const orange = Color(0xFF9B542B);
  static const ivory = Color(0xFFF5F7F1);
  static const night = Color(0xFF111A15);
  static const mint = Color(0xFFA9DCBA);

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? night : ivory;
    final color =
        ColorScheme.fromSeed(
          seedColor: forest,
          brightness: brightness,
        ).copyWith(
          primary: dark ? mint : forest,
          onPrimary: dark ? const Color(0xFF122F22) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF284A39)
              : const Color(0xFFDEEFE5),
          onPrimaryContainer: dark
              ? const Color(0xFFD8F2E0)
              : const Color(0xFF174A33),
          secondary: dark ? const Color(0xFFF0BC9B) : orange,
          surface: dark ? const Color(0xFF1B2720) : const Color(0xFFFFFFFF),
          surfaceContainer: dark
              ? const Color(0xFF24322A)
              : const Color(0xFFEEF2EC),
          onSurface: dark ? const Color(0xFFF1F5EF) : const Color(0xFF142922),
          onSurfaceVariant: dark
              ? const Color(0xFFBAC9BE)
              : const Color(0xFF475A50),
          outline: dark ? const Color(0xFF62766A) : const Color(0xFF9DAFA4),
          outlineVariant: dark
              ? const Color(0xFF3A4D40)
              : const Color(0xFFD9E3DA),
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: color,
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['Noto Sans Arabic', 'Arial'],
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 33,
          height: 1.27,
          fontWeight: FontWeight.w800,
          color: color.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 25,
          height: 1.3,
          fontWeight: FontWeight.w800,
          color: color.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          height: 1.33,
          fontWeight: FontWeight.w800,
          color: color.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: color.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.55,
          color: color.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: color.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          height: 1.5,
          color: color.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: color.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 58,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: color.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: color.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: color.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: color.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: color.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: color.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: BorderSide(color: color.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: color.surface,
        indicatorColor: color.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color.onSurface,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: color.outlineVariant, space: 20),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: color.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
