import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/services/notification_service.dart';

// Provider untuk pengaturan pengingat membaca dan streak saver
class SettingsProvider extends ChangeNotifier {
  // Konstanta jam streak saver (mudah diubah di satu tempat)
  static final int streakSaverHour = 22;
  static final int streakSaverMinute = 0;

  bool _dailyReminderEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 30;
  List<String> _reminderDays = ['1', '2', '3', '4', '5']; // Senin - Jumat
  bool _streakSaverEnabled = true;

  final NotificationService _notificationService = NotificationService();

  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  List<String> get reminderDays => _reminderDays;
  bool get streakSaverEnabled => _streakSaverEnabled;

  SettingsProvider() {
    loadSettings();
  }

  // Muat preferensi dari SharedPreferences
  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
    _reminderHour = prefs.getInt('reminder_hour') ?? 20;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 30;
    _reminderDays = prefs.getStringList('reminder_days') ?? ['1', '2', '3', '4', '5'];
    _streakSaverEnabled = prefs.getBool('streak_saver_enabled') ?? true;

    notifyListeners();
  }

  // Toggle status daily reading alarm
  Future<void> setDailyReminderEnabled(bool enabled) async {
    _dailyReminderEnabled = enabled;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);

    if (enabled) {
      List<int> days = _reminderDays.map((day) => int.parse(day)).toList();
      await _notificationService.scheduleDailyReminder(_reminderHour, _reminderMinute, days);
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }

  // Ubah jam pengingat harian
  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);

    if (_dailyReminderEnabled) {
      List<int> days = _reminderDays.map((day) => int.parse(day)).toList();
      await _notificationService.scheduleDailyReminder(hour, minute, days);
    }
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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminder_days', _reminderDays);

    if (_dailyReminderEnabled) {
      List<int> days = _reminderDays.map((d) => int.parse(d)).toList();
      await _notificationService.scheduleDailyReminder(_reminderHour, _reminderMinute, days);
    }

    return true;
  }

  // Toggle status streak saver alert
  Future<void> setStreakSaverEnabled(bool enabled) async {
    _streakSaverEnabled = enabled;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_saver_enabled', enabled);

    if (enabled) {
      await _notificationService.scheduleStreakSaver(streakSaverHour);
    } else {
      await _notificationService.cancelStreakSaver();
    }
  }
}
