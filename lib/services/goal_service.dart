import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:litly/database/db_helper.dart';

// Model sederhana untuk item buku pada daftar target membaca
class BookItem {
  final String title;
  final String? coverUrl;
  final int percent;
  final bool isCompleted;

  BookItem({
    required this.title,
    this.coverUrl,
    this.percent = 0,
    this.isCompleted = false,
  });
}

// Service untuk mengelola target membaca dan kalkulasi progres membaca
class GoalService {
  final DbHelper _dbHelper = DbHelper();

  // --- BAGIAN 1: PENYIMPANAN TARGET (SharedPreferences) ---

  // Ambil 4 target membaca pengguna
  Future<Map<String, int>> getGoals(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int dailyPages = prefs.getInt('goal_${userId}_daily_pages') ?? 0;
    int dailyMinutes = prefs.getInt('goal_${userId}_daily_minutes') ?? 0;
    int monthlyBooks = prefs.getInt('goal_${userId}_monthly_books') ?? 0;
    int annualBooks = prefs.getInt('goal_${userId}_annual_books') ?? 0;

    return {
      'daily_pages': dailyPages,
      'daily_minutes': dailyMinutes,
      'monthly_books': monthlyBooks,
      'annual_books': annualBooks,
    };
  }

  // Simpan 4 target membaca pengguna
  Future<void> saveGoals(
    int userId,
    int dailyPages,
    int dailyMinutes,
    int monthlyBooks,
    int annualBooks,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal_${userId}_daily_pages', dailyPages);
    await prefs.setInt('goal_${userId}_daily_minutes', dailyMinutes);
    await prefs.setInt('goal_${userId}_monthly_books', monthlyBooks);
    await prefs.setInt('goal_${userId}_annual_books', annualBooks);
  }

  // Ambil target tahunan saja (dipakai juga oleh halaman profil)
  Future<int> getAnnualGoal(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('goal_${userId}_annual_books') ?? 0;
  }

  // Ambil target halaman harian
  Future<int> getDailyPagesGoal(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('goal_${userId}_daily_pages') ?? 0;
  }

  // Ambil tanggal perayaan target harian terakhir
  Future<String?> getCelebratedDate(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('goal_${userId}_celebrated_date');
  }

