import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:litly/models/user_model.dart';

// Helper untuk mengelola database SQLite lokal Litly
class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() {
    return _instance;
  }

  DbHelper._internal();

  // Inisialisasi atau ambil instance database yang sudah aktif
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Membuat dan membuka database SQLite
  Future<Database> _initDatabase() async {
    // Inisialisasi databaseFactory untuk platform Desktop (Windows / Linux)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'litly_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Buat tabel users untuk penyimpanan akun lokal
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            security_pin TEXT NOT NULL,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // Fungsi untuk hashing password menggunakan SHA-256
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Cek apakah email sudah terdaftar di database
  Future<bool> checkEmailExists(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Fungsi insertUser untuk menyimpan data akun baru ke SQLite
  Future<int> insertUser(UserModel user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  // Alias fungsi registerUser untuk kompatibilitas
  Future<int> registerUser(UserModel user) async {
    return await insertUser(user);
  }

  // Memvalidasi proses login pengguna
  Future<Map<String, dynamic>> loginUser(String email, String rawPassword) async {
    Database db = await database;
    String cleanEmail = email.trim().toLowerCase();

    // 1. Cek apakah email terdaftar
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    if (result.isEmpty) {
      return {
        'status': 'not_found',
        'message': 'Email tidak ditemukan',
        'user': null,
      };
    }

    // 2. Cek apakah password cocok
    UserModel user = UserModel.fromMap(result.first);
    String inputHashedPassword = hashPassword(rawPassword);

    if (user.password != inputHashedPassword) {
      return {
        'status': 'wrong_password',
        'message': 'Kata sandi salah',
        'user': null,
      };
    }

    // 3. Login sukses
    return {
      'status': 'success',
      'message': 'Login berhasil',
      'user': user,
    };
  }

  // Ambil data user berdasarkan email
  Future<UserModel?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Verifikasi PIN keamanan untuk fitur Forgot Password
  Future<bool> verifySecurityPin(String email, String pin) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'LOWER(email) = ? AND security_pin = ?',
      whereArgs: [email.trim().toLowerCase(), pin.trim()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Update password akun pengguna setelah verifikasi PIN berhasil
  Future<int> updatePassword(String email, String newPasswordHash) async {
    Database db = await database;
    return await db.update(
      'users',
      {'password': newPasswordHash},
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }
}
