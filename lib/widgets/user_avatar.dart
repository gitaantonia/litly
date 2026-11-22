import 'dart:io';
import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';

// // BARU: Widget foto profil serbaguna (mendukung null/kosong, assets, dan file lokal)
class UserAvatar extends StatelessWidget {
  final String? avatar;
  final String name;
  final double size;

  UserAvatar({
    Key? key,
    this.avatar,
    required this.name,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    Widget fallbackLetter = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryPurple,
        ),
      ),
    );

    // Kasus 1: avatar kosong atau null
    if (avatar == null || avatar!.trim().isEmpty) {
      return fallbackLetter;
    }

    String path = avatar!.trim();

    // Kasus 2: avatar bawaan dari assets
    if (path.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return fallbackLetter;
          },
        ),
      );
    }

    // Kasus 3: path file foto milik pengguna di penyimpanan lokal
    File file = File(path);
    return ClipOval(
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return fallbackLetter;
        },
      ),
    );
  }
}
