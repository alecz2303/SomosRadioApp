import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const orange = Color(0xFFF28A1A);
  static const background = Color(0xFF090909);
  static const surface = Color(0xFF171717);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
    );
  }
}
