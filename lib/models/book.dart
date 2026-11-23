class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? publisher;
  final String? publishedDate;
  final String? publishedYear;
  final String? language;
  final String? category;
  final String? isbn;
  final String? description;
  final int totalPages;
  final double? rating;
  final int? ratingsCount;
  String status;
  int currentPage;
  final DateTime addedAt;
  DateTime? completedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.publisher,
    this.publishedDate,
    this.publishedYear,
    this.language,
    this.category,
    this.isbn,
    this.description,
    required this.totalPages,
    this.rating,
    this.ratingsCount,
    this.status = 'Want to Read',
    this.currentPage = 0,
    required this.addedAt,
    this.completedAt,
  });

  double get progress =>
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  String get progressText => '${(progress * 100).round()}%';

  bool get isFinished => currentPage >= totalPages && totalPages > 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'publisher': publisher,
    'publishedDate': publishedDate,
    'publishedYear': publishedYear,
    'language': language,
    'category': category,
    'isbn': isbn,
    'description': description,
    'totalPages': totalPages,
    'rating': rating,
    'ratingsCount': ratingsCount,
    'status': status,
    'currentPage': currentPage,
    'addedAt': addedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  Map<String, dynamic> toDatabaseMap() => {
    'id': id,
    'title': title,
    'author': author,
    'cover_url': coverUrl,
    'publisher': publisher,
    'published_date': publishedDate,
    'published_year': publishedYear,
    'language': language,
    'category': category,
    'isbn': isbn,
    'description': description,
    'total_pages': totalPages,
    'rating': rating,
    'ratings_count': ratingsCount,
    'status': status,
    'current_page': currentPage,
    'added_at': addedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  factory Book.fromDatabaseMap(Map<String, dynamic> row) => Book(
    id: row['id'] as String,
    title: row['title'] as String,
    author: row['author'] as String,
    coverUrl: row['cover_url'] as String?,
    publisher: row['publisher'] as String?,
    publishedDate: row['published_date'] as String?,
    publishedYear: row['published_year'] as String?,
    language: row['language'] as String?,
    category: row['category'] as String?,
    isbn: row['isbn'] as String?,
    description: row['description'] as String?,
    totalPages: row['total_pages'] as int? ?? 0,
    rating: (row['rating'] as num?)?.toDouble(),
    ratingsCount: row['ratings_count'] as int?,
    status: row['status'] as String? ?? 'Want to Read',
    currentPage: row['current_page'] as int? ?? 0,
    addedAt: DateTime.parse(row['added_at'] as String),
    completedAt: row['completed_at'] == null
        ? null
        : DateTime.parse(row['completed_at'] as String),
  );

  factory Book.fromMap(Map<String, dynamic> map) => Book(
    id: map['id'] as String,
    title: map['title'] as String? ?? 'Tanpa Judul',
    author: map['author'] as String? ?? 'Penulis tidak diketahui',
    coverUrl: map['coverUrl'] as String?,
    publisher: map['publisher'] as String?,
    publishedDate: map['publishedDate'] as String?,
    publishedYear: map['publishedYear'] as String?,
    language: map['language'] as String?,
    category: map['category'] as String?,
    isbn: map['isbn'] as String?,
    description: map['description'] as String?,
    totalPages: map['totalPages'] as int? ?? 0,
    rating: (map['rating'] as num?)?.toDouble(),
    ratingsCount: map['ratingsCount'] as int?,
    status: map['status'] as String? ?? 'Want to Read',
    currentPage: map['currentPage'] as int? ?? 0,
    addedAt: DateTime.parse(map['addedAt'] as String),
    completedAt: map['completedAt'] == null
        ? null
        : DateTime.parse(map['completedAt'] as String),
  );

  factory Book.fromGoogleApi(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? const {};
    final imageLinks =
        volumeInfo['imageLinks'] as Map<String, dynamic>? ?? const {};
    final authors = volumeInfo['authors'] as List<dynamic>? ?? const [];
    final categories = volumeInfo['categories'] as List<dynamic>? ?? const [];
    final identifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>? ?? const [];
    final publishedDate = volumeInfo['publishedDate'] as String?;
    final isbn = identifiers.whereType<Map<String, dynamic>>().firstWhere(
      (identifier) =>
          identifier['type'] == 'ISBN_13' || identifier['type'] == 'ISBN_10',
      orElse: () => const {},
    );
    final imageUrl =
        imageLinks['extraLarge'] ??
        imageLinks['large'] ??
        imageLinks['thumbnail'] ??
        imageLinks['smallThumbnail'];
    final coverUrl =
        _normalizeCover(imageUrl is String ? imageUrl : null) ??
        _fallbackCoverUrl(item['id'] as String?);
    final authorNames = authors.whereType<String>().toList();
    final id = item['id'] as String?;

    return Book(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: volumeInfo['title'] as String? ?? 'Tanpa Judul',
      author: authorNames.isEmpty
          ? 'Penulis Tidak Diketahui'
          : authorNames.join(', '),
      coverUrl: coverUrl,
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: publishedDate,
      publishedYear: publishedDate?.split('-').first,
      language: volumeInfo['language'] as String?,
      category: categories.isEmpty ? null : categories.first.toString(),
      isbn: isbn['identifier'] as String?,
      description: volumeInfo['description'] as String?,
      totalPages: volumeInfo['pageCount'] as int? ?? 0,
      rating: (volumeInfo['averageRating'] as num?)?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'] as int?,
      addedAt: DateTime.now(),
    );
  }

  static String? _fallbackCoverUrl(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return Uri.https('books.google.com', '/books/content', {
      'id': id,
      'printsec': 'frontcover',
      'img': '1',
      'zoom': '2',
      'source': 'gbs_api',
    }).toString();
  }

  static String? _normalizeCover(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return url
        .replaceFirst('http://', 'https://')
        .replaceAll('&edge=curl', '')
        .replaceFirst('zoom=1', 'zoom=2');
  }
}
