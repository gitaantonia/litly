// BARU: Model item sesi membaca untuk timeline riwayat baca
class ReadingSessionItem {
  final int id;
  final int startPage;
  final int endPage;
  final int durationSeconds;
  final DateTime createdAt;

  ReadingSessionItem({
    required this.id,
    required this.startPage,
    required this.endPage,
    required this.durationSeconds,
    required this.createdAt,
  });

  // Getter jumlah halaman yang dibaca pada sesi ini
  int get pagesRead {
    return endPage - startPage;
  }

  // Getter durasi dalam menit (dibulatkan, minimal 1 jika durationSeconds > 0)
  int get durationMinutes {
    if (durationSeconds <= 0) {
      return 0;
    }
    int mins = (durationSeconds / 60).round();
    if (mins < 1) {
      return 1;
    }
    return mins;
  }

  // Getter kecepatan membaca (menit per halaman dengan 1 desimal)
  String get pacePerPage {
    if (durationMinutes <= 0 || pagesRead <= 0) {
      return '';
    }
    double pace = durationMinutes / pagesRead;
    return pace.toStringAsFixed(1);
  }

  // Konversi dari Map SQLite ke objek model
  factory ReadingSessionItem.fromMap(Map<String, dynamic> map) {
    int parsedId = 0;
    var rawId = map['id'];
    if (rawId is num) {
      parsedId = rawId.toInt();
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    }

    int start = (map['start_page'] as num?)?.toInt() ?? 0;
    int end = (map['end_page'] as num?)?.toInt() ?? 0;

    // Fallback jika ada data lama yang memakai pages_read
    if (end == 0 && map['pages_read'] != null) {
      int pagesRead = (map['pages_read'] as num?)?.toInt() ?? 0;
      end = start + pagesRead;
    }

    int durationSec = (map['duration_seconds'] as num?)?.toInt() ?? 0;
    if (durationSec == 0 && map['duration_minutes'] != null) {
      int durationMin = (map['duration_minutes'] as num?)?.toInt() ?? 0;
      durationSec = durationMin * 60;
    }

    DateTime created = DateTime.now();
    if (map['created_at'] != null) {
      DateTime? parsed = DateTime.tryParse(map['created_at'].toString());
      if (parsed != null) {
        created = parsed;
      }
    }

    return ReadingSessionItem(
      id: parsedId,
      startPage: start,
      endPage: end,
      durationSeconds: durationSec,
      createdAt: created,
    );
  }

  // Konversi model ke Map untuk SQLite
  Map<String, dynamic> toMap(String bookId) {
    Map<String, dynamic> map = {
      'book_id': bookId,
      'duration_seconds': durationSeconds,
      'start_page': startPage,
      'end_page': endPage,
      'created_at': createdAt.toIso8601String(),
    };
    if (id > 0) {
      map['id'] = id;
    }
    return map;
  }
}
