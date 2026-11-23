import 'package:sqflite/sqflite.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/services/goal_service.dart';

// Service untuk pencapaian dan lencana membaca pengguna (tabel achievements & user_achievements)
class AchievementService {
  final GoalService _goalService = GoalService();
  final DbHelper _dbHelper = DbHelper();

  // Pastikan user memiliki lencana awal jika baru pertama kali membaca
  Future<void> _ensureDefaultUserBadges(Database db, int userId) async {
    if (userId <= 0) return;
    try {
      List<Map<String, dynamic>> check = await db.query(
        'user_achievements',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (check.isEmpty) {
        String nowStr = DateTime.now().toIso8601String();
        // Berikan lencana awal untuk pengguna
        await db.insert('user_achievements', {
          'user_id': userId,
          'achievement_id': 'first_step',
          'unlocked_at': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        await db.insert('user_achievements', {
          'user_id': userId,
          'achievement_id': 'page_turner',
          'unlocked_at': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        await db.insert('user_achievements', {
          'user_id': userId,
          'achievement_id': 'goal_crusher',
          'unlocked_at': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      // Abaikan jika error
    }
  }

  // Mengambil lencana yang sudah terbuka khusus milik pengguna yang sedang aktif
  Future<List<Map<String, dynamic>>> getUserUnlockedAchievements(
    int userId, {
    int limit = 4,
  }) async {
    try {
      Database db = await _dbHelper.database;
      await _ensureDefaultUserBadges(db, userId);

      List<Map<String, dynamic>> rows = await db.rawQuery('''
        SELECT a.id, a.title, a.description, a.icon_name, ua.unlocked_at, 1 as is_unlocked
        FROM user_achievements ua
        JOIN achievements a ON ua.achievement_id = a.id
        WHERE ua.user_id = ?
        ORDER BY ua.unlocked_at DESC
        LIMIT ?
      ''', [userId, limit]);

      return rows;
    } catch (e) {
      return [];
    }
  }

  // Alias untuk kompatibilitas
  Future<List<Map<String, dynamic>>> getUnlockedAchievements({int limit = 4, int userId = 0}) async {
    return getUserUnlockedAchievements(userId, limit: limit);
  }

  // Mengambil seluruh master lencana beserta status terbuka/terkunci untuk user tertentu
  Future<List<Map<String, dynamic>>> getAllAchievementsWithStatus(int userId) async {
    try {
      Database db = await _dbHelper.database;
      await _ensureDefaultUserBadges(db, userId);

      List<Map<String, dynamic>> rows = await db.rawQuery('''
        SELECT a.id, a.title, a.description, a.icon_name, ua.unlocked_at,
               CASE WHEN ua.achievement_id IS NOT NULL THEN 1 ELSE 0 END as is_unlocked
        FROM achievements a
        LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = ?
        ORDER BY is_unlocked DESC, a.id ASC
      ''', [userId]);

      return rows;
    } catch (e) {
      return [];
    }
  }

  // Periksa progres dan buka lencana baru jika syarat terpenuhi
  Future<void> checkAndUnlockAchievements(int userId) async {
    if (userId <= 0) return;

    try {
      Database db = await _dbHelper.database;
      await _ensureDefaultUserBadges(db, userId);
      String nowStr = DateTime.now().toIso8601String();

      // 1. Cek jumlah buku selesai untuk lencana 'bookworm'
      List<Map<String, dynamic>> completedBooks = await db.rawQuery(
        "SELECT COUNT(*) as count FROM books WHERE status = 'Completed'",
      );
      int count = (completedBooks.first['count'] as num?)?.toInt() ?? 0;
      if (count >= 1) {
        await db.insert('user_achievements', {
          'user_id': userId,
          'achievement_id': 'bookworm',
          'unlocked_at': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // 2. Cek total durasi sesi untuk lencana 'marathon_reader'
      List<Map<String, dynamic>> sessions = await db.rawQuery(
        'SELECT MAX(duration_minutes) as max_dur FROM reading_sessions',
      );
      int maxDur = (sessions.first['max_dur'] as num?)?.toInt() ?? 0;
      if (maxDur >= 60) {
        await db.insert('user_achievements', {
          'user_id': userId,
          'achievement_id': 'marathon_reader',
          'unlocked_at': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      // Abaikan jika error
    }
  }

  // Menghitung metrik goal_days_streak (lencana Goal Crusher)
  Future<int> getGoalDaysStreak(int userId) async {
    int targetPages = await _goalService.getDailyPagesGoal(userId);
    if (targetPages <= 0) {
      return 0; // Target belum diatur
    }

    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> sessions = await db.query(
        'reading_sessions',
        orderBy: 'created_at DESC',
      );

      Map<String, int> dailyPagesMap = {};
      for (var s in sessions) {
        String createdAt = s['created_at'] as String? ?? '';
        if (createdAt.length >= 10) {
          String dateKey = createdAt.substring(0, 10);
          int pages = (s['pages_read'] as num?)?.toInt() ?? 0;
          dailyPagesMap[dateKey] = (dailyPagesMap[dateKey] ?? 0) + pages;
        }
      }

      int streak = 0;
      DateTime checkDate = DateTime.now();

      String todayKey =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      int todayPages = dailyPagesMap[todayKey] ?? 0;

      if (todayPages >= targetPages) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else {
        checkDate = checkDate.subtract(Duration(days: 1));
      }

      while (true) {
        String dateKey =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        int pages = dailyPagesMap[dateKey] ?? 0;
        if (pages >= targetPages) {
          streak++;
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }
}
