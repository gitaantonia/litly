import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/core/badge_style.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/services/achievement_service.dart';
import 'package:litly/widgets/profile/badge_detail_sheet.dart';

// Halaman B: Level, XP, dan Koleksi Lencana (AppBar: Level)
class LevelScreen extends StatefulWidget {
  LevelScreen({Key? key}) : super(key: key);

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final AchievementService _achievementService = AchievementService();
  List<Map<String, dynamic>> _allAchievements = [];
  bool _isLoading = true;
  int _selectedFilterIndex = 0; // 0 = Semua, 1 = Terbuka, 2 = Terkunci

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    int userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
    await _achievementService.checkAndUnlockAchievements(userId);
    List<Map<String, dynamic>> list =
        await _achievementService.getAllAchievementsWithStatus(userId);

    if (mounted) {
      setState(() {
        _allAchievements = list;
        _isLoading = false;
      });
    }
  }

  void _showBadgeDetail(Map<String, dynamic> badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BadgeDetailSheet(badge: badge);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    int unlockedCount =
        _allAchievements.where((item) => item['is_unlocked'] == 1).length;
    int totalCount = _allAchievements.length;

    // Filter daftar lencana berdasarkan tab
    List<Map<String, dynamic>> filteredBadges = _allAchievements.where((item) {
      if (_selectedFilterIndex == 1) return item['is_unlocked'] == 1;
      if (_selectedFilterIndex == 2) return item['is_unlocked'] != 1;
      return true;
    }).toList();

    // Data Level & XP sederhana
    int currentLevel = 3;
    int currentXp = 340;
    int nextLevelXp = 500;
    double xpProgress = (currentXp / nextLevelXp).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // // DIUBAH: Judul AppBar adalah "Level" sesuai desain Halaman B
        title: Text(
          'Level',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Kartu Level & XP
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.kPinkLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.military_tech_rounded,
                                          color: AppColors.kRedMaroon,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Level $currentLevel · Book Explorer',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '$unlockedCount dari $totalCount lencana terbuka',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'XP Progres',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '$currentXp / $nextLevelXp XP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.kRedMaroon,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 8,
                                  width: double.infinity,
                                  color: AppColors.kLavender,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: xpProgress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.kRedMaroon,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // 2. Tab Filter Lencana (Semua, Terbuka, Terkunci)
                        Row(
                          children: [
                            _buildFilterTab(0, 'Semua ($totalCount)'),
                            SizedBox(width: 8),
                            _buildFilterTab(1, 'Terbuka ($unlockedCount)'),
                            SizedBox(width: 8),
                            _buildFilterTab(
                              2,
                              'Terkunci (${totalCount - unlockedCount})',
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // 3. Grid Daftar Lencana
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredBadges.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.88,
                          ),
                          itemBuilder: (context, index) {
                            Map<String, dynamic> item = filteredBadges[index];
                            bool isUnlocked = item['is_unlocked'] == 1;
                            String badgeId = item['id'] as String? ?? '';
                            String title = item['title'] as String? ?? '';
                            String desc = item['description'] as String? ?? '';
                            String iconName = item['icon_name'] as String? ?? '';

                            BadgeStyleData style =
                                BadgeStyle.getStyle(badgeId, iconName);

                            return InkWell(
                              onTap: () => _showBadgeDetail(item),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: isUnlocked
                                            ? style.backgroundColor
                                            : AppColors.kLavender
                                                .withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        style.icon,
                                        color: isUnlocked
                                            ? style.iconColor
                                            : Colors.grey[400],
                                        size: 26,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      desc,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUnlocked
                                            ? Color(0xFFE8F5E9)
                                            : AppColors.kLavender,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isUnlocked ? 'Terbuka' : 'Terkunci',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked
                                              ? Color(0xFF2E7D32)
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  Widget _buildFilterTab(int index, String label) {
    bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.kNavyDark : AppColors.kLavender,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.kNavyDark,
            ),
          ),
        ),
      ),
    );
  }
}
