import 'package:flutter/foundation.dart';
import 'package:litly/models/reading_session_item.dart';
import 'package:litly/services/book_history_service.dart';

// BARU: Provider untuk state riwayat baca satu buku dan update progress
class BookHistoryProvider extends ChangeNotifier {
  final BookHistoryService _historyService = BookHistoryService();

  bool isLoading = true;
  Map<String, dynamic>? book;
  List<ReadingSessionItem> sessions = [];

  // Flag apakah sedang menggunakan data contoh debug
  bool isDebugData = false;

  // Memuat data buku dan seluruh sesi bacaannya
  Future<void> loadHistory(int bookId) async {
    // Kalau sedang pakai data contoh debug, jangan timpa
    if (isDebugData) {
      return;
    }

    isLoading = true;
    notifyListeners();

    Map<String, dynamic>? loadedBook = await _historyService.getBook(bookId);
    List<ReadingSessionItem> loadedSessions = await _historyService.getSessions(bookId);

    book = loadedBook;
    sessions = loadedSessions;
    isLoading = false;
    notifyListeners();
  }

  // Getter persentase progress membaca buku (0 - 100%)
  int get progressPercent {
    if (book == null) return 0;
    int total = (book!['totalPages'] as num?)?.toInt() ?? 0;
    int current = (book!['currentPage'] as num?)?.toInt() ?? 0;
    if (total <= 0) return 0;

    int percent = ((current * 100) / total).round();
    if (percent > 100) {
      return 100;
    }
    return percent;
  }

  // Getter sisa halaman yang belum dibaca
  int get pagesLeft {
    if (book == null) return 0;
    int total = (book!['totalPages'] as num?)?.toInt() ?? 0;
    int current = (book!['currentPage'] as num?)?.toInt() ?? 0;
    int left = total - current;
    if (left < 0) {
      return 0;
    }
    return left;
  }

  // Getter total jumlah semua sesi membaca
  int get sessionCount {
    return sessions.length;
  }

  // Getter estimasi waktu tersisa untuk menyelesaikan buku
  String get timeLeftText {
    if (pagesLeft <= 0) {
      return 'Done';
    }

    // Ambil sesi yang memiliki durasi > 0 dan halaman > 0
    int totalMinutes = 0;
    int totalPages = 0;

    for (var s in sessions) {
      if (s.durationSeconds > 0 && s.pagesRead > 0) {
        totalMinutes += s.durationMinutes;
        totalPages += s.pagesRead;
      }
    }

    if (totalMinutes <= 0 || totalPages <= 0) {
      return '—';
    }

    double avgMinutesPerPage = totalMinutes / totalPages;
    int menitSisa = (pagesLeft * avgMinutesPerPage).round();

    if (menitSisa <= 0) {
      return 'Done';
    }

    if (menitSisa < 60) {
      return '~$menitSisa m left';
    }

    int hours = menitSisa ~/ 60;
    int mins = menitSisa % 60;
    if (mins == 0) {
      return '~${hours}h left';
    }
    return '~${hours}h ${mins}m left';
  }

  // Getter maksimal 10 sesi terbaru untuk timeline
  List<ReadingSessionItem> get recentSessions {
    if (sessions.length <= 10) {
      return sessions;
    }
    return sessions.sublist(0, 10);
  }

  // Simpan progres bacaan baru lewat service atau di memori jika debug
  Future<String?> saveProgress({
    required int bookId,
    required int newPage,
    required int durationMinutes,
  }) async {
    if (isDebugData) {
      // Ubah data di memori saja saat mode debug
      int prevPage = (book?['currentPage'] as num?)?.toInt() ?? 0;
      int totalPages = (book?['totalPages'] as num?)?.toInt() ?? 198;

      String nextStatus = book?['status'] ?? 'Currently Reading';
      if (newPage >= totalPages) {
        nextStatus = 'Completed';
      }

      book = {
        'id': bookId,
        'title': book?['title'] ?? 'Infinite Country',
        'author': book?['author'] ?? 'Patricia Engel',
        'coverUrl': book?['coverUrl'],
        'totalPages': totalPages,
        'currentPage': newPage,
        'status': nextStatus,
        'completedAt': newPage >= totalPages ? DateTime.now().toIso8601String() : null,
      };

      if (newPage > prevPage) {
        ReadingSessionItem newSession = ReadingSessionItem(
          id: sessions.length + 1,
          startPage: prevPage,
          endPage: newPage,
          durationSeconds: durationMinutes * 60,
          createdAt: DateTime.now(),
        );
        sessions = [newSession, ...sessions];
      }

      notifyListeners();
      return null;
    }

    String? error = await _historyService.saveProgress(bookId, newPage, durationMinutes);
    if (error == null) {
      await loadHistory(bookId);
    }
    return error;
  }

  // ============================================================
  // // HAPUS SEBELUM DIKUMPULKAN: Fungsi Mock Data Debug
  // ============================================================
  void setDebugMockData() {
    isDebugData = true;
    isLoading = false;

    // Buku contoh sesuai gambar: Infinite Country oleh Patricia Engel
    book = {
      'id': 999,
      'title': 'Infinite Country',
      'author': 'Patricia Engel',
      'coverUrl': null, // Pakai placeholder pastel
      'totalPages': 198,
      'currentPage': 124,
      'status': 'Currently Reading',
      'completedAt': null,
    };

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day, 14, 20);
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1, 20, 15);
    DateTime twoDaysAgo = DateTime(now.year, now.month, now.day - 2, 18, 40);

    sessions = [
      ReadingSessionItem(
        id: 1,
        startPage: 100,
        endPage: 124, // +24 pgs
        durationSeconds: 28 * 60, // 28m duration
        createdAt: today, // Hari ini, 14:20
      ),
      ReadingSessionItem(
        id: 2,
        startPage: 82,
        endPage: 100, // +18 pgs
        durationSeconds: 22 * 60, // 22m duration
        createdAt: yesterday, // Kemarin, 20:15
      ),
      ReadingSessionItem(
        id: 3,
        startPage: 67,
        endPage: 82, // +15 pgs
        durationSeconds: 19 * 60, // 19m duration
        createdAt: twoDaysAgo, // 2 hari lalu, 18:40
      ),
    ];

    notifyListeners();
  }
}
