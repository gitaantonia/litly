import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/book_service.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  final _service = BookService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  /// Jika sudah pernah login, langsung ke Home
  Future<void> _checkExistingUser() async {
    final name = await _service.getUsername();
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      _goHome(name);
    } else {
      setState(() => _loading = false);
    }
  }

  void _goHome(String name) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(username: name)),
    );
  }

  Future<void> _login() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan nama kamu dulu!',
              style: GoogleFonts.poppins()),
          backgroundColor: kPurple,
        ),
      );
      return;
    }
    await _service.saveUsername(name);
    if (!mounted) return;
    _goHome(name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kPurple)),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 72),

              // Judul
              Text(
                'Halo! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: kPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Siapa nama kamu?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 48),

              // Input Nama
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: 'Nama kamu...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38),
                  filled: true,
                  fillColor: kLightPurple,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
              ),

              const SizedBox(height: 24),

              // Tombol Masuk
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Membaca 📚',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Mascot kecil di bawah
              Center(
                child: Image.asset(
                  'assets/images/liti_mascot.png',
                  width: 120,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
