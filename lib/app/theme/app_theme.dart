// FILE: lib/app/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Kos Bae App Theme
/// Pastel gradient colors inspired by logo
class AppTheme {
  AppTheme._();
  
  // Kos Bae pastel color palette
  static const Color pastelBlue = Color(0xFFADD8E6);
  static const Color softGreen = Color(0xFFB8E6B8);
  static const Color warmPeach = Color(0xFFFFCBA4);
  static const Color lightYellow = Color(0xFFFFF4B8);
  static const Color softPink = Color(0xFFFFB8D1);
  static const Color softGrey = Color(0xFFB0BEC5);
  
  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pastelBlue, softGreen, warmPeach, softPink],
  );
  
  static const LinearGradient selectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [pastelBlue, softGreen],
  );
  
  static const LinearGradient bottomNavGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAFAFA),
      Color(0xFFFFFFFF),
    ],
  );
  
  /// Get MaterialApp theme
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pastelBlue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Poppins', // TODO: Add to pubspec.yaml
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black12,
      ),
      
      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.black54,
      ),
    );
  }
}
