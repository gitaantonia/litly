import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/screens/forgot_password.dart';
import 'package:litly/screens/home.dart';
import 'package:litly/screens/register.dart';
import 'package:litly/services/session_service.dart';

// Halaman Login aplikasi Litly
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Warna tema sesuai referensi desain
  final Color primaryPurple = Color(0xFF8550A0);
  final Color lavenderBg = Color(0xFFF7F0FC);
  final Color errorRed = Color(0xFFD32F2F);

  // Controller input form
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Pesan error real-time
  String? emailError;
  String? passwordError;

  // Status toggle
  bool obscurePassword = true;
  bool rememberMe = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Validasi Email secara real-time
  void _validateEmail(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        emailError = 'Email wajib diisi';
      } else {
        RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          emailError = 'Format email tidak valid (contoh: user@mail.com)';
        } else {
          emailError = null;
        }
      }
    });
  }

  // Validasi Password secara real-time
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        passwordError = 'Password wajib diisi';
      } else {
        passwordError = null;
      }
    });
  }

  // Cek apakah seluruh input valid untuk mengaktifkan tombol Login
  bool get isFormValid {
    return emailError == null &&
        passwordError == null &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  // Proses login pengguna dengan SQLite dan SharedPreferences
  void _handleLogin() async {
    if (!isFormValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      DbHelper db = DbHelper();
      String email = emailController.text.trim();
      String password = passwordController.text;

      Map<String, dynamic> result = await db.loginUser(email, password);

      if (!mounted) return;

      String status = result['status'];

      if (status == 'not_found') {
        setState(() {
          emailError = 'Email tidak ditemukan';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email tidak ditemukan',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: errorRed,
          ),
        );
      } else if (status == 'wrong_password') {
        setState(() {
          passwordError = 'Kata sandi salah';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kata sandi salah', style: GoogleFonts.poppins()),
            backgroundColor: errorRed,
          ),
        );
      } else if (status == 'success') {
        UserModel loggedInUser = result['user'];

        // Simpan session login ke SharedPreferences
        await SessionService.saveUserSession(
          user: loggedInUser,
          rememberMe: rememberMe,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login berhasil! Selamat datang kembali, ${loggedInUser.name}.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green[700],
          ),
        );

        // Arahkan ke halaman Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: loggedInUser.name),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login gagal: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: errorRed,
        ),
      );
    } finally {
      // Pastikan loading selalu kembali false
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              // Logo karakter litly di bagian atas
              Center(
                child: Image.asset(
                  'assets/images/litly_logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 16),
              // Judul "Welcome Back!"
              Text(
                'Welcome Back!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              // Subtitle "Login to continue your journey"
              Text(
                'Login to continue your journey',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 28),

              // Label Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 6),

              // Input Email Address
              Container(
                decoration: BoxDecoration(
                  color: lavenderBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: primaryPurple,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (emailError != null)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      emailError!,
                      style: GoogleFonts.poppins(fontSize: 12, color: errorRed),
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Label Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 6),

              // Input Password
              Container(
                decoration: BoxDecoration(
                  color: lavenderBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  onChanged: _validatePassword,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: primaryPurple,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (passwordError != null)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      passwordError!,
                      style: GoogleFonts.poppins(fontSize: 12, color: errorRed),
                    ),
                  ),
                ),

              SizedBox(height: 8),

              // Baris Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fitur Remember Me
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: rememberMe,
                          activeColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rememberMe = !rememberMe;
                          });
                        },
                        child: Text(
                          'Remember Me',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tombol Forgot Password?
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 28),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (isFormValid && !isLoading) ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    disabledBackgroundColor: primaryPurple.withValues(
                      alpha: 0.45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: (isFormValid && !isLoading) ? 4 : 0,
                    shadowColor: primaryPurple.withValues(alpha: 0.4),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Teks navigasi ke Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Register',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
