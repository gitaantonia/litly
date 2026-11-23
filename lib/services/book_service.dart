import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_initializer.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import 'google_books_service.dart';

// Service untuk mengelola buku, sesi membaca, dan integrasi Google Books API
class BookService {
  BookService({GoogleBooksService? googleBooksService})
    : _googleBooksService = googleBooksService ?? GoogleBooksService();

  static final String _usernameKey = 'username';
  static final String _legacyBooksKey = 'reading_books';
  static final String _databaseName = 'litly.db';
  static final int _databaseVersion = 4;
  static final String _dailyTargetMinutesKey = 'daily_target_minutes';

  final GoogleBooksService _googleBooksService;
  Database? _database;

  // Inisialisasi dan pengambilan instance database SQLite
  Future<Database> get _db async {
    if (_database != null && _database!.isOpen) return _database!;
    final factory = litlyDatabaseFactory;
    String path;

    if (kIsWeb) {
      path = _databaseName;
    } else {
      final databasesPath = await factory.getDatabasesPath();
      path = p.join(databasesPath, _databaseName);
    }

    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await _createTables(db);
          // Migrasi data legacy dari SharedPreferences jika ada
          final prefs = await SharedPreferences.getInstance();
          final legacyBooks = prefs.getStringList(_legacyBooksKey) ?? [];
          if (legacyBooks.isNotEmpty) {
            final batch = db.batch();
            for (final encodedBook in legacyBooks) {
              final map = jsonDecode(encodedBook) as Map<String, dynamic>;
              batch.insert(
                'books',
                Book.fromMap(map).toDatabaseMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            await batch.commit(noResult: true);
            await prefs.remove(_legacyBooksKey);
          }
        },
        onOpen: (db) async {
          await _createTables(db);
          try {
            await db.execute('ALTER TABLE books ADD COLUMN published_year TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE books ADD COLUMN category TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE books ADD COLUMN language TEXT');
          } catch (_) {}
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createTables(db);
          if (oldVersion < 2) {
            try {
              await db.execute('ALTER TABLE books ADD COLUMN published_year TEXT');
              await db.execute('ALTER TABLE books ADD COLUMN category TEXT');
            } catch (_) {}
          }
          if (oldVersion < 4) {
            try {
              await db.execute('ALTER TABLE books ADD COLUMN language TEXT');
            } catch (_) {}
          }
        },
      ),
    );
    return _database!;
  }

  // Membuat tabel-tabel penting jika belum ada
  Future<void> _createTables(Database db) async {
    // 1. Tabel koleksi buku
    await db.execute('''
      CREATE TABLE IF NOT EXISTS books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_url TEXT,
        publisher TEXT,
        published_date TEXT,
        published_year TEXT,
        language TEXT,
        category TEXT,
        isbn TEXT,
        description TEXT,
        total_pages INTEGER NOT NULL,
        rating REAL,
        ratings_count INTEGER,
        status TEXT NOT NULL,
        current_page INTEGER NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel sesi membaca Focus Timer
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_sessions (
        id TEXT PRIMARY KEY,
        book_id TEXT,
        book_title TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        pages_read INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel target membaca harian
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_goals (
        date TEXT PRIMARY KEY,
        target_minutes INTEGER NOT NULL,
        completed_minutes INTEGER NOT NULL,
        completed_pages INTEGER NOT NULL
      )
    ''');
  }

  // --- PENGELOLAAN USERNAME ---
  Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> clearUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
  }

  // --- PENGELOLAAN KOLEKSI BUKU ---
  Future<List<Book>> getBooks() async {
    final db = await _db;
    final rows = await db.query('books', orderBy: 'added_at DESC');
    return rows
        .map((row) => Book.fromDatabaseMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> addBook(Book book) async {
    final db = await _db;
    await db.insert(
      'books',
      book.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBook(Book updated) async {
    final db = await _db;
    await db.update(
      'books',
      updated.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
  }

  Future<void> deleteBook(String id) async {
    final db = await _db;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Update progres halaman buku setelah sesi membaca
  Future<Book?> updateBookProgress(String bookId, int additionalPages) async {
    final db = await _db;
    final rows = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final currentBook = Book.fromDatabaseMap(Map<String, dynamic>.from(rows.first));
    final newPage = (currentBook.currentPage + additionalPages).clamp(
      0,
      currentBook.totalPages > 0 ? currentBook.totalPages : 99999,
    );

    final wasCompleted = currentBook.status.trim().toLowerCase() == 'completed';
    final newStatus = wasCompleted ||
            (currentBook.totalPages > 0 && newPage >= currentBook.totalPages)
        ? 'Completed'
        : 'Currently Reading';

    final updatedBook = Book(
      id: currentBook.id,
      title: currentBook.title,
      author: currentBook.author,
      coverUrl: currentBook.coverUrl,
      publisher: currentBook.publisher,
      publishedDate: currentBook.publishedDate,
      publishedYear: currentBook.publishedYear,
      language: currentBook.language,
      category: currentBook.category,
      isbn: currentBook.isbn,
      description: currentBook.description,
      totalPages: currentBook.totalPages,
      rating: currentBook.rating,
      ratingsCount: currentBook.ratingsCount,
      status: newStatus,
      currentPage: newPage,
      addedAt: currentBook.addedAt,
    );

    await updateBook(updatedBook);
    return updatedBook;
  }

  // --- PENGELOLAAN SESI MEMBACA FOCUS TIMER ---
  Future<void> addReadingSession(ReadingSession session) async {
    final db = await _db;
    await db.insert(
      'reading_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReadingSession>> getReadingSessions() async {
    final db = await _db;
    final rows = await db.query('reading_sessions', orderBy: 'created_at DESC');
    return rows.map((row) => ReadingSession.fromMap(row)).toList();
  }

  // Mengambil sesi membaca khusus hari ini
  Future<List<ReadingSession>> getTodayReadingSessions() async {
    final sessions = await getReadingSessions();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime.utc(now.year, now.month, now.day);
    return sessions
        .where((session) => session.readingDateInWib == today)
        .toList();
  }

  // Menghitung total detik membaca hari ini berdasarkan durasi timer
  Future<int> getTodayReadingSeconds() async {
    final sessions = await getTodayReadingSessions();
    return sessions.fold<int>(
      0,
      (total, session) => total + session.trackedDurationSeconds,
    );
  }

  // Menghitung total durasi membaca hari ini dalam menit
  Future<int> getTodayReadingMinutes() async {
    return (await getTodayReadingSeconds()) ~/ 60;
  }

  // Menghitung total halaman yang dibaca hari ini
  Future<int> getTodayPagesRead() async {
    final sessions = await getTodayReadingSessions();
    int totalPages = 0;
    for (final s in sessions) {
      totalPages += s.pagesRead;
    }
    return totalPages;
  }

  // --- PENGELOLAAN TARGET MEMBACA HARIAN (DAILY GOAL) ---
  Future<int> getDailyTargetMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyTargetMinutesKey) ?? 30; // Default 30 menit
  }

  Future<void> setDailyTargetMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyTargetMinutesKey, minutes);
  }

  // --- PENGELOLAAN TARGET MEMBACA TAHUNAN (ANNUAL READING GOAL) ---
  Future<int> getAnnualReadingGoal(int year) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('annual_reading_goal_$year') ?? 24; // Default 24 buku
  }

  Future<void> setAnnualReadingGoal(int year, int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('annual_reading_goal_$year', target);
  }

  // Mengambil riwayat sesi membaca dalam periode tertentu
  Future<List<ReadingSession>> getReadingSessionsForPeriod(DateTime start, DateTime end) async {
    final sessions = await getReadingSessions();
    return sessions.where((s) {
      final createdAt = s.createdAtInWib;
      return (createdAt.isAfter(start) || createdAt.isAtSameMomentAs(start)) &&
          (createdAt.isBefore(end) || createdAt.isAtSameMomentAs(end));
    }).toList();
  }

  // --- GOOGLE BOOKS SERVICE ---
  Future<List<Book>> searchGoogleBooks(
    String query, {
    int maxResults = 20,
  }) async {
    var formattedQuery = query.trim();
    if (formattedQuery.isEmpty) return [];
    final cleanIsbn = formattedQuery.replaceAll(RegExp(r'[-\s]'), '');
    if (RegExp(r'^[0-9Xx]+$').hasMatch(cleanIsbn) &&
        (cleanIsbn.length == 10 || cleanIsbn.length == 13)) {
      formattedQuery = 'isbn:$cleanIsbn';
    }
    return _googleBooksService.searchBooks(
      formattedQuery,
      limit: maxResults,
      languageCode: 'id',
    );
  }

  Future<List<Book>> fetchBooksByCategory(
    String category, {
    int maxResults = 40,
  }) {
    final normalizedCategory = category.trim();
    final query = switch (normalizedCategory.toLowerCase()) {
      'all' => 'book',
      'novel' => 'subject:fiction',
      'biografi' => 'subject:biography',
      'sains' => 'subject:science',
      'sejarah' => 'subject:history',
      _ => 'subject:"$normalizedCategory"',
    };
    return _googleBooksService.searchBooks(
      query,
      limit: maxResults,
      languageCode: 'id',
    );
  }
}
