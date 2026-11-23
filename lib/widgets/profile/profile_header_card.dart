import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/widgets/user_avatar.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key});

  String _formatMemberSince(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Anggota baru';
    try {
      final date = DateTime.parse(createdAt);
      return 'Bergabung sejak ${date.month.toString().padLeft(2, '0')}/${date.year}';
    } on FormatException {
      return 'Anggota baru';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final displayName = user != null && user.name.isNotEmpty
        ? user.name
        : 'Pembaca Litly';
    final displayEmail = user != null && user.email.isNotEmpty
        ? user.email
        : 'reader@litly.com';

    return SizedBox(
      height: 224,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 164,
            child: ClipPath(
              clipper: _ProfileHeaderClipper(),
              child: const ColoredBox(color: AppColors.kYellow),
            ),
          ),
          Positioned(
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.kNavy.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: UserAvatar(
                avatar: user?.avatar,
                name: displayName,
                size: 96,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 24,
            right: 24,
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.kNavy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: 24,
            right: 24,
            child: Text(
              displayEmail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Positioned(
            top: 173,
            left: 24,
            right: 24,
            child: Text(
              _formatMemberSince(user?.createdAt),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.25,
        size.height * 1.12,
        size.width * 0.72,
        size.height * 0.55,
        size.width,
        size.height * 0.83,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
