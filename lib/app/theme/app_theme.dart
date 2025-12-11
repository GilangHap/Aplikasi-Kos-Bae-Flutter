// FILE: lib/app/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kos Bae App Theme
/// Premium Blue & Cream color palette inspired by logo
/// Supports both light and dark modes
class AppTheme {
  AppTheme._();

  // Premium Blue & Cream color palette - Inspired by logo
  static const Color primaryBlue = Color(0xFF5B8DB8); // Main blue from logo
  static const Color deepBlue = Color(0xFF2C3E50); // Dark blue for contrast
  static const Color lightBlue = Color(0xFF7BA9CC); // Light blue accent
  static const Color skyBlue = Color(0xFFADD8E6); // Soft sky blue
  static const Color cream = Color(0xFFF5E6D3); // Warm cream from logo
  static const Color darkCream = Color(0xFFE8D4BA); // Darker cream shade
  static const Color gold = Color(0xFFD4AF37); // Premium gold accent
  static const Color charcoal = Color(0xFF2D3436); // Premium dark gray
  static const Color softGrey = Color(0xFFF8F9FA); // Background gray
  static const Color mediumGrey = Color(0xFFDFE6E9); // Border gray

  // Dark mode colors
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);
  static const Color darkCard = Color(0xFF0F3460);

  // Legacy colors for backward compatibility (will be phased out)
  static const Color pastelBlue = primaryBlue;
  static const Color softGreen = Color(0xFFB8E6B8);
  static const Color warmPeach = cream;
  static const Color lightYellow = Color(0xFFFFF4B8);
  static const Color softPink = Color(0xFFFFB8D1);

  // Premium Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, deepBlue],
  );

  static const LinearGradient selectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, lightBlue],
  );

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, darkCream],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, deepBlue, gold],
  );

  static const LinearGradient bottomNavGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [softGrey, Colors.white],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBackground, darkSurface],
  );

  /// Get default theme (light mode)
  static ThemeData getTheme() => getLightTheme();

  /// Get MaterialApp light theme with premium fonts
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: cream,
        surface: Colors.white,
        error: const Color(0xFFE74C3C),
      ),
      scaffoldBackgroundColor: softGrey,
      textTheme: GoogleFonts.interTextTheme(),

      // AppBar theme - Premium style
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: charcoal),
        titleTextStyle: GoogleFonts.inter(
          color: charcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      // Card theme - Premium elevated cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: mediumGrey.withOpacity(0.3), width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.08),
        color: Colors.white,
      ),

      // Button theme - Premium style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: mediumGrey.withOpacity(0.5),
        thickness: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: Colors.black54),
    );
  }

  /// Get MaterialApp dark theme with premium fonts
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: lightBlue,
        secondary: darkCream,
        surface: darkSurface,
        error: const Color(0xFFE74C3C),
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

      // AppBar theme - Dark style
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      // Card theme - Dark elevated cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: darkCard.withOpacity(0.5), width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
        color: darkSurface,
      ),

      // Button theme - Dark style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: lightBlue,
          foregroundColor: darkBackground,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkCard),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkCard),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: darkCard.withOpacity(0.5),
        thickness: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: Colors.white70),

      // Bottom navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: lightBlue,
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}

