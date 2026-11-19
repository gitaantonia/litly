import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_keys.dart';
import '../models/book.dart';

class GoogleBooksException implements Exception {
  const GoogleBooksException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleBooksService {
  GoogleBooksService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoint = 'https://www.googleapis.com/books/v1/volumes';
  static const _timeout = Duration(seconds: 10);

  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return [];
    return _request({'q': normalizedQuery, 'maxResults': '$limit'});
  }

  Future<List<Book>> recommendations(String subject) {
    return _request({
      'q': 'subject:$subject',
      'orderBy': 'relevance',
      'maxResults': '10',
    });
  }

  Future<List<Book>> _request(Map<String, String> parameters) async {
    final query = Map<String, String>.from(parameters);
    if (ApiKeys.googleBooks.isNotEmpty) {
      query['key'] = ApiKeys.googleBooks;
    }

    late final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(_endpoint).replace(queryParameters: query))
          .timeout(_timeout);
    } on TimeoutException {
      throw const GoogleBooksException(
        'Koneksi terlalu lama. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const GoogleBooksException(
        'Tidak dapat terhubung. Periksa koneksi internet kamu.',
      );
    }

    switch (response.statusCode) {
      case 200:
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final items = payload['items'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(_bookFromJson)
            .toList();
      case 400:
        throw const GoogleBooksException(
          'Pencarian tidak dapat diproses. Coba kata kunci lain.',
        );
      case 404:
        return [];
      case 429:
        throw const GoogleBooksException(
          'Batas pencarian sedang tercapai. Coba lagi sebentar.',
        );
      case 500:
        throw const GoogleBooksException(
          'Layanan buku sedang bermasalah. Coba lagi nanti.',
        );
      default:
        throw const GoogleBooksException(
          'Terjadi kendala saat memuat buku. Silakan coba lagi.',
        );
    }
  }

  Book _bookFromJson(Map<String, dynamic> json) {
    return Book.fromGoogleApi(json);
  }
}
