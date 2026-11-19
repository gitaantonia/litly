class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  int currentPage;
  final DateTime addedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.currentPage = 0,
    required this.addedAt,
  });

  /// Persentase progress (0.0 – 1.0)
  double get progress =>
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  /// Persentase dalam bentuk teks, misal "42%"
  String get progressText => '${(progress * 100).round()}%';

  bool get isFinished => currentPage >= totalPages && totalPages > 0;

  // Konversi dari/ke Map untuk disimpan di shared_preferences
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        title: map['title'] as String,
        author: map['author'] as String,
        coverUrl: map['coverUrl'] as String?,
        totalPages: map['totalPages'] as int,
        currentPage: map['currentPage'] as int? ?? 0,
        addedAt: DateTime.parse(map['addedAt'] as String),
      );
}
