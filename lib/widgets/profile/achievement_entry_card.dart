import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/goal_provider.dart';

// // BARU: Kartu navigasi ke Halaman Achievement (Target Membaca)
class AchievementEntryCard extends StatelessWidget {
  AchievementEntryCard({Key? key}) : super(key: key);

  String _buildSubtitle(GoalProvider goal) {
    bool hasDailyPages = goal.dailyPagesGoal > 0;
    bool hasDailyMinutes = goal.dailyMinutesGoal > 0;
    bool hasMonthly = goal.monthlyGoal > 0;
    bool hasAnnual = goal.annualGoal > 0;

    if (!hasDailyPages && !hasDailyMinutes && !hasMonthly && !hasAnnual) {
      return 'Atur targetmu, lalu gas baca!';
    }

    List<String> parts = [];

    // Bagian harian
    if (hasDailyPages) {
      parts.add('Hari ini ${goal.todayPages}/${goal.dailyPagesGoal} halaman');
    } else if (hasDailyMinutes) {
      parts.add('Hari ini ${goal.todayMinutes}/${goal.dailyMinutesGoal} menit');
    }

    // Bagian bulanan
    if (hasMonthly) {
      parts.add('${goal.monthCompleted}/${goal.monthlyGoal} buku bulan ini');
    } else if (hasAnnual && parts.isEmpty) {
      parts.add('${goal.yearCompleted}/${goal.annualGoal} buku tahun ini');
    }

    if (parts.isEmpty) {
      return 'Atur targetmu, lalu gas baca!';
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    GoalProvider goalProvider = Provider.of<GoalProvider>(context);
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    int userId = authProvider.user?.id ?? 0;

    String subtitle = _buildSubtitle(goalProvider);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            // // DIUBAH: Membuka Halaman A lewat route '/achievement'
            await Navigator.pushNamed(context, '/achievement');
            if (context.mounted) {
              Provider.of<GoalProvider>(
                context,
                listen: false,
              ).loadGoals(userId);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.kLavender,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.kRedMaroon,
                    size: 24,
                  ),
                ),
                SizedBox(width: 14),

                // Judul tebal "Achievement" dan subjudul dinamis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement Gaskeun!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),

                // Ikon panah kanan abu
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
