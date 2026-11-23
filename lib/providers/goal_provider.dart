import 'package:flutter/material.dart';
import 'package:litly/services/goal_service.dart';
import 'package:litly/services/notification_service.dart';

// Titik pemicu perayaan target harian (checkGoalAndCelebrate):
// 1. Setelah penyimpanan sesi timer membaca di lib/screens/focus_timer.dart.
// 2. Saat pull-to-refresh di halaman AchievementScreen (Halaman A).
class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();

  // // ==========================================
  // // HAPUS SEBELUM DIKUMPULKAN: Debug mock data
  // // ==========================================
  bool isDebugData = false;

  void setDebugMockData() {
    isDebugData = true;
    _dailyPagesGoal = 20;
    _dailyMinutesGoal = 30;
    _monthlyGoal = 4;
    _annualGoal = 24;

    _todayPages = 15;
    _todayMinutes = 25;
    _monthCompleted = 3;
    _yearCompleted = 18; // 18 dari 24 = 75%
    notifyListeners();
  }
  // // ==========================================

  bool _isLoading = false;
  int _dailyPagesGoal = 0;
  int _dailyMinutesGoal = 0;
  int _monthlyGoal = 0;
  int _annualGoal = 0;

  int _todayPages = 0;
  int _todayMinutes = 0;
  int _monthCompleted = 0;
  int _yearCompleted = 0;

  List<BookItem> _monthBooks = [];
  List<BookItem> _yearBooks = [];

  bool get isLoading => _isLoading;
  int get dailyPagesGoal => _dailyPagesGoal;
  int get dailyMinutesGoal => _dailyMinutesGoal;
  int get monthlyGoal => _monthlyGoal;
  int get annualGoal => _annualGoal;

  int get todayPages => _todayPages;
  int get todayMinutes => _todayMinutes;
  int get monthCompleted => _monthCompleted;
  int get yearCompleted => _yearCompleted;

  List<BookItem> get monthBooks => _monthBooks;
  List<BookItem> get yearBooks => _yearBooks;

  // Cek apakah target harian sudah tercapai
  bool get isDailyReached {
    if (_dailyPagesGoal > 0) {
      return _todayPages >= _dailyPagesGoal;
    }
    if (_dailyMinutesGoal > 0) {
      return _todayMinutes >= _dailyMinutesGoal;
    }
    return false;
  }

  // Persentase capaian target harian (boleh lebih dari 100%)
  int get dailyPercent {
    if (_dailyPagesGoal > 0) {
      return (_todayPages * 100 / _dailyPagesGoal).round();
    }
    if (_dailyMinutesGoal > 0) {
      return (_todayMinutes * 100 / _dailyMinutesGoal).round();
    }
    return 0;
  }

  // Persentase capaian target bulanan (maksimal 100%)
  int get monthlyPercent {
    if (_monthlyGoal <= 0) return 0;
    int percent = (_monthCompleted * 100 / _monthlyGoal).round();
    if (percent > 100) return 100;
    return percent;
  }

  // Jumlah hari tersisa di bulan berjalan
  int get daysLeftInMonth {
    DateTime now = DateTime.now();
    int lastDay = DateTime(now.year, now.month + 1, 0).day;
    int diff = lastDay - now.day;
    if (diff < 0) return 0;
    return diff;
  }

  // Status tantangan tahunan ('On Track' atau 'Behind Schedule')
  String get yearStatus {
    if (_annualGoal <= 0) return 'On Track';

    DateTime now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    bool isLeap = (now.year % 4 == 0 && now.year % 100 != 0) || (now.year % 400 == 0);
    int totalDays = isLeap ? 366 : 365;

    double expected = (_annualGoal * dayOfYear) / totalDays;
    int expectedFloor = expected.floor();

    if (_yearCompleted >= expectedFloor) {
      return 'On Track';
    } else {
      return 'Behind Schedule';
    }
  }

  // Muat seluruh target dan data progres membaca
  Future<void> loadGoals(int userId) async {
    // // ==========================================
    // // HAPUS SEBELUM DIKUMPULKAN: Jangan timpa data debug
    // // ==========================================
    if (isDebugData) {
      return;
    }
    // // ==========================================

    _isLoading = true;
    notifyListeners();

    Map<String, int> goals = await _goalService.getGoals(userId);
    _dailyPagesGoal = goals['daily_pages'] ?? 0;
    _dailyMinutesGoal = goals['daily_minutes'] ?? 0;
    _monthlyGoal = goals['monthly_books'] ?? 0;
    _annualGoal = goals['annual_books'] ?? 0;

    _todayPages = await _goalService.getTodayPages(userId);
    _todayMinutes = await _goalService.getTodayMinutes(userId);
    _monthCompleted = await _goalService.getCompletedBooksThisMonth(userId);
    _yearCompleted = await _goalService.getCompletedBooksThisYear(userId);

    _monthBooks = await _goalService.getMonthBooks(userId);
    _yearBooks = await _goalService.getYearBooks(userId);

    _isLoading = false;
    notifyListeners();
  }

  // Simpan perubahan target membaca
  Future<String?> saveGoals(
    int userId,
    int dailyPages,
    int dailyMinutes,
    int monthlyBooks,
    int annualBooks,
  ) async {
    if (dailyPages < 0 || dailyMinutes < 0 || monthlyBooks < 0 || annualBooks < 0) {
      return 'Target tidak boleh bernilai negatif';
    }

    try {
      await _goalService.saveGoals(
        userId,
        dailyPages,
        dailyMinutes,
        monthlyBooks,
        annualBooks,
      );

      // Reset flag debug saat user menyimpan target baru secara riil
      isDebugData = false;

      await loadGoals(userId);
      return null;
    } catch (e) {
      return 'Gagal menyimpan target: ${e.toString()}';
    }
  }

  // Cek pencapaian target harian dan munculkan perayaan jika tercapai
  Future<void> checkGoalAndCelebrate(BuildContext context, int userId) async {
    await loadGoals(userId);

    if (isDailyReached) {
      DateTime now = DateTime.now();
      String todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String? celebratedDate = await _goalService.getCelebratedDate(userId);

      if (celebratedDate != todayStr) {
        await _goalService.setCelebratedDate(userId, todayStr);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Hebat! Target Harian Tercapai 🎉'),
            ),
          );
        }

        await NotificationService.instance.showGoalReached();
      }
    }
  }
}
