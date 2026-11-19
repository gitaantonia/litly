// Model data buku untuk aplikasi Litly
class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? publisher;
  final String? publishedDate;
  final String? isbn;
  final String? description;
  final int totalPages;
  final double? rating;
  final int? ratingsCount;
  String status;
  int currentPage;
  final DateTime addedAt;

  // Field tambahan dari Google Books API (PB-010 & PB-011)
  final String? description;
  final double? rating;
  final String? isbn;

  Book({
    required this.id,
    required this.author,
    this.coverUrl,
    this.publisher,
    this.publishedDate,
    this.isbn,
    this.description,
    required this.totalPages,
    this.rating,
    this.ratingsCount,
    this.status = 'Want to Read',
    this.currentPage = 0,
    required this.addedAt,
    this.publishedYear,
    this.category,
    this.description,
    this.rating,
    this.isbn,
  });

  /// Persentase progress membaca (0.0 – 1.0)
  double get progress =>
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  /// Persentase dalam bentuk teks, misal "42%"
  String get progressText => '${(progress * 100).round()}%';

  bool get isFinished => currentPage >= totalPages && totalPages > 0;

  // Konversi dari/ke Map untuk disimpan di shared_preferences (kompatibel anggota kelompok)
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'addedAt': addedAt.toIso8601String(),
        'publishedYear': publishedYear,
        'category': category,
        'description': description,
        'rating': rating,
        'isbn': isbn,
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        title: map['title'] as String,
        author: map['author'] as String,
        coverUrl: map['coverUrl'] as String?,
        totalPages: map['totalPages'] as int? ?? 0,
        currentPage: map['currentPage'] as int? ?? 0,
        addedAt: DateTime.parse(map['addedAt'] as String),
        publishedYear: map['publishedYear'] as String?,
        category: map['category'] as String?,
        description: map['description'] as String?,
        rating: (map['rating'] as num?)?.toDouble(),
        isbn: map['isbn'] as String?,
      );

  // Factory untuk memetakan respon item dari Google Books API v1
  factory Book.fromGoogleApi(Map<String, dynamic> item) {
    Map<String, dynamic> volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? {};

    // 1. Ekstrak thumbnail cover dan pastikan menggunakan HTTPS
    String? thumbnail;
    if (volumeInfo['imageLinks'] != null) {
      Map<String, dynamic> images = volumeInfo['imageLinks'] as Map<String, dynamic>;
      thumbnail = images['thumbnail'] as String? ?? images['smallThumbnail'] as String?;
      if (thumbnail != null && thumbnail.startsWith('http://')) {
        thumbnail = thumbnail.replaceFirst('http://', 'https://');
      }
    }

    // 2. Ekstrak penulis
    String authors = 'Penulis Tidak Diketahui';
    if (volumeInfo['authors'] != null && (volumeInfo['authors'] as List).isNotEmpty) {
      authors = (volumeInfo['authors'] as List).join(', ');
    }

    // 3. Ekstrak tahun terbit
    String? year;
    String? rawDate = volumeInfo['publishedDate'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      year = rawDate.split('-')[0].trim();
    }

    // 4. Ekstrak kategori utama
    String? primaryCategory;
    if (volumeInfo['categories'] != null && (volumeInfo['categories'] as List).isNotEmpty) {
      primaryCategory = (volumeInfo['categories'] as List).first.toString();
    }

    // 5. Ekstrak ISBN
    String? isbnValue;
    if (volumeInfo['industryIdentifiers'] != null) {
      List identifiers = volumeInfo['industryIdentifiers'] as List;
      for (var idObj in identifiers) {
        if (idObj is Map && (idObj['type'] == 'ISBN_13' || idObj['type'] == 'ISBN_10')) {
          isbnValue = idObj['identifier']?.toString();
          break;
        }
      }
    }

    // 6. Ekstrak rating
    double? avgRating;
    if (volumeInfo['averageRating'] != null) {
      avgRating = (volumeInfo['averageRating'] as num).toDouble();
    }

    return Book(
      id: item['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: volumeInfo['title'] as String? ?? 'Tanpa Judul',
      author: authors,
      coverUrl: thumbnail,
      totalPages: volumeInfo['pageCount'] as int? ?? 0,
      currentPage: 0,
      addedAt: DateTime.now(),
      publishedYear: year,
      category: primaryCategory,
      description: volumeInfo['description'] as String?,
      rating: avgRating,
      isbn: isbnValue,
    );
  }
}
