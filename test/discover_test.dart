import 'package:flutter_test/flutter_test.dart';
import 'package:litly/models/book.dart';

void main() {
  test('Book.fromGoogleApi should correctly parse volumeInfo from Google Books API', () {
    Map<String, dynamic> sampleGoogleBookJson = {
      'id': 'abc123volume',
      'volumeInfo': {
        'title': 'Thinking, Fast and Slow',
        'authors': ['Daniel Kahneman'],
        'publishedDate': '2011-10-25',
        'language': 'en',
        'description':
            'The profound duality between instinctive cognitive habits...',
        'pageCount': 499,
        'categories': ['Psychology'],
        'averageRating': 4.7,
        'imageLinks': {
          'smallThumbnail': 'http://books.google.com/books/content?id=abc123volume&printsec=frontcover&img=1&zoom=1&edge=curl',
          'thumbnail': 'http://books.google.com/books/content?id=abc123volume&printsec=frontcover&img=1&zoom=1&edge=curl',
        },
        'industryIdentifiers': [
          {'type': 'ISBN_13', 'identifier': '9780374533557'},
          {'type': 'ISBN_10', 'identifier': '0374533555'},
        ],
      },
    };

    Book book = Book.fromGoogleApi(sampleGoogleBookJson);

    expect(book.id, 'abc123volume');
    expect(book.title, 'Thinking, Fast and Slow');
    expect(book.author, 'Daniel Kahneman');
    expect(book.publishedYear, '2011');
    expect(book.language, 'en');
    expect(book.totalPages, 499);
    expect(book.category, 'Psychology');
    expect(book.rating, 4.7);
    expect(book.isbn, '9780374533557');
    // Cover URL is normalized for Google Books image delivery.
    expect(book.coverUrl, startsWith('https://'));
    expect(book.coverUrl, contains('zoom=2'));
    expect(book.coverUrl, isNot(contains('edge=curl')));
  });

  test('Book.fromGoogleApi handles missing optional fields gracefully', () {
    Map<String, dynamic> minimalBookJson = {
      'id': 'minimal123',
      'volumeInfo': {'title': 'Simple Book'},
    };

    Book book = Book.fromGoogleApi(minimalBookJson);

    expect(book.id, 'minimal123');
    expect(book.title, 'Simple Book');
    expect(book.author, 'Penulis Tidak Diketahui');
    expect(book.totalPages, 0);
    expect(Uri.parse(book.coverUrl!).queryParameters['id'], 'minimal123');
    expect(book.publishedYear, isNull);
    expect(book.language, isNull);
    expect(book.rating, isNull);
  });

  test('Book database mapping preserves the optional language', () {
    final book = Book(
      id: 'language-book',
      title: 'Novel',
      author: 'Writer',
      language: 'id',
      totalPages: 12,
      addedAt: DateTime(2026),
    );

    final restored = Book.fromDatabaseMap(book.toDatabaseMap());

    expect(restored.language, 'id');
  });
}
