import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/achievement_provider.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/state/app_state.dart';
import 'package:litly/widgets/goals/annual_goal_card.dart';
import 'package:litly/widgets/goals/daily_banner_card.dart';
import 'package:litly/widgets/goals/daily_goal_cards.dart';
import 'package:litly/widgets/goals/edit_goals_sheet.dart';
import 'package:litly/widgets/goals/monthly_goal_card.dart';

// Target harian, bulanan, dan misi baca tahunan.
class AchievementScreen extends StatefulWidget {
  AchievementScreen({Key? key}) : super(key: key);

  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  AppState? _appState;
  int _lastDataVersion = -1;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    if (_appState != appState) {
      _appState?.removeListener(_onReadingDataChanged);
      _appState = appState..addListener(_onReadingDataChanged);
      _lastDataVersion = appState.dataVersion;
      _refreshUserProgress();
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_onReadingDataChanged);
    super.dispose();
  }

  void _onReadingDataChanged() {
    final dataVersion = _appState?.dataVersion;
    if (dataVersion == null || dataVersion == _lastDataVersion) return;
    _lastDataVersion = dataVersion;
    _refreshUserProgress();
  }

  Future<void> _refreshUserProgress() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    final goalProvider = context.read<GoalProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    try {
      await goalProvider.loadGoals(userId);
      await achievementProvider.checkAndShow(userId);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progres belum dapat diperbarui: $error'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
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
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    GoalProvider goalProvider = Provider.of<GoalProvider>(context);
    int userId = authProvider.user?.id ?? 0;

    DateTime now = DateTime.now();
    String currentMonthName = _indonesianMonths[now.month - 1];
    int currentYear = now.year;

    bool isMinuteMetric =
        goalProvider.dailyPagesGoal == 0 && goalProvider.dailyMinutesGoal > 0;
    bool isConfigured =
        goalProvider.dailyPagesGoal > 0 || goalProvider.dailyMinutesGoal > 0;
    int todayValue = isMinuteMetric
        ? goalProvider.todayMinutes
        : goalProvider.todayPages;
    int targetValue = isMinuteMetric
        ? goalProvider.dailyMinutesGoal
        : goalProvider.dailyPagesGoal;

    String daysLeftText = goalProvider.daysLeftInMonth == 0
        ? 'Hari terakhir'
        : 'Sisa ${goalProvider.daysLeftInMonth} Hari';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Achievement Gaskeun!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [],
      ),
      body: Container(
        color: AppColors.kBackground,
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
                          books: goalProvider.unfinishedBooks,
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
