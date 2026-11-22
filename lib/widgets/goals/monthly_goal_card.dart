import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/services/goal_service.dart';
import 'package:litly/widgets/goals/book_cover_item.dart';

// Kartu target membaca bulanan dan daftar buku bulan ini
class MonthlyGoalCard extends StatelessWidget {
  final int completedBooks;
  final int targetBooks;
  final int percent;
  final List<BookItem> books;
  final VoidCallback onEditTap;

  MonthlyGoalCard({
    Key? key,
    required this.completedBooks,
    required this.targetBooks,
    required this.percent,
    required this.books,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (targetBooks <= 0) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Belum ada target bulanan',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kNavyDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                elevation: 0,
              ),
              onPressed: onEditTap,
              child: Text(
                'Atur Target',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Teks status pencapaian bulanan
    String statusText;
    int remaining = targetBooks - completedBooks;
    if (completedBooks >= targetBooks) {
      statusText = 'Target bulan ini tercapai! 🎉';
    } else if (remaining == 1) {
      statusText = 'Hampir tuntas! 1 buku lagi untuk capai 100%.';
    } else {
      statusText = 'Masih butuh $remaining buku lagi untuk capai 100%.';
    }

    double progressFactor = (percent / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: Jumlah buku & status di kiri, lingkaran persentase di kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '$completedBooks ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      children: [
                        TextSpan(
                          text: '/ $targetBooks Buku',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Lingkaran lavender dengan persen tebal
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.kLavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kNavyDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Progress bar navy tebal rounded
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 10,
              width: double.infinity,
              color: AppColors.kLavender,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressFactor,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.kNavyDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Label BUKU BULAN INI
          Text(
            'BUKU BULAN INI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12),

          // Horizontal list buku bulan ini
          if (books.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada buku bulan ini. Yuk mulai membaca!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  BookItem item = books[index];
                  return BookCoverItem(
                    title: item.title,
                    coverUrl: item.coverUrl,
                    percent: item.percent,
                    isCompleted: item.isCompleted,
                    showPercent: true,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
