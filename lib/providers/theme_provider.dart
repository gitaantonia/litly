import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// // DIUBAH: Provider tema hanya mendukung Light dan Dark (opsi System dihapus)
class ThemeProvider extends ChangeNotifier {
  // Default tema adalah Light
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    loadTheme();
  }

  // Muat tema yang tersimpan di SharedPreferences
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? modeString = prefs.getString('theme_mode');

    // // DIUBAH: Jika bernilai 'system' atau nilai tidak dikenal, fallback dan simpan ulang sebagai 'light'
    if (modeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
      if (modeString != 'light') {
        await prefs.setString('theme_mode', 'light');
      }
    }

    notifyListeners();
  }

  // Ubah tema aplikasi ke Light atau Dark dan simpan ke SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.dark) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String modeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString('theme_mode', modeString);
  }
}
