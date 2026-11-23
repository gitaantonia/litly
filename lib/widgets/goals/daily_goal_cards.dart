import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/widgets/goals/goal_ring.dart';

// Dua kartu target harian (Halaman & Waktu Baca) dalam satu baris sejajar
class DailyGoalCards extends StatelessWidget {
  final int todayPages;
  final int targetPages;
  final int todayMinutes;
  final int targetMinutes;

  DailyGoalCards({
    Key? key,
    required this.todayPages,
    required this.targetPages,
    required this.todayMinutes,
    required this.targetMinutes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Logika Card Halaman
    double pagesProgress = 0.0;
    String pagesSubtext = '';
    Widget pagesCenterContent;

    if (targetPages <= 0) {
      pagesProgress = 0.0;
      pagesSubtext = 'Belum diatur';
      pagesCenterContent = Text(
        '-',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      );
    } else {
      pagesProgress = todayPages / targetPages;
      if (todayPages >= targetPages) {
        pagesSubtext = 'Target harian tercapai';
      } else {
        pagesSubtext = 'Sisa ${targetPages - todayPages} hal lagi';
      }
      pagesCenterContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$todayPages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.kRedMaroon,
            ),
          ),
          Text(
            '/$targetPages hal',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    // 2. Logika Card Waktu Baca
    double minutesProgress = 0.0;
    String minutesSubtext = '';
    Widget minutesCenterContent;

    if (targetMinutes <= 0) {
      minutesProgress = 0.0;
      minutesSubtext = 'Belum diatur';
      minutesCenterContent = Text(
        '-',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      );
    } else {
      minutesProgress = todayMinutes / targetMinutes;
      if (todayMinutes > targetMinutes) {
        minutesSubtext = '+${todayMinutes - targetMinutes} mnt dari rencana';
      } else if (todayMinutes == targetMinutes) {
        minutesSubtext = 'Tepat sesuai rencana';
      } else {
        minutesSubtext = 'Sisa ${targetMinutes - todayMinutes} mnt lagi';
      }
      minutesCenterContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$todayMinutes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE67E22),
            ),
          ),
          Text(
            '/$targetMinutes mnt',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Card Halaman
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
                GoalRing(
                  progress: pagesProgress,
                  color: AppColors.kRedMaroon,
                  child: pagesCenterContent,
                ),
                SizedBox(height: 14),
                Text(
                  'Halaman',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  pagesSubtext,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),

        // Card Waktu Baca
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
                GoalRing(
                  progress: minutesProgress,
                  color: Color(0xFFE67E22),
                  child: minutesCenterContent,
                ),
                SizedBox(height: 14),
                Text(
                  'Waktu Baca',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  minutesSubtext,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