  // Simpan tanggal perayaan target harian
  Future<void> setCelebratedDate(int userId, String dateStr) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('goal_${userId}_celebrated_date', dateStr);
  }

  // --- BAGIAN 2: PERHITUNGAN PROGRES DARI DATABASE ---

  // Total halaman yang dibaca hari ini.
  // Pilihan sumber: Menggunakan tabel reading_sessions karena tabel progress_log
  // belum tersedia di database. Kolom pages_read dijumlahkan untuk sesi hari ini.
  Future<int> getTodayPages(int userId) async {
    try {
      Database db = await _dbHelper.database;
      DateTime now = DateTime.now();
      String todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      List<Map<String, dynamic>> result = await db.query(
        'reading_sessions',
        where: 'created_at LIKE ?',
        whereArgs: ['$todayStr%'],
      );

      int totalPages = 0;
      for (var row in result) {
        int pages = (row['pages_read'] as num?)?.toInt() ?? 0;
        totalPages += pages;
      }
      return totalPages;
    } catch (e) {
      return 0;
    }
  }

  // Total durasi membaca hari ini dalam menit (duration_seconds / 60)
  Future<int> getTodayMinutes(int userId) async {
    try {
      Database db = await _dbHelper.database;
      DateTime now = DateTime.now();
      String todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      List<Map<String, dynamic>> result = await db.query(
        'reading_sessions',
        where: 'created_at LIKE ?',
        whereArgs: ['$todayStr%'],
      );

      int totalSeconds = 0;
      for (var row in result) {
        int seconds = (row['duration_seconds'] as num?)?.toInt() ?? 0;
        if (seconds == 0) {
          int minutes = (row['duration_minutes'] as num?)?.toInt() ?? 0;
          seconds = minutes * 60;
        }
        totalSeconds += seconds;
      }
      return totalSeconds ~/ 60;
    } catch (e) {
      return 0;
    }
  }

  // Jumlah buku berstatus 'Completed' di bulan dan tahun berjalan
  Future<int> getCompletedBooksThisMonth(int userId) async {
    try {
      Database db = await _dbHelper.database;
      DateTime now = DateTime.now();
      String yearMonthStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Cek apakah tabel books memiliki kolom completed_at atau memakai added_at
      List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM books 
        WHERE status = 'Completed' AND (
          (completed_at IS NOT NULL AND completed_at LIKE '$yearMonthStr%') OR 
          (added_at LIKE '$yearMonthStr%')
        )
      ''');

      if (result.isNotEmpty && result.first['count'] != null) {
        return (result.first['count'] as num).toInt();
      }
      return 0;
    } catch (e) {
      // Fallback jika kolom completed_at belum ada
      try {
        Database db = await _dbHelper.database;
        DateTime now = DateTime.now();
        String yearMonthStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';

        List<Map<String, dynamic>> fallback = await db.rawQuery('''
          SELECT COUNT(*) as count FROM books 
          WHERE status = 'Completed' AND added_at LIKE '$yearMonthStr%'
        ''');
        if (fallback.isNotEmpty && fallback.first['count'] != null) {
          return (fallback.first['count'] as num).toInt();
        }
      } catch (err) {
        return 0;
      }
      return 0;
    }
  }

  // Jumlah buku berstatus 'Completed' di tahun berjalan
  Future<int> getCompletedBooksThisYear(int userId) async {
    try {
      Database db = await _dbHelper.database;
      int currentYear = DateTime.now().year;

      List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM books 
        WHERE status = 'Completed' AND (
          (completed_at IS NOT NULL AND completed_at LIKE '$currentYear%') OR 
          (added_at LIKE '$currentYear%')
        )
      ''');

      if (result.isNotEmpty && result.first['count'] != null) {
        return (result.first['count'] as num).toInt();
      }
      return 0;
    } catch (e) {
      // Fallback jika query utama gagal
      try {
        Database db = await _dbHelper.database;
        int currentYear = DateTime.now().year;

        List<Map<String, dynamic>> fallback = await db.rawQuery('''
          SELECT COUNT(*) as count FROM books 
          WHERE status = 'Completed' AND added_at LIKE '$currentYear%'
        ''');
        if (fallback.isNotEmpty && fallback.first['count'] != null) {
          return (fallback.first['count'] as num).toInt();
        }
      } catch (err) {
        return 0;
      }
      return 0;
    }
  }

  // Daftar buku bulan ini (selesai bulan ini + sedang dibaca)
  Future<List<BookItem>> getMonthBooks(int userId) async {
    List<BookItem> books = [];
    try {
      Database db = await _dbHelper.database;
      DateTime now = DateTime.now();
      String yearMonthStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // 1. Ambil buku yang selesai bulan ini
      List<Map<String, dynamic>> completedRows = [];
      try {
        completedRows = await db.rawQuery('''
          SELECT title, cover_url, current_page, total_pages, status FROM books 
          WHERE status = 'Completed' AND (
            (completed_at IS NOT NULL AND completed_at LIKE '$yearMonthStr%') OR 
            (added_at LIKE '$yearMonthStr%')
          )
          ORDER BY added_at DESC
          LIMIT 10
        ''');
      } catch (e) {
        completedRows = await db.rawQuery('''
          SELECT title, cover_url, current_page, total_pages, status FROM books 
          WHERE status = 'Completed' AND added_at LIKE '$yearMonthStr%'
          ORDER BY added_at DESC
          LIMIT 10
        ''');
      }

      for (var row in completedRows) {
        books.add(BookItem(
          title: row['title'] as String? ?? 'Buku',
          coverUrl: row['cover_url'] as String?,
          percent: 100,
          isCompleted: true,
        ));
      }

      // 2. Ambil buku yang berstatus sedang dibaca (Currently Reading)
      int remainingSlots = 10 - books.length;
      if (remainingSlots > 0) {
        List<Map<String, dynamic>> readingRows = await db.rawQuery('''
          SELECT title, cover_url, current_page, total_pages, status FROM books 
          WHERE status != 'Completed'
          ORDER BY added_at DESC
          LIMIT $remainingSlots
        ''');

        for (var row in readingRows) {
          int current = (row['current_page'] as num?)?.toInt() ?? 0;
          int total = (row['total_pages'] as num?)?.toInt() ?? 1;
          int percent = 0;
          if (total > 0) {
            percent = (current * 100 / total).round();
          }

          books.add(BookItem(
            title: row['title'] as String? ?? 'Buku',
            coverUrl: row['cover_url'] as String?,
            percent: percent,
            isCompleted: false,
          ));
        }
      }

      return books;
    } catch (e) {
      return books;
    }
  }

  // Daftar buku yang selesai tahun ini (maksimal 10)
  Future<List<BookItem>> getYearBooks(int userId) async {
    List<BookItem> books = [];
    try {
      Database db = await _dbHelper.database;
      int currentYear = DateTime.now().year;

      List<Map<String, dynamic>> rows = [];
      try {
        rows = await db.rawQuery('''
          SELECT title, cover_url, current_page, total_pages FROM books 
          WHERE status = 'Completed' AND (
            (completed_at IS NOT NULL AND completed_at LIKE '$currentYear%') OR 
            (added_at LIKE '$currentYear%')
          )
          ORDER BY added_at DESC
          LIMIT 10
        ''');
      } catch (e) {
        rows = await db.rawQuery('''
          SELECT title, cover_url, current_page, total_pages FROM books 
          WHERE status = 'Completed' AND added_at LIKE '$currentYear%'
          ORDER BY added_at DESC
          LIMIT 10
        ''');
      }

      for (var row in rows) {
        books.add(BookItem(
          title: row['title'] as String? ?? 'Buku',
          coverUrl: row['cover_url'] as String?,
          percent: 100,
          isCompleted: true,
        ));
      }

      return books;
    } catch (e) {
      return books;
    }
  }
}
