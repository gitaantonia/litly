import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';

// Widget cincin progres melingkar untuk kartu target harian
class GoalRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Widget child;
  final double size;
  final double strokeWidth;

  GoalRing({
    Key? key,
    required this.progress,
    required this.color,
    required this.child,
    this.size = 90.0,
    this.strokeWidth = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nilai dibatasi 0.0 sampai 1.0 agar cincin tetap penuh jika melebihi target
    double clampedValue = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Latar belakang lingkaran (track lavender)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.kLavender),
            ),
          ),
          // Indikator progres aktif
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clampedValue,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // Konten di tengah lingkaran
          Center(child: child),
        ],
      ),
    );
  }
}
