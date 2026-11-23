import 'package:litly/database/db_helper.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/services/session_service.dart';

// Service autentikasi dan manajemen akun pengguna
class AuthService {
  final DbHelper _db = DbHelper();

  // Proses login pengguna
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    Map<String, dynamic> result = await _db.loginUser(email, password);
    if (result['status'] == 'success') {
      UserModel user = result['user'];
      await SessionService.saveUserSession(
        user: user,
        rememberMe: rememberMe,
      );
    }
    return result;
  }

  // Proses pendaftaran akun baru
  Future<String?> register(UserModel user) async {
    bool exists = await _db.checkEmailExists(user.email);
    if (exists) {
      return 'Email sudah terdaftar';
    }
    int id = await _db.insertUser(user);
    if (id > 0) {
      user.id = id;
      await SessionService.saveUserSession(
        user: user,
        rememberMe: true,
      );
      return null;
    }
    return 'Gagal mendaftarkan pengguna';
  }

  // // DIUBAH: Update profil pengguna (nama dan avatar nullable)
  Future<String?> updateProfile(int userId, String name, String? avatar) async {
    try {
      int result = await _db.updateProfile(userId, name, avatar);
      if (result > 0) {
        return null;
      }
      return 'Gagal memperbarui profil pengguna';
    } catch (e) {
      return e.toString();
    }
  }

  // Logout dan hapus sesi pengguna
  Future<void> logout() async {
    await SessionService.clearSession();
  }
}
