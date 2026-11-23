import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import 'book_service.dart';

class BookItem {
  final String title;
  final String? coverUrl;
  final int percent;
  final bool isCompleted;

  const BookItem({
    required this.title,
    this.coverUrl,
    this.percent = 0,
    this.isCompleted = false,
  });
}

class GoalService {
  GoalService({BookService? bookService})
    : _bookService = bookService ?? BookService();

  final BookService _bookService;

  Future<Map<String, int>> getGoals(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'daily_pages': prefs.getInt('goal_${userId}_daily_pages') ?? 0,
      'daily_minutes': prefs.getInt('goal_${userId}_daily_minutes') ?? 0,
      'monthly_books': prefs.getInt('goal_${userId}_monthly_books') ?? 0,
      'annual_books': prefs.getInt('goal_${userId}_annual_books') ?? 0,
    };
  }

  Future<void> saveGoals(
    int userId,
    int dailyPages,
    int dailyMinutes,
    int monthlyBooks,
    int annualBooks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal_${userId}_daily_pages', dailyPages);
    await prefs.setInt('goal_${userId}_daily_minutes', dailyMinutes);
    await prefs.setInt('goal_${userId}_monthly_books', monthlyBooks);
    await prefs.setInt('goal_${userId}_annual_books', annualBooks);
  }

  Future<int> getAnnualGoal(int userId) async {
    final goals = await getGoals(userId);
    return goals['annual_books'] ?? 0;
  }

  Future<int> getDailyPagesGoal(int userId) async {
    final goals = await getGoals(userId);
    return goals['daily_pages'] ?? 0;
  }

  Future<String?> getCelebratedDate(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('goal_${userId}_celebrated_date');
  }

  Future<void> setCelebratedDate(int userId, String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goal_${userId}_celebrated_date', dateStr);
  }

  Future<int> getTodayPages(int userId) async {
    final sessions = await _bookService.getTodayReadingSessions();
    return sessions.fold<int>(
      0,
      (total, session) => total + session.pagesRead,
    );
  }

  Future<int> getTodayMinutes(int userId) async {
    return (await _bookService.getTodayReadingSeconds()) ~/ 60;
  }

  Future<int> getCompletedBooksThisMonth(int userId) async {
    final now = _todayWib;
    final start = DateTime.utc(now.year, now.month);
    final end = DateTime.utc(now.year, now.month + 1);
    final books = await _bookService.getBooks();
    return books.where((book) => _completedInRange(book, start, end)).length;
  }

  Future<int> getCompletedBooksThisYear(int userId) async {
    final now = _todayWib;
    final start = DateTime.utc(now.year);
    final end = DateTime.utc(now.year + 1);
    final books = await _bookService.getBooks();
    return books.where((book) => _completedInRange(book, start, end)).length;
  }

  Future<List<BookItem>> getMonthBooks(int userId) async {
    final now = _todayWib;
    final start = DateTime.utc(now.year, now.month);
    final end = DateTime.utc(now.year, now.month + 1);
    final books = await _bookService.getBooks();
    final completedThisMonth = books
        .where((book) => _completedInRange(book, start, end))
        .map(_toBookItem);
    final unfinished = books
        .where((book) => !_isCompleted(book))
        .map(_toBookItem);

    return [...completedThisMonth, ...unfinished].take(10).toList();
  }

  Future<List<BookItem>> getUnfinishedBooks(int userId) async {
    final books = await _bookService.getBooks();
    return books.where((book) => !_isCompleted(book)).map(_toBookItem).toList();
  }

  Future<int> getGoalDaysStreak(int userId) async {
    final goals = await getGoals(userId);
    final pageTarget = goals['daily_pages'] ?? 0;
    final minuteTarget = goals['daily_minutes'] ?? 0;
    if (pageTarget <= 0 && minuteTarget <= 0) return 0;

    final sessions = await _bookService.getReadingSessions();
    final dailyPages = <DateTime, int>{};
    final dailySeconds = <DateTime, int>{};
    for (final session in sessions) {
      final date = session.readingDateInWib;
      dailyPages[date] = (dailyPages[date] ?? 0) + session.pagesRead;
      dailySeconds[date] =
          (dailySeconds[date] ?? 0) + session.trackedDurationSeconds;
    }

    bool metTarget(DateTime date) {
      if (pageTarget > 0) return (dailyPages[date] ?? 0) >= pageTarget;
      return (dailySeconds[date] ?? 0) ~/ 60 >= minuteTarget;
    }

    var checkDate = _todayWib;
    var streak = 0;
    if (!metTarget(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    while (metTarget(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool _completedInRange(Book book, DateTime start, DateTime end) {
    if (!_isCompleted(book)) return false;
    final completionDate = _toWib(book.completedAt ?? book.addedAt);
    return !completionDate.isBefore(start) && completionDate.isBefore(end);
  }

  bool _isCompleted(Book book) =>
      book.status.trim().toLowerCase() == 'completed';

  BookItem _toBookItem(Book book) {
    final percent = book.totalPages > 0
        ? (book.currentPage * 100 / book.totalPages)
              .round()
              .clamp(0, 100)
              .toInt()
        : 0;
    return BookItem(
      title: book.title,
      coverUrl: book.coverUrl,
      percent: percent,
      isCompleted: _isCompleted(book),
    );
  }

  DateTime get _todayWib {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime.utc(now.year, now.month, now.day);
  }

  DateTime _toWib(DateTime date) => date.toUtc().add(const Duration(hours: 7));
}
