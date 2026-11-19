import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class BookService {
  static const _booksKey = 'reading_books';
  static const _usernameKey = 'username';

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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_booksKey) ?? [];
    return raw
        .map((s) => Book.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = books.map((b) => jsonEncode(b.toMap())).toList();
    await prefs.setStringList(_booksKey, raw);
  }

  Future<void> addBook(Book book) async {
    final books = await getBooks();
    books.add(book);
    await saveBooks(books);
  }

  Future<void> updateBook(Book updated) async {
    final books = await getBooks();
    final idx = books.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      books[idx] = updated;
      await saveBooks(books);
    }
  }

  Future<void> deleteBook(String id) async {
    final books = await getBooks();
    books.removeWhere((b) => b.id == id);
    await saveBooks(books);
  }
}
