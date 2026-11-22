import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/widgets/goals/edit_goals_sheet.dart';

// // DIUBAH: Kartu progres tantangan membaca tahunan sesuai gambar desain 2
class ReadingChallengeCard extends StatelessWidget {
  ReadingChallengeCard({Key? key}) : super(key: key);

  void _openEditSheet(BuildContext context, GoalProvider goal, int userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return EditGoalsSheet(
          userId: userId,
          initialDailyPages: goal.dailyPagesGoal,
          initialDailyMinutes: goal.dailyMinutesGoal,
          initialMonthlyBooks: goal.monthlyGoal,
          initialAnnualBooks: goal.annualGoal,
        );
      },
    );
    if (context.mounted) {
      goal.loadGoals(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // // DIUBAH: Membaca data langsung dari GoalProvider
    GoalProvider goalProvider = Provider.of<GoalProvider>(context);
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    int userId = authProvider.user?.id ?? 0;

    int currentYear = DateTime.now().year;
    int yearCompleted = goalProvider.yearCompleted;
    int annualGoal = goalProvider.annualGoal;

    // Perhitungan status dan persentase target tahunan
    DateTime now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    bool isLeapYear = (now.year % 4 == 0 && now.year % 100 != 0) || (now.year % 400 == 0);
    int totalDaysInYear = isLeapYear ? 366 : 365;

    double progress = 0.0;
    int percentage = 0;
    String statusMessage = '';

    if (annualGoal > 0) {
      progress = (yearCompleted / annualGoal).clamp(0.0, 1.0);
      percentage = ((yearCompleted * 100) / annualGoal).round();
      if (percentage > 100) percentage = 100;

      double expected = (annualGoal * dayOfYear) / totalDaysInYear;
      int diff = yearCompleted - expected.floor();

      if (yearCompleted >= annualGoal) {
        statusMessage = 'Challenge complete! Amazing work 🎉';
      } else if (diff > 0) {
        String bookWord = diff == 1 ? 'book' : 'books';
        statusMessage = 'You are $diff $bookWord ahead of your annual schedule. Keep going!';
      } else if (diff < 0) {
        int diffAbs = diff.abs();
        String bookWord = diffAbs == 1 ? 'book' : 'books';
        statusMessage = 'You are $diffAbs $bookWord behind schedule. You can catch up!';
      } else {
        statusMessage = 'You are right on schedule!';
      }
    }

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
          onTap: () {
            // // DIUBAH: Mengetuk card membuka EditGoalsSheet
            _openEditSheet(context, goalProvider, userId);
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris atas: Judul dan pil persentase
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentYear Reading Challenge',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (annualGoal > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.kPinkLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: AppColors.kRedMaroon,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),

                if (annualGoal == 0) ...[
                  Text(
                    "You haven't set an annual reading goal yet.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kRedMaroon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // // DIUBAH: Membuka bottom sheet EditGoalsSheet, bukan pindah halaman
                      _openEditSheet(context, goalProvider, userId);
                    },
                    child: Text(
                      'Set Goal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else ...[
                  // Progress Bar tinggi 8 rounded penuh
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: AppColors.kLavender,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.kRedMaroon,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$yearCompleted of $annualGoal titles complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
