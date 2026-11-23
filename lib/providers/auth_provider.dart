import 'package:flutter/material.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/services/auth_service.dart';
import 'package:litly/services/session_service.dart';

// Provider untuk manajemen state autentikasi dan profil pengguna
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    loadUserFromSession();
  }

  // Muat data pengguna yang sedang login dari session lokal
  Future<void> loadUserFromSession() async {
    Map<String, dynamic> sessionData = await SessionService.getSessionData();
    String email = sessionData['user_email'] as String? ?? '';

    if (email.isNotEmpty) {
      UserModel? dbUser = await DbHelper().getUserByEmail(email);
      if (dbUser != null) {
        _user = dbUser;
        notifyListeners();
        return;
      }

      // Fallback jika database belum mengembalikan data
      _user = UserModel(
        id: sessionData['user_id'] as int?,
        name: sessionData['user_name'] as String? ?? 'Pengguna',
        email: email,
        password: '',
        securityPin: '',
        createdAt: DateTime.now().toIso8601String(),
      );
      notifyListeners();
    }
  }

  // Set user secara manual jika diperlukan
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Proses login pengguna
  Future<String?> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic> result = await _authService.login(
      email,
      password,
      rememberMe: rememberMe,
    );
    _isLoading = false;

    if (result['status'] == 'success') {
      _user = result['user'] as UserModel;
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return result['message'] as String? ?? 'Login gagal';
    }
  }

  // Proses pendaftaran akun baru
  Future<String?> register(UserModel newUser) async {
    _isLoading = true;
    notifyListeners();

    String? error = await _authService.register(newUser);
    _isLoading = false;

    if (error == null) {
      _user = newUser;
    }
    notifyListeners();
    return error;
  }

  // // DIUBAH: Update profil (nama dan avatar nullable)
  Future<String?> updateProfile(int userId, String name, String? avatar) async {
    _isLoading = true;
    notifyListeners();

    String? error = await _authService.updateProfile(userId, name, avatar);
    _isLoading = false;

    if (error == null) {
      if (_user != null) {
        _user!.name = name;
        _user!.avatar = avatar;
        // Sinkronkan juga ke session SharedPreferences
        await SessionService.saveUserSession(user: _user!, rememberMe: true);
      }
      notifyListeners();
      return null;
    }

    notifyListeners();
    return error;
  }

  // Logout akun pengguna
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
