import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/services/goal_service.dart';
import 'package:litly/widgets/goals/book_cover_item.dart';

// Kartu tantangan membaca tahunan (PB-037)
class AnnualGoalCard extends StatelessWidget {
  final int completedBooks;
  final int targetBooks;
  final String status;
  final List<BookItem> books;
  final VoidCallback onEditTap;

  AnnualGoalCard({
    Key? key,
    required this.completedBooks,
    required this.targetBooks,
    required this.status,
    required this.books,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int currentYear = DateTime.now().year;

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
              'Belum ada tantangan tahunan',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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

    double progressFactor = (completedBooks / targetBooks).clamp(0.0, 1.0);
    bool isOnTrack = status == 'Gas Terus!';

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
          // Baris Header: Judul dan Chip Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Misi Baca $currentYear',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnTrack ? Color(0xFFE8F5E9) : AppColors.kPinkLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOnTrack ? Color(0xFF2E7D32) : AppColors.kRedMaroon,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '$completedBooks / $targetBooks Buku',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 14),

          // Progress bar navy
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

          if (books.isNotEmpty) ...[
            SizedBox(height: 18),
            Text(
              'BUKU YANG BELUM TAMAT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 10),
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
                    isCompleted: false,
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(height: 18),
            Text(
              'Belum ada bacaan yang belum tamat. Tambah buku baru, bestie!',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
