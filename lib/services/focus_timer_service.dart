import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';

// Status jalannya timer fokus
enum FocusTimerStatus { initial, running, paused, completed }

// Layanan singleton untuk mengelola state dan jalannya Focus Timer
class FocusTimerService extends ChangeNotifier {
  static final FocusTimerService _instance = FocusTimerService._internal();

  factory FocusTimerService() {
    return _instance;
  }

  FocusTimerService._internal();

  // Durasi default 25 menit (1500 detik)
  int totalDurationSeconds = 25 * 60;
  int remainingSeconds = 25 * 60;
  FocusTimerStatus status = FocusTimerStatus.initial;

  // Catatan halaman yang dibaca dalam sesi ini
  int pagesRead = 0;

  // Buku yang sedang dibaca dalam sesi fokus
  Book? selectedBook;

  DateTime? _targetEndTime;
  Timer? _timer;

  // Cek apakah timer sedang aktif berjalan
  bool get isRunning => status == FocusTimerStatus.running;

  // Cek apakah timer sedang di-pause
  bool get isPaused => status == FocusTimerStatus.paused;

  // Progres waktu yang telah berjalan (0.0 sampai 1.0)
  double get timerProgress {
    if (totalDurationSeconds <= 0) return 0.0;
    return (1.0 - (remainingSeconds / totalDurationSeconds)).clamp(0.0, 1.0);
  }

  // Format sisa waktu ke bentuk string MM:SS
  String get formattedTime {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    String mStr = minutes.toString().padLeft(2, '0');
    String sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  // Durasi yang sudah dihabiskan dalam satuan menit
  int get elapsedMinutes {
    int spent = totalDurationSeconds - remainingSeconds;
    if (spent <= 0) return 1;
    int mins = (spent / 60).ceil();
    return mins.clamp(1, totalDurationSeconds ~/ 60);
  }

  // Memulai timer fokus (dilengkapi proteksi anti double-start)
  void startTimer() {
    if (status == FocusTimerStatus.running) return; // Mencegah timer ganda

    if (status == FocusTimerStatus.initial || status == FocusTimerStatus.completed) {
      remainingSeconds = totalDurationSeconds;
    }

    status = FocusTimerStatus.running;
    _targetEndTime = DateTime.now().add(Duration(seconds: remainingSeconds));

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_targetEndTime == null) return;
      int secLeft = _targetEndTime!.difference(DateTime.now()).inSeconds;

      if (secLeft <= 0) {
        remainingSeconds = 0;
        status = FocusTimerStatus.completed;
        _timer?.cancel();
        _timer = null;
      } else {
        remainingSeconds = secLeft;
      }
      notifyListeners();
    });

    notifyListeners();
  }

  // Menjeda jalannya timer
  void pauseTimer() {
    if (status != FocusTimerStatus.running) return;
    _timer?.cancel();
    _timer = null;
    status = FocusTimerStatus.paused;
    notifyListeners();
  }

  // Melanjutkan timer yang dijeda
  void resumeTimer() {
    if (status != FocusTimerStatus.paused) return;
    startTimer();
  }

  // Beralih antara start / pause
  void toggleTimer() {
    if (status == FocusTimerStatus.running) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  // Mereset timer ke durasi awal
  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    remainingSeconds = totalDurationSeconds;
    status = FocusTimerStatus.initial;
    pagesRead = 0;
    notifyListeners();
  }

  // Menyelesaikan timer secara manual
  void completeTimer() {
    _timer?.cancel();
    _timer = null;
    status = FocusTimerStatus.completed;
    notifyListeners();
  }

  // Mengubah durasi timer (hanya bisa jika timer tidak sedang berjalan)
  void setDuration(int minutes) {
    if (status == FocusTimerStatus.running) return;
    totalDurationSeconds = minutes * 60;
    remainingSeconds = totalDurationSeconds;
    status = FocusTimerStatus.initial;
    notifyListeners();
  }

  // Mengatur buku yang dipilih untuk sesi membaca
  void setSelectedBook(Book? book) {
    selectedBook = book;
    notifyListeners();
  }

  // Tambah jumlah halaman yang dibaca
  void incrementPages() {
    pagesRead++;
    notifyListeners();
  }

  // Kurangi jumlah halaman yang dibaca (minimal 0)
  void decrementPages() {
    if (pagesRead > 0) {
      pagesRead--;
      notifyListeners();
    }
  }

  // Reset sesi setelah disimpan
  void resetSessionAfterSave() {
    resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
