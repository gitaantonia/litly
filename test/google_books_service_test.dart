import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:litly/services/google_books_service.dart';

void main() {
  group('GoogleBooksService', () {
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
      expect(books.single.coverUrl, isNull);
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
