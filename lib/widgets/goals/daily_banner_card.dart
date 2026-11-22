import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';

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

    // Gradasi warna latar: kuning krem jika tercapai, lavender pucat jika belum tercapai
    List<Color> gradientColors;
    if (!isConfigured) {
      gradientColors = [
        Color(0xFFF7F3FC),
        Color(0xFFEFE8F6),
      ];
    } else if (isReached) {
      gradientColors = [
        Color(0xFFFFF9E6),
        Color(0xFFFFEEBA),
      ];
    } else {
      gradientColors = [
        Color(0xFFF3EEF8),
        Color(0xFFEBE4F3),
      ];
    }

    String title;
    String description;
    double progressFactor = 0.0;

    if (!isConfigured) {
      title = 'Belum Ada Target Harian';
      description = 'Atur target membacamu supaya lebih konsisten.';
      progressFactor = 0.0;
    } else if (isReached) {
      title = 'Daily Goal Achieved!';
      String compliment = percent == 100
          ? 'Target harianmu tercapai 100%!'
          : 'Target harianmu terlampaui $percent%!';
      description =
          'Luar biasa! Kamu membaca $todayValue dari $targetValue $unit hari ini. $compliment';
      progressFactor = 1.0;
    } else {
      title = 'Ayo Capai Targetmu!';
      description =
          'Kamu sudah membaca $todayValue dari $targetValue $unit hari ini. Sedikit lagi!';
      progressFactor = (percent / 100).clamp(0.0, 1.0);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              // Kolom teks judul dan deskripsi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF252A3D),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF555A6E),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // Maskot bintang litly
              Image.asset(
                'assets/images/litly_star.png',
                height: 90,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 80,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.star_rounded,
                      size: 60,
                      color: Color(0xFFFFB300),
                    ),
                  );
                },
              ),
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
                      color: isReached ? Color(0xFFF39C12) : AppColors.kRedMaroon,
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
