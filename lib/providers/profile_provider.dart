import 'package:flutter/material.dart';
import 'package:litly/services/achievement_service.dart';
import 'package:litly/services/goal_service.dart';

// Provider untuk data progres membaca dan lencana di halaman profil
class ProfileProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();
  final AchievementService _achievementService = AchievementService();

  int _completedBooks = 0;
  int _annualGoal = 0;
  List<Map<String, dynamic>> _recentBadges = [];
  bool _isLoading = false;

  int get completedBooks => _completedBooks;
  int get annualGoal => _annualGoal;
  List<Map<String, dynamic>> get recentBadges => _recentBadges;
  bool get isLoading => _isLoading;

  ProfileProvider() {
    loadProfileData();
  }

  // Mengambil target tahunan, buku selesai, dan lencana terbuka
  Future<void> loadProfileData([int userId = 0]) async {
    _isLoading = true;
    notifyListeners();

    // 1. Ambil target tahunan dari GoalService
    int goal = await _goalService.getAnnualGoal(userId);
    _annualGoal = goal;

    // 2. Ambil jumlah buku yang selesai tahun ini dari GoalService
    int completed = await _goalService.getCompletedBooksThisYear(userId);
    _completedBooks = completed;

    // 3. Periksa dan ambil lencana terbaru yang sudah terbuka
    await _achievementService.checkAndUnlockAchievements(userId);
    List<Map<String, dynamic>> badges =
        await _achievementService.getUserUnlockedAchievements(userId, limit: 4);
    _recentBadges = badges;

    _isLoading = false;
    notifyListeners();
  }
}
