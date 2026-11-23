import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/providers/profile_provider.dart';
import 'package:litly/providers/settings_provider.dart';
import 'package:litly/providers/theme_provider.dart';
import 'package:litly/widgets/profile/achievement_entry_card.dart'; // // BARU: import kartu Achievement
import 'package:litly/widgets/profile/appearance_card.dart';
import 'package:litly/widgets/profile/badge_preview_card.dart';
import 'package:litly/widgets/profile/profile_header_card.dart';
import 'package:litly/widgets/profile/reading_challenge_card.dart';
import 'package:litly/widgets/profile/reading_reminder_card.dart';

// Halaman utama Profil pengguna Litly
class ProfileScreen extends StatefulWidget {
  final String username;

  ProfileScreen({Key? key, this.username = ''}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Memuat data profil, goals, settings, dan tema saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
      Provider.of<AuthProvider>(context, listen: false).loadUserFromSession();
      Provider.of<ProfileProvider>(context, listen: false).loadProfileData(userId);
      // // BARU: Memuat data GoalProvider untuk ReadingChallengeCard & AchievementEntryCard
      Provider.of<GoalProvider>(context, listen: false).loadGoals(userId);
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
      Provider.of<ThemeProvider>(context, listen: false).loadTheme();
    });
  }

  void _showLogoutDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.kRedMaroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    int currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),

                // 1. Header Profil
                ProfileHeaderCard(),
                SizedBox(height: 24),

                // 2. Section Literary Journey
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.kRedMaroon,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Literary Journey',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$currentYear GOAL',
                        style: TextStyle(
                          color: AppColors.kRedMaroon,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),

                // 3. Reading Challenge Card (baca dari GoalProvider)
                ReadingChallengeCard(),
                SizedBox(height: 12),

                // 4. // BARU: Achievement Entry Card (PERSIS di bawah Reading Challenge)
                AchievementEntryCard(),
                SizedBox(height: 12),

                // 5. Badge Collection
                BadgePreviewCard(),
                SizedBox(height: 24),

                // 6. Section Settings & Preferences
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Settings & Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ReadingReminderCard(),
                SizedBox(height: 12),
                AppearanceCard(),
                SizedBox(height: 28),

                // 7. Tombol Bawah
                // Tombol Edit Profile Details
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kNavyDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/edit-profile');
                        if (!context.mounted) return;
                        int userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
                        Provider.of<AuthProvider>(context, listen: false).loadUserFromSession();
                        Provider.of<ProfileProvider>(context, listen: false).loadProfileData(userId);
                        Provider.of<GoalProvider>(context, listen: false).loadGoals(userId);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Edit Profile Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Tombol Log Out of Litly
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.kPinkLight,
                        side: BorderSide(color: AppColors.kPinkLight),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _showLogoutDialog,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: AppColors.kRedMaroon, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Log Out of Litly',
                            style: TextStyle(
                              color: AppColors.kRedMaroon,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
