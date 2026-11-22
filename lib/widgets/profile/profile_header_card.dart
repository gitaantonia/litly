import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/widgets/user_avatar.dart'; // // BARU: import UserAvatar

// Kartu header informasi profil pengguna (Avatar, Nama, Email, Tanggal Bergabung, Tombol Edit)
class ProfileHeaderCard extends StatelessWidget {
  ProfileHeaderCard({Key? key}) : super(key: key);

  String _formatMemberSince(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return 'Member since recently';
    }
    try {
      DateTime date = DateTime.parse(createdAt);
      List<String> months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return 'Member since ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Member since recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    UserModel? user = authProvider.user;

    String displayName = user != null && user.name.isNotEmpty
        ? user.name
        : 'Litly Reader';
    String displayEmail = user != null && user.email.isNotEmpty
        ? user.email
        : 'reader@litly.com';
    String memberSinceText = _formatMemberSince(user?.createdAt);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(18),
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
      child: Row(
        children: [
          // // DIUBAH: Avatar memakai UserAvatar dengan titik indikator online di pojok kanan bawah
          Stack(
            children: [
              UserAvatar(
                avatar: user?.avatar,
                name: displayName,
                size: 64,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          // Informasi nama, email, dan tanggal bergabung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  memberSinceText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          // Tombol pensil untuk membuka edit profil
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kLavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.kNavyDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
