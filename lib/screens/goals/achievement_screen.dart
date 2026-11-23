import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/widgets/goals/annual_goal_card.dart';
import 'package:litly/widgets/goals/daily_banner_card.dart';
import 'package:litly/widgets/goals/daily_goal_cards.dart';
import 'package:litly/widgets/goals/edit_goals_sheet.dart';
import 'package:litly/widgets/goals/monthly_goal_card.dart';

// Halaman A: Target Membaca Harian, Bulanan, dan Tahunan (AppBar: Achievement)
class AchievementScreen extends StatefulWidget {
  AchievementScreen({Key? key}) : super(key: key);

  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final List<String> _indonesianMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
      Provider.of<GoalProvider>(context, listen: false).loadGoals(userId);
    });
  }

  void _openEditSheet(GoalProvider goalProvider, int userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditGoalsSheet(
          userId: userId,
          initialDailyPages: goalProvider.dailyPagesGoal,
          initialDailyMinutes: goalProvider.dailyMinutesGoal,
          initialMonthlyBooks: goalProvider.monthlyGoal,
          initialAnnualBooks: goalProvider.annualGoal,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    GoalProvider goalProvider = Provider.of<GoalProvider>(context);
    int userId = authProvider.user?.id ?? 0;

    DateTime now = DateTime.now();
    String currentMonthName = _indonesianMonths[now.month - 1];
    int currentYear = now.year;

    bool isMinuteMetric = goalProvider.dailyPagesGoal == 0 && goalProvider.dailyMinutesGoal > 0;
    bool isConfigured = goalProvider.dailyPagesGoal > 0 || goalProvider.dailyMinutesGoal > 0;
    int todayValue = isMinuteMetric ? goalProvider.todayMinutes : goalProvider.todayPages;
    int targetValue = isMinuteMetric ? goalProvider.dailyMinutesGoal : goalProvider.dailyPagesGoal;

    String daysLeftText = goalProvider.daysLeftInMonth == 0
        ? 'Hari terakhir'
        : 'Sisa ${goalProvider.daysLeftInMonth} Hari';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // // DIUBAH: Judul AppBar adalah "Achievement" sesuai desain Halaman A
        title: Text(
          'Achievement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          // // ==========================================
          // // HAPUS SEBELUM DIKUMPULKAN: Tombol Debug
          // // ==========================================
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.science_outlined),
              tooltip: 'Debug Mock Data (18/24 Buku, 75%)',
              onPressed: () {
                goalProvider.setDebugMockData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data contoh debug aktif (18/24 buku, 75%)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          // // ==========================================
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : null,
          gradient: isDarkMode
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.profileBgStart,
                    AppColors.profileBgEnd,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await goalProvider.checkGoalAndCelebrate(context, userId);
            },
            child: goalProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Daily Banner Card
                        DailyBannerCard(
                          isReached: goalProvider.isDailyReached,
                          isConfigured: isConfigured,
                          todayValue: todayValue,
                          targetValue: targetValue,
                          percent: goalProvider.dailyPercent,
                          isMinuteMetric: isMinuteMetric,
                          onEditTap: () => _openEditSheet(goalProvider, userId),
                        ),
                        SizedBox(height: 22),

                        // 2. Baris Judul Target Harian & Tombol Sesuaikan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Harian',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () => _openEditSheet(goalProvider, userId),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.kLavender,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: 15,
                                      color: AppColors.kNavyDark,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sesuaikan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kNavyDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // 3. Daily Goal Cards (Halaman & Waktu Baca)
                        DailyGoalCards(
                          todayPages: goalProvider.todayPages,
                          targetPages: goalProvider.dailyPagesGoal,
                          todayMinutes: goalProvider.todayMinutes,
                          targetMinutes: goalProvider.dailyMinutesGoal,
                        ),
                        SizedBox(height: 22),

                        // 4. Baris Judul Target Bulanan & Chip Sisa Hari
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target $currentMonthName $currentYear',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kLavender,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                daysLeftText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kNavyDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // 5. Monthly Goal Card
                        MonthlyGoalCard(
                          completedBooks: goalProvider.monthCompleted,
                          targetBooks: goalProvider.monthlyGoal,
                          percent: goalProvider.monthlyPercent,
                          books: goalProvider.monthBooks,
                          onEditTap: () => _openEditSheet(goalProvider, userId),
                        ),
                        SizedBox(height: 22),

                        // 6. Annual Goal Card (Tantangan Tahunan)
                        AnnualGoalCard(
                          completedBooks: goalProvider.yearCompleted,
                          targetBooks: goalProvider.annualGoal,
                          status: goalProvider.yearStatus,
                          books: goalProvider.yearBooks,
                          onEditTap: () => _openEditSheet(goalProvider, userId),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
