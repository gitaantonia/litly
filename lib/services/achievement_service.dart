import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';
import '../models/reading_session.dart';
import 'book_service.dart';
import 'goal_service.dart';

class AchievementService {
  AchievementService({
    BookService? bookService,
    GoalService? goalService,
    DbHelper? dbHelper,
  }) : _bookService = bookService ?? BookService(),
       _goalService = goalService ?? GoalService(),
       _dbHelper = dbHelper ?? DbHelper();

  final BookService _bookService;
  final GoalService _goalService;
  final DbHelper _dbHelper;

  Future<List<Map<String, dynamic>>> getUserUnlockedAchievements(
    int userId, {
    int limit = 4,
  }) async {
    if (userId <= 0) return [];
    final db = await _dbHelper.database;
    return db.rawQuery(
      '''
      SELECT a.id, a.title, a.description, a.icon_name, ua.unlocked_at,
             1 as is_unlocked
      FROM user_achievements ua
      JOIN achievements a ON ua.achievement_id = a.id
      WHERE ua.user_id = ?
      ORDER BY ua.unlocked_at DESC
      LIMIT ?
    ''',
      [userId, limit],
    );
  }

  Future<List<Map<String, dynamic>>> getUnlockedAchievements({
    int limit = 4,
    int userId = 0,
  }) {
    return getUserUnlockedAchievements(userId, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getAllAchievementsWithStatus(
    int userId,
  ) async {
    final db = await _dbHelper.database;
    return db.rawQuery(
      '''
      SELECT a.id, a.title, a.description, a.icon_name, ua.unlocked_at,
             CASE WHEN ua.achievement_id IS NOT NULL THEN 1 ELSE 0 END
               as is_unlocked
      FROM achievements a
      LEFT JOIN user_achievements ua
        ON a.id = ua.achievement_id AND ua.user_id = ?
      ORDER BY is_unlocked DESC, a.id ASC
    ''',
      [userId],
    );
  }

  Future<void> checkAndUnlockAchievements(int userId) async {
    if (userId <= 0) return;

    final db = await _dbHelper.database;
    final sessions = await _bookService.getReadingSessions();
    final books = await _bookService.getBooks();
    final goals = await _goalService.getGoals(userId);
    final now = DateTime.now();
    final sessionsByDay = <DateTime, List<ReadingSession>>{};

    for (final session in sessions) {
      sessionsByDay
          .putIfAbsent(session.readingDateInWib, () => [])
          .add(session);
    }

    Future<void> unlock(String achievementId) async {
      await db.insert('user_achievements', {
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final hasRead = sessions.any(
      (session) => session.pagesRead > 0 || session.trackedDurationSeconds > 0,
    );
    if (hasRead) await unlock('first_step');

    final pageTarget = goals['daily_pages'] ?? 0;
    final pageThreshold = pageTarget > 0 ? pageTarget : 20;
    final reachedPageTarget = sessionsByDay.values.any(
      (daySessions) =>
          daySessions.fold<int>(0, (total, s) => total + s.pagesRead) >=
          pageThreshold,
    );
    if (reachedPageTarget) await unlock('page_turner');

    if (await _goalService.getGoalDaysStreak(userId) >= 3) {
      await unlock('goal_crusher');
    }

    final completedBooks = books
        .where((book) => book.status.trim().toLowerCase() == 'completed')
        .length;
    if (completedBooks > 0) await unlock('bookworm');

    if (sessions.any((session) {
      final hour = session.createdAtInWib.hour;
      return hour >= 20 || hour < 4;
    })) {
      await unlock('night_owl');
    }

    if (sessions.any((session) => session.trackedDurationSeconds >= 3600)) {
      await unlock('marathon_reader');
    }

    final monthlyGoal = goals['monthly_books'] ?? 0;
    if (monthlyGoal > 0 &&
        await _goalService.getCompletedBooksThisMonth(userId) >= monthlyGoal) {
      await unlock('monthly_champ');
    }

    final annualGoal = goals['annual_books'] ?? 0;
    if (annualGoal > 0 &&
        await _goalService.getCompletedBooksThisYear(userId) >= annualGoal) {
      await unlock('year_champ');
    }
  }
}
