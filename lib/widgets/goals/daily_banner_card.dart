import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/widgets/litly_mascot.dart';

// Banner status pencapaian target membaca harian
class DailyBannerCard extends StatelessWidget {
  final bool isReached;
  final bool isConfigured;
  final int todayValue;
  final int targetValue;
  final int percent;
  final bool isMinuteMetric;
  final VoidCallback onEditTap;

  DailyBannerCard({
    Key? key,
    required this.isReached,
    required this.isConfigured,
    required this.todayValue,
    required this.targetValue,
    required this.percent,
    this.isMinuteMetric = false,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String unit = isMinuteMetric ? 'menit' : 'halaman';

    late final Color bannerColor;
    if (!isConfigured) {
      bannerColor = Color(0xFFF3EDF1);
    } else if (isReached) {
      bannerColor = Color(0xFFFFF5D9);
    } else {
      bannerColor = Color(0xFFF5F0E7);
    }

    String title;
    String description;
    double progressFactor = 0.0;

    if (!isConfigured) {
      title = 'Target harian belum diatur';
      description = 'Pilih target yang nyaman, lalu mulai dari satu halaman.';
      progressFactor = 0.0;
    } else if (isReached) {
      title = percent > 100
          ? 'Targetmu terlampaui!'
          : 'Target harian tercapai!';
      String compliment = percent == 100
          ? 'Target harianmu tercapai 100%!'
          : 'Target harianmu terlampaui $percent%!';
      description =
          'Kamu membaca $todayValue dari $targetValue $unit hari ini. $compliment';
      progressFactor = 1.0;
    } else {
      title = todayValue == 0 ? 'Mulai pelan-pelan' : 'Sedikit lagi!';
      description = todayValue == 0
          ? 'Satu halaman juga sudah jadi awal yang baik.'
          : 'Kamu sudah membaca $todayValue dari $targetValue $unit hari ini.';
      progressFactor = (percent / 100).clamp(0.0, 1.0);
    }
    final mascotMood = !isConfigured
        ? LitlyMood.greeting
        : isReached
        ? (percent > 100 ? LitlyMood.amazed : LitlyMood.cheering)
        : todayValue == 0
        ? LitlyMood.pointing
        : percent >= 75
        ? LitlyMood.amazed
        : LitlyMood.pointing;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerColor,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kNavy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!isConfigured) ...[
                      SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kNavyDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                  ],
                ),
              ),
              SizedBox(width: 12),
              LitlyMascot(mood: mascotMood, width: 104, height: 132),
            ],
          ),
          if (isConfigured) ...[
            SizedBox(height: 16),
            // Progress bar tebal rounded di bawah banner
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 8,
                width: double.infinity,
                color: Colors.white.withOpacity(0.6),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isReached
                          ? Color(0xFFE1B64F)
                          : AppColors.kRedMaroon,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
