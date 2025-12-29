import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Standard Dark Theme Colors
  static const _darkBackground = Color(0xFF121212);
  static const _darkError = Color(0xFFCF6679);

  // Vibrant Dark Theme Colors
  static const _vibrantBackground = Color(0xFF0A0E21); // Deep Blue-Black
  static const _vibrantSurface = Color(0xFF1D1E33);    // Dark Purple-Grey
  static const _vibrantPrimary = Color(0xFFFF5722);    // Deep Orange
  static const _vibrantSecondary = Color(0xFF9C27B0);  // Vivid Purple

  // Text opacities
  static const _highEmphasis = 0.87;

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData get darkTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _darkBackground,
      error: _darkError,
    );

    return _buildTheme(baseScheme, _darkBackground);
  }

  static ThemeData get vibrantTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _vibrantPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _vibrantPrimary,
      secondary: _vibrantSecondary,
      surface: _vibrantSurface,
      background: _vibrantBackground,
      error: _darkError,
    );

    return _buildTheme(baseScheme, _vibrantBackground);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Color background) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white.withOpacity(_highEmphasis),
        displayColor: Colors.white.withOpacity(_highEmphasis),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white.withOpacity(_highEmphasis),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: colorScheme.primary.withOpacity(0.3), // Stronger indicator
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: colorScheme.primary, // Vibrant selected icon
              size: 26,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurface.withOpacity(0.6), // Brighter unselected (was white with 0.5)
            size: 24,
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          );
        }),
      ),
    );
  }
}
