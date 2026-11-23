import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

// Konfigurasi tampilan terang aplikasi Litly
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.kBackground,
      cardColor: AppColors.cardBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.kPurple,
        secondary: AppColors.kYellow,
        surface: AppColors.cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kBackground,
        foregroundColor: AppColors.kNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    );
  }
}
