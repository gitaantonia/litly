import 'package:flutter/material.dart';
import 'package:litly/models/reading_session_item.dart';

// BARU: Kartu item riwayat sesi membaca dalam timeline
class HistoryItem extends StatelessWidget {
  final ReadingSessionItem session;
  final bool isLatest;

  HistoryItem({
    Key? key,
    required this.session,
    this.isLatest = false,
  }) : super(key: key);

  // Format label waktu sesi secara manual tanpa package intl
  String _formatDateTime(DateTime createdAt) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime sessionDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    int diffDays = today.difference(sessionDate).inDays;
    String hourStr = createdAt.hour.toString().padLeft(2, '0');
    String minStr = createdAt.minute.toString().padLeft(2, '0');
    String timeStr = '$hourStr:$minStr';

    if (diffDays == 0) {
      return 'Hari ini, $timeStr';
    } else if (diffDays == 1) {
      return 'Kemarin, $timeStr';
    } else if (diffDays >= 2 && diffDays <= 6) {
      return '$diffDays hari lalu, $timeStr';
    } else {
      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      String monthName = months[createdAt.month - 1];
      return '${createdAt.day} $monthName, $timeStr';
    }
  }

  // Label level fokus berdasarkan durasi membaca
  String _getFocusLabel(int durationMinutes) {
    if (durationMinutes >= 20) {
      return 'Focus high';
    } else if (durationMinutes >= 10) {
      return 'Focus medium';
    } else {
      return 'Focus low';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String timeLabel = _formatDateTime(session.createdAt);
    String pace = session.pacePerPage;
    String focusLabel = _getFocusLabel(session.durationMinutes);

    String durationText = session.durationSeconds > 0
        ? '${session.durationMinutes}m duration'
        : 'no timer';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF282846) : Color(0xFFF1EEFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Waktu di kiri, +X pgs di kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                '+${session.pagesRead} pgs',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA65F59),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),

          // Baris 2: Rentang halaman di kiri, Durasi di kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'p. ${session.startPage} → p. ${session.endPage}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                durationText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),

          // Baris 3: Khusus item paling baru dengan durasi > 0
          if (isLatest && session.durationSeconds > 0 && pace.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF38385A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 13,
                    color: Colors.orange[700],
                  ),
                  SizedBox(width: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      children: [
                        TextSpan(text: 'Pace: $pace m/page • '),
                        TextSpan(
                          text: focusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
