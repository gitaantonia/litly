import 'package:sqflite/sqflite.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/reading_session_item.dart';
import 'package:litly/services/book_service.dart';

// BARU: Service pengelola riwayat baca buku dan update progres membaca
class BookHistoryService {
  final DbHelper _dbHelper = DbHelper();
  final BookService _bookService = BookService();

  // Mengambil data satu buku berdasarkan id
  Future<Map<String, dynamic>?> getBook(int bookId) async {
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> rows = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [bookId.toString()],
        limit: 1,
      );

      // Jika belum ditemukan di DbHelper, cek di BookService
      if (rows.isEmpty) {
        var allBooks = await _bookService.getBooks();
        for (var b in allBooks) {
          if (b.id == bookId.toString()) {
            return {
              'id': b.id,
              'title': b.title,
              'author': b.author,
              'coverUrl': b.coverUrl,
              'totalPages': b.totalPages,
              'currentPage': b.currentPage,
              'status': b.status,
              'completedAt': null,
            };
          }
        }
        return null;
      }

      Map<String, dynamic> row = rows.first;
      int total = (row['total_pages'] as num?)?.toInt() ?? 0;
      int current = (row['current_page'] as num?)?.toInt() ?? 0;

      return {
        'id': row['id'],
        'title': row['title'] ?? 'Tanpa Judul',
        'author': row['author'] ?? 'Penulis tidak diketahui',
        'coverUrl': row['cover_url'],
        'totalPages': total,
        'currentPage': current,
        'status': row['status'] ?? 'Want to Read',
        'completedAt': row['completed_at'],
      };
    } catch (e) {
      return null;
    }
  }

  // Mengambil daftar sesi membaca untuk buku tertentu urut terbaru
  Future<List<ReadingSessionItem>> getSessions(int bookId) async {
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> rows = await db.query(
        'reading_sessions',
        where: 'book_id = ? AND end_page > start_page',
        whereArgs: [bookId.toString()],
        orderBy: 'created_at DESC',
      );

      List<ReadingSessionItem> sessions = [];
      for (var row in rows) {
        sessions.add(ReadingSessionItem.fromMap(row));
      }
      return sessions;
    } catch (e) {
      return [];
    }
  }

  // Menyimpan progres bacaan baru dan mencatat sesi ke dalam SQLite
  Future<String?> saveProgress(int bookId, int newPage, int durationMinutes) async {
    try {
      Database db = await _dbHelper.database;

      // 1. Ambil data buku saat ini
      List<Map<String, dynamic>> bookRows = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [bookId.toString()],
        limit: 1,
      );

      int previousPage = 0;
      int totalPages = 0;
      String currentStatus = 'Want to Read';

      if (bookRows.isNotEmpty) {
        var b = bookRows.first;
        previousPage = (b['current_page'] as num?)?.toInt() ?? 0;
        totalPages = (b['total_pages'] as num?)?.toInt() ?? 0;
        currentStatus = b['status'] as String? ?? 'Want to Read';
      } else {
        // Cek fallback di BookService jika buku terdaftar di sana
        var allBooks = await _bookService.getBooks();
        for (var item in allBooks) {
          if (item.id == bookId.toString()) {
            previousPage = item.currentPage;
            totalPages = item.totalPages;
            currentStatus = item.status;
            // Salin buku ke tabel books DbHelper agar transaksi berjalan lancar
            await db.insert('books', {
              'id': item.id,
              'title': item.title,
              'author': item.author,
              'cover_url': item.coverUrl,
              'total_pages': item.totalPages,
              'current_page': item.currentPage,
              'status': item.status,
              'added_at': DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            break;
          }
        }
      }

      String nowIso = DateTime.now().toIso8601String();

      // 6. Jalankan seluruh operasi dalam satu transaksi database
      await db.transaction((txn) async {
        // 2. Jika newPage > previousPage: simpan satu baris di reading_sessions
        if (newPage > previousPage) {
          int durationSec = durationMinutes * 60;
          await txn.insert('reading_sessions', {
            'book_id': bookId.toString(),
            'duration_seconds': durationSec,
            'start_page': previousPage,
            'end_page': newPage,
            'created_at': nowIso,
          });
        }

        // Tentukan status buku baru
        String nextStatus = currentStatus;
        String? completedAt;

        // 4. Kalau status buku 'Want to Read' dan newPage > 0: ubah ke 'Currently Reading'
        if (currentStatus == 'Want to Read' && newPage > 0) {
          nextStatus = 'Currently Reading';
        }

        // 5. Kalau newPage == total_pages: ubah status ke 'Completed' dan isi completed_at
        if (totalPages > 0 && newPage >= totalPages) {
          nextStatus = 'Completed';
          completedAt = nowIso;
        }

        // 3. Update data pada tabel books
        Map<String, dynamic> updateValues = {
          'current_page': newPage,
          'status': nextStatus,
        };
        if (completedAt != null) {
          updateValues['completed_at'] = completedAt;
        }

        await txn.update(
          'books',
          updateValues,
          where: 'id = ?',
          whereArgs: [bookId.toString()],
        );
      });

      // Sinkronkan juga ke BookService jika ada untuk AppState
      try {
        await _bookService.updateBookProgress(bookId.toString(), newPage - previousPage);
      } catch (_) {}

      return null; // Sukses tanpa error
    } catch (e) {
      return 'Gagal menyimpan progress: ${e.toString()}';
    }
  }
}
