import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/models/user_model.dart';

// Service untuk mengelola sesi login pengguna dengan SharedPreferences
class SessionService {
  static final String keyIsLoggedIn = 'is_logged_in';
  static final String keyUserId = 'user_id';
  static final String keyUserName = 'user_name';
  static final String keyUserEmail = 'user_email';
  static final String keyRememberMe = 'remember_me';

  // Menyimpan sesi pengguna yang berhasil login atau register
  static Future<void> saveUserSession({
    required UserModel user,
    required bool rememberMe,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setInt(keyUserId, user.id ?? 0);
    await prefs.setString(keyUserName, user.name);
    await prefs.setString(keyUserEmail, user.email);
    await prefs.setBool(keyRememberMe, rememberMe);
    await prefs.setString('username', user.name);
  }

  // Memeriksa apakah pengguna memiliki sesi login yang aktif
  static Future<bool> isSessionActive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
    bool rememberMe = prefs.getBool(keyRememberMe) ?? false;
    return isLoggedIn && rememberMe;
  }

  // Mengambil informasi pengguna yang sedang login
  static Future<Map<String, dynamic>> getSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getInt(keyUserId) ?? 0,
      'user_name': prefs.getString(keyUserName) ?? '',
      'user_email': prefs.getString(keyUserEmail) ?? '',
      'remember_me': prefs.getBool(keyRememberMe) ?? false,
    };
  }

  // Menghapus sesi saat pengguna logout
  static Future<void> clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, false);
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.setBool(keyRememberMe, false);
    await prefs.remove('username');
  }
}
