import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/book.dart';

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

  // ─── USERNAME ───────────────────────────────────────────

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

  // ─── BOOKS ──────────────────────────────────────────────

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
}
