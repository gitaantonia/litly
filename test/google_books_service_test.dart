import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:litly/services/book_service.dart';
import 'package:litly/services/google_books_service.dart';

void main() {
  group('GoogleBooksService', () {
    test('filters by the category supplied by Google Books', () async {
      final service = BookService(
        googleBooksService: GoogleBooksService(
          client: MockClient((request) async {
            expect(request.url.queryParameters['q'], 'subject:"Fiction"');
            expect(request.url.queryParameters['langRestrict'], 'id');
            expect(request.url.queryParameters['maxResults'], '40');
            return http.Response('{"items":[]}', 200);
          }),
        ),
      );

      expect(await service.fetchBooksByCategory('Fiction'), isEmpty);
    });

    test('starts with Indonesian books for the All category', () async {
      final service = BookService(
        googleBooksService: GoogleBooksService(
          client: MockClient((request) async {
            expect(request.url.queryParameters['q'], 'novel');
            expect(request.url.queryParameters['langRestrict'], 'id');
            return http.Response('{"items":[]}', 200);
          }),
        ),
      );

      expect(await service.fetchBooksByCategory('All'), isEmpty);
    });

    test('restricts book search to Indonesian language', () async {
      final service = BookService(
        googleBooksService: GoogleBooksService(
          client: MockClient((request) async {
            expect(request.url.queryParameters['q'], 'Dune');
            expect(request.url.queryParameters['langRestrict'], 'id');
            return http.Response('{"items":[]}', 200);
          }),
        ),
      );

      expect(await service.searchGoogleBooks('Dune'), isEmpty);
    });

    test('maps incomplete book data without failing', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'flutter');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'book-1',
                'volumeInfo': {'title': 'Flutter Basics'},
              },
            ],
          }),
          200,
        );
      });

      final books = await GoogleBooksService(client: client)
          .searchBooks('flutter');

      expect(books, hasLength(1));
      expect(books.single.title, 'Flutter Basics');
      expect(books.single.author, 'Penulis Tidak Diketahui');
      final coverUri = Uri.parse(books.single.coverUrl!);
      expect(coverUri.host, 'books.google.com');
      expect(coverUri.queryParameters['id'], 'book-1');
      expect(books.single.totalPages, 0);
    });

    test('returns an empty result for a not-found response', () async {
      final service = GoogleBooksService(
        client: MockClient((_) async => http.Response('', 404)),
      );

      expect(await service.searchBooks('unknown'), isEmpty);
    });

    test(
      'uses the small thumbnail when it is the only available cover',
      () async {
        final service = GoogleBooksService(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'items': [
                  {
                    'id': 'book-2',
                    'volumeInfo': {
                      'title': 'Small Cover',
                      'imageLinks': {
                        'smallThumbnail': 'http://books.example/cover.jpg',
                      },
                    },
                  },
                ],
              }),
              200,
            ),
          ),
        );

        final books = await service.searchBooks('small cover');

        expect(books.single.coverUrl, 'https://books.example/cover.jpg');
      },
    );

    test('provides a human-readable rate-limit error', () async {
      final service = GoogleBooksService(
        client: MockClient((_) async => http.Response('', 429)),
      );

      await expectLater(
        service.searchBooks('popular books'),
        throwsA(
          isA<GoogleBooksException>().having(
            (error) => error.message,
            'message',
            contains('Batas pencarian'),
          ),
        ),
      );
    });

    test('does not request the API for a blank search', () async {
      var requested = false;
      final service = GoogleBooksService(
        client: MockClient((_) async {
          requested = true;
          return http.Response('', 200);
        }),
      );

      expect(await service.searchBooks('   '), isEmpty);
      expect(requested, isFalse);
    });
  });
}
