import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/book.dart';

// Service untuk mengelola data buku lokal dan integrasi Google Books API v1
class BookService {
  static const _usernameKey = 'username';
  static const _legacyBooksKey = 'reading_books';
  static const _databaseName = 'litly.db';
  static const _databaseVersion = 1;
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            cover_url TEXT,
            publisher TEXT,
            published_date TEXT,
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
    );
    return _database!;
  }

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

<<<<<<< HEAD
  // ─── LOCAL BOOKS (Fitur Reading Tracker kelompok) ─────────────────────

=======
>>>>>>> 77451b8a04c578a1eaa747b4ca8c813759b3aaf4
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

  // ─── GOOGLE BOOKS API (PB-010 & PB-011) ──────────────────────────────

  /// PB-010: Pencarian buku berdasarkan judul, penulis, atau ISBN
  Future<List<Book>> searchGoogleBooks(String query, {int maxResults = 20}) async {
    String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return [];
    }

    // Mendeteksi apakah pencarian berupa ISBN (hanya angka/tanda hubung, panjang 10-13)
    String formattedQuery = cleanQuery;
    String cleanIsbn = cleanQuery.replaceAll('-', '').replaceAll(' ', '');
    bool isNumeric = RegExp(r'^[0-9Xx]+$').hasMatch(cleanIsbn);
    if (isNumeric && (cleanIsbn.length == 10 || cleanIsbn.length == 13)) {
      formattedQuery = 'isbn:$cleanIsbn';
    }

    Uri uri = Uri.parse(
      '$_googleBooksApiUrl?q=${Uri.encodeComponent(formattedQuery)}&maxResults=$maxResults&printType=books',
    );

    try {
      final response = await http.get(uri).timeout(Duration(seconds: 12));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List? items = data['items'] as List?;
        if (items == null || items.isEmpty) {
          return [];
        }

        return items
            .map((item) => Book.fromGoogleApi(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server mengembalikan kode status ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PB-011: Eksplorasi buku berdasarkan kategori menggunakan parameter subject
  Future<List<Book>> fetchBooksByCategory(String category, {int maxResults = 20}) async {
    String subjectQuery;

    // Pemetaan kategori sesuai pembagian tugas PB-011
    switch (category.toLowerCase()) {
      case 'fiction':
        subjectQuery = 'subject:fiction';
        break;
      case 'self-improvement':
        subjectQuery = 'subject:self-help+OR+subject:personal+development';
        break;
      case 'technology':
        subjectQuery = 'subject:computers+OR+subject:technology';
        break;
      case 'business':
        subjectQuery = 'subject:business+OR+subject:economics';
        break;
      case 'history':
        subjectQuery = 'subject:history';
        break;
      case 'psychology':
        subjectQuery = 'subject:psychology';
        break;
      case 'all':
      default:
        subjectQuery = 'subject:reading+OR+subject:literature+OR+subject:popular';
        break;
    }

    Uri uri = Uri.parse(
      '$_googleBooksApiUrl?q=$subjectQuery&maxResults=$maxResults&orderBy=relevance&printType=books',
    );

    try {
      final response = await http.get(uri).timeout(Duration(seconds: 12));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List? items = data['items'] as List?;
        if (items == null || items.isEmpty) {
          return [];
        }

        return items
            .map((item) => Book.fromGoogleApi(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server mengembalikan kode status ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
