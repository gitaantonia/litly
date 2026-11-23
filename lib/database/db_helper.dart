import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/database/database_initializer.dart';

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

  // Membuat dan membuka database SQLite sesuai platform aktif
  Future<Database> _initDatabase() async {
    final factory = litlyDatabaseFactory;
    String path;

    if (kIsWeb) {
      path = 'litly_local.db';
    } else {
      final databasesPath = await factory.getDatabasesPath();
      path = join(databasesPath, 'litly_local.db');
    }

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5, // // DIUBAH: versi 5 untuk tabel books dan reading_sessions
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            List<Map<String, dynamic>> columns = await db.rawQuery(
              'PRAGMA table_info(users)',
            );
            bool hasAvatar = false;
            for (var col in columns) {
              if (col['name'] == 'avatar') {
                hasAvatar = true;
                break;
              }
            }
            if (!hasAvatar) {
              await db.execute('ALTER TABLE users ADD COLUMN avatar TEXT');
            }
          }
          if (oldVersion < 3) {
            await _createAchievementsTable(db);
          }
          if (oldVersion < 4) {
            await _createUserAchievementsTable(db);
          }
          if (oldVersion < 5) {
            await _createBooksAndSessionsTable(db);
          }
        },
        onOpen: (db) async {
          await _createTables(db);
        },
      ),
    );
  }

  // Memastikan semua tabel siap digunakan
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        security_pin TEXT NOT NULL,
        created_at TEXT,
        avatar TEXT
      )
    ''');

    await _createAchievementsTable(db);
    await _createUserAchievementsTable(db);
    await _createBooksAndSessionsTable(db);
  }

  // // BARU: Tabel books dan reading_sessions untuk riwayat baca
  Future<void> _createBooksAndSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_url TEXT,
        total_pages INTEGER NOT NULL,
        current_page INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Want to Read',
        completed_at TEXT,
        added_at TEXT,
        user_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        start_page INTEGER NOT NULL DEFAULT 0,
        end_page INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Pastikan kolom completed_at ada pada books jika tabel sudah ada sebelumnya
    try {
      await db.execute('ALTER TABLE books ADD COLUMN completed_at TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE books ADD COLUMN user_id INTEGER');
    } catch (_) {}

    // Pastikan kolom start_page dan end_page ada pada reading_sessions jika tabel sudah ada sebelumnya
    try {
      await db.execute(
        'ALTER TABLE reading_sessions ADD COLUMN start_page INTEGER DEFAULT 0',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE reading_sessions ADD COLUMN end_page INTEGER DEFAULT 0',
      );
    } catch (_) {}
  }

  // Tabel master daftar lencana (achievements)
  Future<void> _createAchievementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_name TEXT NOT NULL
      )
    ''');

    final achievements = [
      {
        'id': 'first_step',
        'title': 'Gaskeun Baca!',
        'description': 'Mencatat sesi baca pertamamu.',
        'icon_name': 'explore',
      },
      {
        'id': 'page_turner',
        'title': 'Pejuang Halaman',
        'description': 'Mencapai target halaman harian (atau 20 halaman).',
        'icon_name': 'auto_stories',
      },
      {
        'id': 'goal_crusher',
        'title': 'Target? Libas!',
        'description': 'Target harian tercapai 3 hari berturut-turut.',
        'icon_name': 'emoji_events',
      },
      {
        'id': 'bookworm',
        'title': 'Tamatin, Bestie!',
        'description': 'Menyelesaikan buku pertamamu.',
        'icon_name': 'menu_book',
      },
      {
        'id': 'night_owl',
        'title': 'Kuntil Baca',
        'description': 'Mencatat sesi baca mulai pukul 20.00 sampai 03.59.',
        'icon_name': 'nightlight_round',
      },
      {
        'id': 'marathon_reader',
        'title': 'Maraton Tipis-Tipis',
        'description': 'Membaca minimal 60 menit dalam satu sesi.',
        'icon_name': 'timer',
      },
      {
        'id': 'monthly_champ',
        'title': 'Jagoan Bulanan',
        'description': 'Mencapai target buku bulananmu.',
        'icon_name': 'emoji_events',
      },
      {
        'id': 'year_champ',
        'title': 'Legenda Baca',
        'description': 'Mencapai target buku tahunanmu.',
        'icon_name': 'emoji_events',
      },
    ];

    for (final achievement in achievements) {
      await db.insert(
        'achievements',
        achievement,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // // BARU: Tabel lencana yang terbuka per pengguna (user_achievements)
  Future<void> _createUserAchievementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_achievements (
        user_id INTEGER NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY (user_id, achievement_id)
      )
    ''');
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

  // Simpan data akun baru ke SQLite
  Future<int> insertUser(UserModel user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  // Alias fungsi registerUser untuk kompatibilitas
  Future<int> registerUser(UserModel user) async {
    return await insertUser(user);
  }

  // Memvalidasi proses login pengguna
  Future<Map<String, dynamic>> loginUser(
    String email,
    String rawPassword,
  ) async {
    Database db = await database;
    String cleanEmail = email.trim().toLowerCase();

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

    UserModel user = UserModel.fromMap(result.first);
    if (user.password != rawPassword) {
      return {
        'status': 'wrong_password',
        'message': 'Kata sandi salah',
        'user': null,
      };
    }

    return {'status': 'success', 'message': 'Login berhasil', 'user': user};
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

  // Verifikasi PIN keamanan
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

  // Update password pengguna
  Future<int> updatePassword(String email, String newPassword) async {
    Database db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // Memperbarui nama dan avatar profil pengguna
  Future<int> updateProfile(int userId, String name, String? avatar) async {
    Database db = await database;
    return await db.update(
      'users',
      {'name': name, 'avatar': avatar},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
