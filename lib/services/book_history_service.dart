import 'package:sqflite/sqflite.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/book.dart';
import 'package:litly/models/reading_session.dart';
import 'package:litly/models/reading_session_item.dart';
import 'package:litly/services/book_service.dart';

// BARU: Service pengelola riwayat baca buku dan update progres membaca
class BookHistoryService {
  final DbHelper _dbHelper = DbHelper();
  final BookService _bookService = BookService();

  // Mengambil data satu buku berdasarkan id
  Future<Map<String, dynamic>?> getBook(int bookId) async {
    try {
      final allBooks = await _bookService.getBooks();
      for (final book in allBooks) {
        if (book.id == bookId.toString()) {
          return {
            'id': book.id,
            'title': book.title,
            'author': book.author,
            'coverUrl': book.coverUrl,
            'totalPages': book.totalPages,
            'currentPage': book.currentPage,
            'status': book.status,
            'completedAt': book.completedAt?.toIso8601String(),
          };
        }
      }

      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> rows = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [bookId.toString()],
        limit: 1,
      );

      if (rows.isEmpty) return null;

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
  Future<String?> saveProgress(
    int bookId,
    int newPage,
    int durationMinutes,
  ) async {
    try {
      Database db = await _dbHelper.database;
      final allBooks = await _bookService.getBooks();
      Book? book;
      for (final item in allBooks) {
        if (item.id == bookId.toString()) {
          book = item;
          break;
        }
      }

      final bookRows = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [bookId.toString()],
        limit: 1,
      );

      if (book == null && bookRows.isNotEmpty) {
        final row = bookRows.first;
        book = Book(
          id: row['id'] as String,
          title: row['title'] as String? ?? 'Tanpa Judul',
          author: row['author'] as String? ?? 'Penulis tidak diketahui',
          coverUrl: row['cover_url'] as String?,
          totalPages: (row['total_pages'] as num?)?.toInt() ?? 0,
          currentPage: (row['current_page'] as num?)?.toInt() ?? 0,
          status: row['status'] as String? ?? 'Want to Read',
          addedAt:
              DateTime.tryParse(row['added_at'] as String? ?? '') ??
              DateTime.now(),
          completedAt: DateTime.tryParse(row['completed_at'] as String? ?? ''),
        );
        await _bookService.addBook(book);
      }

      if (book == null) return 'Buku tidak ditemukan di koleksi.';

      final previousPage = book.currentPage;
      final totalPages = book.totalPages;
      final currentStatus = book.status;
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final nextStatus = totalPages > 0 && newPage >= totalPages
          ? 'Completed'
          : currentStatus.toLowerCase() == 'want to read' && newPage > 0
          ? 'Currently Reading'
          : currentStatus;
      final completedAt = nextStatus == 'Completed'
          ? book.completedAt?.toIso8601String() ?? nowIso
          : null;

      await db.transaction((txn) async {
        if (bookRows.isEmpty) {
          await txn.insert('books', {
            'id': book!.id,
            'title': book.title,
            'author': book.author,
            'cover_url': book.coverUrl,
            'total_pages': book.totalPages,
            'current_page': book.currentPage,
            'status': book.status,
            'added_at': book.addedAt.toIso8601String(),
            'completed_at': book.completedAt?.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (newPage > previousPage) {
          await txn.insert('reading_sessions', {
            'book_id': bookId.toString(),
            'duration_seconds': durationMinutes * 60,
            'start_page': previousPage,
            'end_page': newPage,
            'created_at': nowIso,
          });
        }

        final updateValues = <String, Object?>{
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

      if (newPage != previousPage) {
        await _bookService.updateBookProgress(
          bookId.toString(),
          newPage - previousPage,
        );
      }
      if (newPage > previousPage || durationMinutes > 0) {
        final pagesRead = (newPage - previousPage).clamp(0, newPage).toInt();
        await _bookService.addReadingSession(
          ReadingSession(
            id: 'progress_${bookId}_${now.microsecondsSinceEpoch}',
            bookId: bookId.toString(),
            bookTitle: book.title,
            durationMinutes: durationMinutes,
            durationSeconds: durationMinutes * 60,
            pagesRead: pagesRead,
            createdAt: now,
          ),
        );
      }

      return null;
    } catch (e) {
      return 'Gagal menyimpan progress: ${e.toString()}';
    }
  }
}
