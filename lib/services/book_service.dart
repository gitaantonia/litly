import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_initializer.dart';
import '../models/book.dart';
import 'google_books_service.dart';

class BookService {
  BookService({GoogleBooksService? googleBooksService})
    : _googleBooksService = googleBooksService ?? GoogleBooksService();

  static const _usernameKey = 'username';
  static const _legacyBooksKey = 'reading_books';
  static const _databaseName = 'litly.db';
  static const _databaseVersion = 2;
  final GoogleBooksService _googleBooksService;
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final factory = litlyDatabaseFactory;
    final path = p.join(await factory.getDatabasesPath(), _databaseName);
    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
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
            published_year TEXT,
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
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE books ADD COLUMN published_year TEXT',
            );
            await db.execute('ALTER TABLE books ADD COLUMN category TEXT');
          }
        },
      ),
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
    return _googleBooksService.searchBooks(formattedQuery, limit: maxResults);
  }

  Future<List<Book>> fetchBooksByCategory(
    String category, {
    int maxResults = 20,
  }) {
    final subject = switch (category.toLowerCase()) {
      'fiction' => 'fiction',
      'self-improvement' => 'self-help OR personal development',
      'technology' => 'computers OR technology',
      'business' => 'business OR economics',
      'history' => 'history',
      'psychology' => 'psychology',
      _ => 'reading OR literature OR popular',
    };
    return _googleBooksService.searchBooks(
      'subject:($subject)',
      limit: maxResults,
    );
  }
}
