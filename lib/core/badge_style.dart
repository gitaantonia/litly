import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';

class BadgeStyleData {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  BadgeStyleData({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

class BadgeStyle {
  static BadgeStyleData getStyle(String? badgeId, String? iconName) {
    String key = (badgeId ?? '').toLowerCase().trim();

    if (key.contains('first') || key.contains('step')) {
      return BadgeStyleData(
        icon: Icons.bookmark_add_outlined,
        iconColor: AppColors.kPurple,
        backgroundColor: AppColors.kLightPurple,
      );
    }
    if (key.contains('page') || key.contains('turner')) {
      return BadgeStyleData(
        icon: Icons.auto_stories_outlined,
        iconColor: AppColors.kPurple,
        backgroundColor: AppColors.kLightPurple,
      );
    }
    if (key.contains('goal') || key.contains('crusher')) {
      return BadgeStyleData(
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.kNavy,
        backgroundColor: AppColors.kYellow,
      );
    }
    if (key.contains('bookworm') || key.contains('worm')) {
      return BadgeStyleData(
        icon: Icons.menu_book_outlined,
        iconColor: AppColors.kPurple,
        backgroundColor: AppColors.kLightPurple,
      );
    }
    if (key.contains('night') || key.contains('owl')) {
      return BadgeStyleData(
        icon: Icons.nights_stay_outlined,
        iconColor: AppColors.kPurple,
        backgroundColor: AppColors.kLightPurple,
      );
    }
    if (key.contains('marathon') || key.contains('timer')) {
      return BadgeStyleData(
        icon: Icons.timer_outlined,
        iconColor: AppColors.kPurple,
        backgroundColor: AppColors.kLightPurple,
      );
    }

    // Default fallback
    return BadgeStyleData(
      icon: Icons.bookmark_border_rounded,
      iconColor: AppColors.kPurple,
      backgroundColor: AppColors.kLightPurple,
    );
  }
}
