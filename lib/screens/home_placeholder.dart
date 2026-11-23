import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litly/screens/discover.dart';
import 'package:litly/screens/login.dart';
import 'package:litly/services/session_service.dart';

// Halaman placeholder Home sementara untuk pengujian login & sesi
class HomeScreenPlaceholder extends StatefulWidget {
  final String userName;
  final String userEmail;

  HomeScreenPlaceholder({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HomeScreenPlaceholder> createState() => _HomeScreenPlaceholderState();
}

class _HomeScreenPlaceholderState extends State<HomeScreenPlaceholder> {
  Color primaryPurple = Color(0xFF6A4D67);
  Color lavenderBg = Color(0xFFFAF8F3);

  // Fungsi logout akun
  void _logout() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Litly Home',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryPurple,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              // Logo karakter litly
              Center(
                child: Image.asset(
                  'assets/images/litly_logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Selamat Datang!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.userName.isNotEmpty ? widget.userName : 'Reader',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryPurple,
                ),
              ),
              SizedBox(height: 4),
              Text(
                widget.userEmail,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 28),
              // Kartu informasi placeholder
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: lavenderBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: primaryPurple),
                        SizedBox(width: 8),
                        Text(
                          'Informasi Proyek',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Halaman ini adalah halaman placeholder Home sementara. Sesi login berhasil disimpan di SharedPreferences dan akun tersimpan di database lokal SQLite.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fitur Reading Tracker (koleksi buku, target membaca, dan progres) akan dilanjutkan oleh anggota tim lainnya.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Tombol Buka Discover
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscoverScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.explore_rounded, color: Colors.white),
                  label: Text(
                    'Buka Discover (PB-010 & PB-011)',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF38323B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Tombol Logout
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text(
                    'Keluar (Logout)',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
