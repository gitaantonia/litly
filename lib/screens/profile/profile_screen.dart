import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/providers/profile_provider.dart';
import 'package:litly/widgets/profile/achievement_entry_card.dart'; // // BARU: import kartu Achievement
import 'package:litly/widgets/profile/badge_preview_card.dart';
import 'package:litly/widgets/profile/profile_header_card.dart';
import 'package:litly/widgets/profile/reading_challenge_card.dart';

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
    // Memuat data profil, goals, dan pengaturan saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int userId =
          Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
      Provider.of<AuthProvider>(context, listen: false).loadUserFromSession();
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).loadProfileData(userId);
      Provider.of<GoalProvider>(context, listen: false).loadGoals(userId);
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: AppColors.kBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Profil
                ProfileHeaderCard(),
                SizedBox(height: 8),

                // 2. Section Literary Journey
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Perjalanan Membaca',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/routine'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: AppColors.kPurple),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atur rutin membaca',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Atur waktu dan hari pengingat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

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
                        int userId =
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).user?.id ??
                            0;
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).loadUserFromSession();
                        Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        ).loadProfileData(userId);
                        Provider.of<GoalProvider>(
                          context,
                          listen: false,
                        ).loadGoals(userId);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Edit profil',
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
                          Icon(
                            Icons.logout,
                            color: AppColors.kRedMaroon,
                            size: 20,
                          ),
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
