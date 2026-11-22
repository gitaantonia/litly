import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/core/badge_style.dart';

// Modal bottom sheet untuk melihat detail informasi sebuah lencana
class BadgeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> badge;

  BadgeDetailSheet({Key? key, required this.badge}) : super(key: key);

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(dateStr);
      List<String> months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return 'Terbuka pada ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    String badgeId = badge['id'] as String? ?? '';
    String title = badge['title'] as String? ?? 'Badge';
    String description = badge['description'] as String? ?? '';
    String iconName = badge['icon_name'] as String? ?? '';
    bool isUnlocked = (badge['is_unlocked'] == 1) || (badge['unlocked_at'] != null);
    String dateInfo = _formatDate(badge['unlocked_at'] as String?);

    BadgeStyleData style = BadgeStyle.getStyle(badgeId, iconName);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Handle bar abu kecil di atas sheet
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),

          // Lingkaran ikon besar dengan warna pastel
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isUnlocked ? style.backgroundColor : AppColors.kLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              style.icon,
              size: 40,
              color: isUnlocked ? style.iconColor : Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),

          // Judul lencana
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),

          // Deskripsi lencana
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),

          // Chip status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUnlocked ? Color(0xFFE8F5E9) : AppColors.kLavender,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isUnlocked ? 'Lencana Terbuka 🎉' : 'Lencana Terkunci',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Color(0xFF2E7D32) : Colors.grey[600],
              ),
            ),
          ),

          if (isUnlocked && dateInfo.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              dateInfo,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          SizedBox(height: 24),

          // Tombol Tutup
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kNavyDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
