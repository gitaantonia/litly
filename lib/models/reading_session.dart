// Model data untuk sesi membaca Focus Timer
class ReadingSession {
  final String id;
  final String? bookId;
  final String bookTitle;
  final int durationMinutes;
  final int durationSeconds;
  final int pagesRead;
  final DateTime createdAt;

  ReadingSession({
    required this.id,
    this.bookId,
    required this.bookTitle,
    required this.durationMinutes,
    required this.durationSeconds,
    required this.pagesRead,
    required this.createdAt,
  });

  // Konversi model ke Map untuk SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'book_id': bookId,
    'book_title': bookTitle,
    'duration_minutes': durationMinutes,
    'duration_seconds': durationSeconds,
    'pages_read': pagesRead,
    'created_at': createdAt.toIso8601String(),
  };

  // Membuat instance ReadingSession dari baris SQLite
  factory ReadingSession.fromMap(Map<String, dynamic> map) => ReadingSession(
    id: map['id'] as String,
    bookId: map['book_id'] as String?,
    bookTitle: map['book_title'] as String? ?? 'Buku Tidak Diketahui',
    durationMinutes: map['duration_minutes'] as int? ?? 0,
    durationSeconds: map['duration_seconds'] as int? ?? 0,
    pagesRead: map['pages_read'] as int? ?? 0,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
