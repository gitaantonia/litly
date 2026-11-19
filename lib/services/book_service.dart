import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

// Service untuk mengelola data buku lokal dan integrasi Google Books API v1
class BookService {
  static final String _booksKey = 'reading_books';
  static final String _usernameKey = 'username';

  // Base URL Google Books API v1
  static final String _googleBooksApiUrl = 'https://www.googleapis.com/books/v1/volumes';

  // ─── USERNAME (Disimpan dari anggota kelompok) ───────────────────────

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

  // ─── LOCAL BOOKS (Fitur Reading Tracker kelompok) ─────────────────────

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
