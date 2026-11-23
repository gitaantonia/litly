import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Konfigurasi tema terang dan gelap aplikasi Litly
class AppTheme {
  // Tema terang (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Color(0xFFFDFDFD),
      cardColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: Color(0xFFB5294E),
        secondary: Color(0xFF8550A0),
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    );
  }

  // Tema gelap (Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Color(0xFF121216),
      cardColor: Color(0xFF1E1E26),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFB5294E),
        secondary: Color(0xFFC3A6D8),
        surface: Color(0xFF1E1E26),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    );
  }
}
