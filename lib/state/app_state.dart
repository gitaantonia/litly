import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/book_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._bookService);

  final BookService _bookService;
  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  int _dataVersion = 0;

  List<Book> get books => List.unmodifiable(_books);
  bool get isLoading => _loading;
  String? get error => _error;
  int get dataVersion => _dataVersion;

  Future<void> loadBooks() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _books = await _bookService.getBooks();
    } on Exception {
      _error = 'Koleksi belum dapat dimuat. Silakan coba lagi.';
    } finally {
      _loading = false;
      _dataVersion++;
      notifyListeners();
    }
  }

  bool containsBook(String id) => _books.any((book) => book.id == id);

  Future<void> addBook(Book book) async {
    await _bookService.addBook(book);
    _books = [book, ..._books.where((item) => item.id != book.id)];
    _dataVersion++;
    notifyListeners();
  }

  Future<void> updateBook(Book book) async {
    await _bookService.updateBook(book);
    _books = _books.map((item) => item.id == book.id ? book : item).toList();
    _dataVersion++;
    notifyListeners();
  }

  Future<void> removeBook(String id) async {
    await _bookService.deleteBook(id);
    _books = _books.where((book) => book.id != id).toList();
    _dataVersion++;
    notifyListeners();
  }

  void notifyReadingActivityChanged() {
    _dataVersion++;
    notifyListeners();
  }
}
