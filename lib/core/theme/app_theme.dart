import 'package:flutter/material.dart';

class AppTheme {
  // TripSplite 브랜드 컬러
  static const Color primaryGreen = Color(0xFF5BC5A7);
  static const Color accentOrange = Color(0xFFFF652F);
  static const Color darkGreen = Color(0xFF1CC29F);
  static const Color lightGreen = Color(0xFFE8F5F1);
  
  // 정산 상태 컬러
  static const Color positiveGreen = Color(0xFF5BC5A7);
  static const Color negativeRed = Color(0xFFFF652F);
  static const Color neutralGray = Color(0xFF9E9E9E);
  
  // 배경 컬러
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentOrange,
        background: backgroundGray,
        surface: cardWhite,
      ),
      scaffoldBackgroundColor: backgroundGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: cardWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }
  
  static TextStyle get currencyStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryGreen,
  );
  
  static TextStyle get balancePositiveStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: positiveGreen,
  );
  
  static TextStyle get balanceNegativeStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: negativeRed,
  );
}
