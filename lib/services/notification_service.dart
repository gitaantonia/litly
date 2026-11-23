import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../database/db_helper.dart';
import 'book_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 100;
  static const int _streakSaverId = 200;
  static const int streakSaverHour = 22;
  static const int streakSaverMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('ic_stat_litly');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
    _isInitialized = true;
  }

  Future<void> syncFromSettings({bool requestPermissions = false}) async {
    _ensureInitialized();

    if (!_supportsScheduledReminders) {
      if (requestPermissions) {
        throw UnsupportedError(
          'Pengingat terjadwal hanya tersedia di Android dan iOS.',
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final dailyEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
    final streakSaverEnabled = prefs.getBool('streak_saver_enabled') ?? true;
    if (!dailyEnabled && !streakSaverEnabled) {
      await _cancelScheduledReminders();
      return;
    }

    if (requestPermissions && !await _requestPermissions()) {
      throw StateError(
        'Izin notifikasi atau alarm belum diberikan. Aktifkan izinnya agar pengingat bisa muncul.',
      );
    }

    final hour = prefs.getInt('reminder_hour') ?? 20;
    final minute = prefs.getInt('reminder_minute') ?? 30;
    final storedDays =
        prefs.getStringList('reminder_days') ??
        const ['1', '2', '3', '4', '5', '6', '7'];
    final days = storedDays.map(int.parse).toSet();
    if (dailyEnabled &&
        (days.isEmpty || days.any((day) => day < 1 || day > 7))) {
      throw StateError('Pilih minimal satu hari pengingat yang valid.');
    }

    final hasReadToday = await _hasReadToday();
    await _cancelScheduledReminders();

    if (dailyEnabled) {
      for (final weekday in days) {
        await _scheduleDailyReminder(
          weekday,
          hour,
          minute,
          skipToday: hasReadToday,
        );
      }
    }

    if (streakSaverEnabled) {
      await _scheduleStreakSaver(skipToday: hasReadToday);
    }
  }

  Future<void> _cancelScheduledReminders() async {
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(_dailyReminderId + weekday);
    }
    await _plugin.cancel(_streakSaverId);
  }

  Future<void> onReadingActivitySaved() async {
    await syncFromSettings();
  }

  Future<bool> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final notificationPermission = await android
          .requestNotificationsPermission();
      if (notificationPermission == false) return false;

      final exactAlarmPermission = await android.requestExactAlarmsPermission();
      return exactAlarmPermission != false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    throw UnsupportedError(
      'Izin pengingat terjadwal hanya tersedia di Android dan iOS.',
    );
  }

  Future<void> _scheduleDailyReminder(
    int weekday,
    int hour,
    int minute, {
    required bool skipToday,
  }) async {
    await _plugin.zonedSchedule(
      _dailyReminderId + weekday,
      'Waktunya Membaca!',
      'Kamu belum membaca hari ini. Luangkan waktu untuk membaca buku pilihanmu.',
      _nextWeeklyTime(weekday, hour, minute, skipToday: skipToday),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _scheduleStreakSaver({required bool skipToday}) async {
    await _plugin.zonedSchedule(
      _streakSaverId,
      'Jangan Biarkan Streak Padam!',
      'Kamu belum membaca hari ini. Luangkan 10 menit untuk membaca agar streak-mu tetap aman.',
      _nextDailyTime(streakSaverHour, streakSaverMinute, skipToday: skipToday),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'litly_reading_reminders',
      'Pengingat membaca',
      channelDescription: 'Pengingat rutin dan streak membaca Litly',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: 'ic_stat_litly',
      largeIcon: DrawableResourceAndroidBitmap('litly_logo'),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
  );

  timezone.TZDateTime _nextWeeklyTime(
    int weekday,
    int hour,
    int minute, {
    required bool skipToday,
  }) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday ||
        !scheduled.isAfter(now) ||
        (skipToday && _isSameDate(scheduled, now))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  timezone.TZDateTime _nextDailyTime(
    int hour,
    int minute, {
    required bool skipToday,
  }) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now) || skipToday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<bool> _hasReadToday() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final db = await DbHelper().database;
    final progress = await db.query(
      'reading_sessions',
      columns: ['id'],
      where: 'created_at LIKE ? AND end_page > start_page',
      whereArgs: ['$today%'],
      limit: 1,
    );
    if (progress.isNotEmpty) return true;

    return await BookService().getTodayPagesRead() > 0;
  }

  bool get _supportsScheduledReminders =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('NotificationService belum diinisialisasi.');
    }
  }

  bool _isSameDate(timezone.TZDateTime first, timezone.TZDateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
