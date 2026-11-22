import 'dart:io';
import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';

// BARU: Kartu ringkasan buku di bagian atas halaman riwayat membaca
class BookSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? book;
  final int progressPercent;
  final int pagesLeft;
  final String timeLeftText;

  BookSummaryCard({
    Key? key,
    required this.book,
    required this.progressPercent,
    required this.pagesLeft,
    required this.timeLeftText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String title = book?['title'] ?? 'Tanpa Judul';
    String author = book?['author'] ?? 'Penulis tidak diketahui';
    String? coverUrl = book?['coverUrl'];
    int totalPages = (book?['totalPages'] as num?)?.toInt() ?? 0;
    int currentPage = (book?['currentPage'] as num?)?.toInt() ?? 0;
    String status = book?['status'] ?? 'Want to Read';

    // Format teks status menjadi UPPERCASE
    String statusUpper = status.toUpperCase();

    // Format teks sisa halaman
    String pagesLeftText = '';
    if (pagesLeft <= 0) {
      pagesLeftText = 'Finished!';
    } else if (pagesLeft == 1) {
      pagesLeftText = '1 page to finish';
    } else {
      pagesLeftText = '$pagesLeft pages to finish';
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Lingkaran dekoratif pink muda di pojok kanan atas
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFDE8EE).withOpacity(isDarkMode ? 0.08 : 0.6),
                ),
              ),
            ),

            // Konten kartu
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Atas: Sampul di kiri, Informasi Buku di kanan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sampul Buku
                      _buildBookCover(coverUrl, title),
                      SizedBox(width: 14),

                      // Detail Buku
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pil Status (pink muda dengan dot merah marun)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFFDE8EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFB5294E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    statusUpper,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB5294E),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),

                            // Judul Buku
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),

                            // Penulis Buku
                            Text(
                              author,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 14),

                            // Baris Halaman & Persentase
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(width: 6),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '$currentPage',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: ' / $totalPages pgs',
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '$progressPercent%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB5294E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Progress Bar 8px
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: Color(0xFFE8E4F8),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (progressPercent / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFB5294E), Color(0xFFD45278)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Baris Bawah: Waktu tersisa di kiri, Sisa halaman di kanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          SizedBox(width: 6),
                          Text(
                            timeLeftText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        pagesLeftText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembangun sampul buku
  Widget _buildBookCover(String? coverUrl, String title) {
    String firstLetter = title.isNotEmpty ? title[0].toUpperCase() : 'B';

    Widget placeholder = Container(
      width: 95,
      height: 135,
      decoration: BoxDecoration(
        color: Color(0xFFE8E4F8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB5294E),
          ),
        ),
      ),
    );

    if (coverUrl == null || coverUrl.isEmpty) {
      return placeholder;
    }

    if (coverUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 95,
          height: 135,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.network(
            coverUrl,
            width: 95,
            height: 135,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 95,
          height: 135,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.file(
            File(coverUrl),
            width: 95,
            height: 135,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
        ),
      );
    }
  }
}
