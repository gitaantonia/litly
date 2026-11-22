import 'package:flutter/material.dart';

// Model data style visual lencana (ikon dan warna pastel)
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

// Helper untuk styling lencana berdasarkan ID atau nama icon
class BadgeStyle {
  static BadgeStyleData getStyle(String? badgeId, String? iconName) {
    String key = (badgeId ?? '').toLowerCase().trim();

    if (key.contains('first') || key.contains('step')) {
      return BadgeStyleData(
        icon: Icons.explore_outlined,
        iconColor: Color(0xFF00897B),
        backgroundColor: Color(0xFFE0F2F1), // Pastel teal
      );
    }
    if (key.contains('page') || key.contains('turner')) {
      return BadgeStyleData(
        icon: Icons.auto_stories_outlined,
        iconColor: Color(0xFFE65100),
        backgroundColor: Color(0xFFFFF3E0), // Pastel orange
      );
    }
    if (key.contains('goal') || key.contains('crusher')) {
      return BadgeStyleData(
        icon: Icons.emoji_events_outlined,
        iconColor: Color(0xFFB5294E),
        backgroundColor: Color(0xFFFDE8EE), // Pastel pink Litly
      );
    }
    if (key.contains('bookworm') || key.contains('worm')) {
      return BadgeStyleData(
        icon: Icons.menu_book_outlined,
        iconColor: Color(0xFF6B4585),
        backgroundColor: Color(0xFFF3EBF9), // Pastel purple Litly
      );
    }
    if (key.contains('night') || key.contains('owl')) {
      return BadgeStyleData(
        icon: Icons.nightlight_round_outlined,
        iconColor: Color(0xFF2E365A),
        backgroundColor: Color(0xFFE8E4F8), // Pastel lavender Litly
      );
    }
    if (key.contains('marathon') || key.contains('timer')) {
      return BadgeStyleData(
        icon: Icons.timer_outlined,
        iconColor: Color(0xFFD84315),
        backgroundColor: Color(0xFFFFEBE6), // Pastel red-orange
      );
    }

    // Default fallback
    return BadgeStyleData(
      icon: Icons.workspace_premium_outlined,
      iconColor: Color(0xFFB5294E),
      backgroundColor: Color(0xFFFDE8EE),
    );
  }
}
