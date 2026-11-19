import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/book_service.dart';
import '../services/session_service.dart';
import 'login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  Future<void> _logout(BuildContext context) async {
    await BookService().clearUsername();
    await SessionService.clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      children: [
        Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF252A3D),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFF0F1F6),
                child: Text(
                  username.isEmpty ? '?' : username[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E365A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                username,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Pembaca Litly',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: Text('Keluar', style: GoogleFonts.poppins(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}
