import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/services/notification_service.dart';

// Provider untuk pengaturan pengingat membaca dan streak saver
class SettingsProvider extends ChangeNotifier {
  // Konstanta jam streak saver (mudah diubah di satu tempat)
  static const int streakSaverHour = NotificationService.streakSaverHour;
  static const int streakSaverMinute = NotificationService.streakSaverMinute;

  bool _dailyReminderEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 30;
  List<String> _reminderDays = ['1', '2', '3', '4', '5', '6', '7'];
  bool _streakSaverEnabled = true;

  final NotificationService _notificationService = NotificationService.instance;

  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  List<String> get reminderDays => _reminderDays;
  bool get streakSaverEnabled => _streakSaverEnabled;

  SettingsProvider() {
    loadSettings();
  }

  // Muat pengaturan pengingat dari SharedPreferences
  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
    _reminderHour = prefs.getInt('reminder_hour') ?? 20;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 30;
    _reminderDays =
        prefs.getStringList('reminder_days') ??
        ['1', '2', '3', '4', '5', '6', '7'];
    _streakSaverEnabled = prefs.getBool('streak_saver_enabled') ?? true;

    notifyListeners();
  }

  void setDailyReminderEnabled(bool enabled) {
    _dailyReminderEnabled = enabled;
    notifyListeners();
  }

  void setReminderTime(int hour, int minute) {
    _reminderHour = hour;
    _reminderMinute = minute;
    notifyListeners();
  }

  // Toggle pilihan hari (M T W T F S S). Mengembalikan false jika mencoba mematikan hari terakhir.
  Future<bool> toggleReminderDay(String day) async {
    List<String> updatedDays = List<String>.from(_reminderDays);

    if (updatedDays.contains(day)) {
      if (updatedDays.length <= 1) {
        // Minimal 1 hari harus terpilih
        return false;
      }
      updatedDays.remove(day);
    } else {
      updatedDays.add(day);
      updatedDays.sort();
    }

    _reminderDays = updatedDays;
    notifyListeners();

    return true;
  }

  void setStreakSaverEnabled(bool enabled) {
    _streakSaverEnabled = enabled;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setInt('reminder_hour', _reminderHour);
    await prefs.setInt('reminder_minute', _reminderMinute);
    await prefs.setStringList('reminder_days', _reminderDays);
    await prefs.setBool('streak_saver_enabled', _streakSaverEnabled);
    await _notificationService.syncFromSettings(requestPermissions: true);
  }
}
