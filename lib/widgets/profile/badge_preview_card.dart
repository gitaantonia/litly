import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/core/badge_style.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/services/achievement_service.dart';
import 'package:litly/widgets/profile/badge_detail_sheet.dart';

// // DIUBAH: Kartu pratinjau koleksi lencana terbaru pengguna
class BadgePreviewCard extends StatefulWidget {
  BadgePreviewCard({Key? key}) : super(key: key);

  @override
  _BadgePreviewCardState createState() => _BadgePreviewCardState();
}

class _BadgePreviewCardState extends State<BadgePreviewCard> {
  final AchievementService _achievementService = AchievementService();
  List<Map<String, dynamic>> _unlockedBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBadges();
  }

  Future<void> _loadUserBadges() async {
    int userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
    List<Map<String, dynamic>> list =
        await _achievementService.getUserUnlockedAchievements(userId, limit: 4);

    if (mounted) {
      setState(() {
        _unlockedBadges = list;
        _isLoading = false;
      });
    }
  }

  void _showDetail(Map<String, dynamic> badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BadgeDetailSheet(badge: badge);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Header: Judul dan Tombol See All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Badge Collection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () async {
                  // // DIUBAH: Membuka Halaman B lewat route '/level'
                  await Navigator.pushNamed(context, '/level');
                  if (mounted) {
                    _loadUserBadges();
                  }
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.kRedMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          if (_isLoading)
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_unlockedBadges.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No badges unlocked yet. Start reading!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            // Baris horizontal lencana dengan ikon dan warna bervariasi dari BadgeStyle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _unlockedBadges.map((badge) {
                String badgeId = badge['id'] as String? ?? '';
                String title = badge['title'] as String? ?? 'Badge';
                String iconName = badge['icon_name'] as String? ?? '';

                BadgeStyleData style = BadgeStyle.getStyle(badgeId, iconName);

                return InkWell(
                  onTap: () => _showDetail(badge),
                  borderRadius: BorderRadius.circular(30),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: style.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          style.icon,
                          color: style.iconColor,
                          size: 26,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
