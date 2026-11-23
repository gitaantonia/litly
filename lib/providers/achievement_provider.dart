import 'package:flutter/material.dart';
import 'package:litly/services/achievement_service.dart';

// BARU: Provider untuk pengecekan pencapaian dan lencana
class AchievementProvider extends ChangeNotifier {
  final AchievementService _service = AchievementService();

  Future<void> checkAndShow(int userId) async {
    if (userId <= 0) return;
    await _service.checkAndUnlockAchievements(userId);
    notifyListeners();
  }
}
