import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/models/reading_session_item.dart';
import 'package:litly/widgets/history/history_item.dart';

// BARU: Widget timeline vertikal untuk menampilkan daftar riwayat sesi membaca
class HistoryTimeline extends StatelessWidget {
  final List<ReadingSessionItem> sessions;
  final int totalSessionCount;

  HistoryTimeline({
    Key? key,
    required this.sessions,
    required this.totalSessionCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String sessionCountText = totalSessionCount == 1
        ? '1 Session'
        : '$totalSessionCount Sessions';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Recent Reading History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFFDE8EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sessionCountText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA65F59),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Kondisi jika belum ada sesi membaca
          if (sessions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat membaca',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Catat sesi pertamamu untuk melihat perkembanganmu di sini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                ReadingSessionItem item = sessions[index];
                bool isLatest = index == 0;
                bool isLast = index == sessions.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kolom Node dan Garis Vertikal (lebar 32)
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            // Node bulat
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLatest
                                    ? Color(0xFFFDE8EE)
                                    : (isDarkMode ? Color(0xFF38385A) : Color(0xFFE8E4F8)),
                              ),
                              child: Icon(
                                isLatest ? Icons.bolt : Icons.menu_book,
                                size: 16,
                                color: isLatest
                                    ? Color(0xFFA65F59)
                                    : (isDarkMode ? Colors.white70 : Color(0xFF38323B)),
                              ),
                            ),

                            // Garis vertikal menyambung ke item berikutnya
                            Expanded(
                              child: isLast
                                  ? SizedBox.shrink()
                                  : Container(
                                      width: 2,
                                      margin: EdgeInsets.symmetric(vertical: 2),
                                      color: isDarkMode
                                          ? Color(0xFF38385A)
                                          : Color(0xFFE8E4F8),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),

                      // Kolom Kanan: Kartu item riwayat
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: HistoryItem(
                            session: item,
                            isLatest: isLatest,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Keterangan jika sesi lebih dari 10
          if (totalSessionCount > 10) ...[
            SizedBox(height: 8),
            Center(
              child: Text(
                'Menampilkan 10 sesi terbaru',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
