import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/screens/home.dart';
import 'package:litly/services/session_service.dart';

// Halaman Register untuk pendaftaran akun baru Litly
class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Warna tema sesuai referensi desain
  final Color primaryPurple = Color(0xFF8550A0);
  final Color lavenderBg = Color(0xFFF7F0FC);
  final Color errorRed = Color(0xFFD32F2F);

  // Controller input form
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Pesan error real-time untuk setiap field
  String? nameError;
  String? emailError;
  String? pinError;
  String? passwordError;
  String? confirmPasswordError;

  // Toggle visibilitas password
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // Status proses registrasi
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pinController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Validasi Full Name secara real-time
  void _validateName(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        nameError = 'Nama lengkap wajib diisi';
      } else if (value.trim().length < 3) {
        nameError = 'Nama minimal 3 karakter';
      } else {
        nameError = null;
      }
    });
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

  // Validasi PIN keamanan secara real-time (opsional, jika diisi harus 6 digit)
  void _validatePin(String value) {
    setState(() {
      if (value.trim().isNotEmpty && value.trim().length != 6) {
        pinError = 'PIN harus terdiri dari 6 digit angka';
      } else {
        pinError = null;
      }
    });
  }

  // Validasi Password secara real-time
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        passwordError = 'Password wajib diisi';
      } else if (value.length < 6) {
        passwordError = 'Password minimal 6 karakter';
      } else {
        bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
        bool hasDigit = RegExp(r'[0-9]').hasMatch(value);
        if (!hasLetter || !hasDigit) {
          passwordError = 'Password harus kombinasi huruf dan angka';
        } else {
          passwordError = null;
        }
      }

      // Validasi ulang konfirmasi password jika sudah pernah diketik
      if (confirmPasswordController.text.isNotEmpty) {
        if (confirmPasswordController.text != value) {
          confirmPasswordError = 'Konfirmasi password tidak sama';
        } else {
          confirmPasswordError = null;
        }
      }
    });
  }

  // Validasi Confirm Password secara real-time
  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        confirmPasswordError = 'Konfirmasi password wajib diisi';
      } else if (value != passwordController.text) {
        confirmPasswordError = 'Konfirmasi password harus sama dengan password';
      } else {
        confirmPasswordError = null;
      }
    });
  }

  // Memeriksa apakah seluruh field valid untuk mengaktifkan tombol Register
  bool get isFormValid {
    return nameError == null &&
        emailError == null &&
        pinError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;
  }

  // Proses pendaftaran akun ke SQLite dan auto-login
  void _handleRegister() async {
    if (!isFormValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      DbHelper db = DbHelper();
      String email = emailController.text.trim();

      // 1. Periksa apakah email sudah terdaftar di SQLite
      bool emailExists = await db.checkEmailExists(email);
      if (emailExists) {
        if (!mounted) return;
        setState(() {
          emailError = 'Email sudah terdaftar, gunakan email lain';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email sudah terdaftar. Silakan login atau gunakan email lain.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: errorRed,
          ),
        );
        return;
      }

      // 2. Hash password sebelum disimpan ke database
      String hashedPassword = DbHelper.hashPassword(passwordController.text);

      // 3. Simpan data user ke SQLite menggunakan insertUser
      String pin = pinController.text.trim().isEmpty ? '123456' : pinController.text.trim();
      UserModel newUser = UserModel(
        name: nameController.text.trim(),
        email: email,
        password: hashedPassword,
        securityPin: pin,
        createdAt: DateTime.now().toIso8601String(),
      );

      int newUserId = await db.insertUser(newUser);
      newUser.id = newUserId;

      // 4. Simpan session login otomatis ke SharedPreferences
      await SessionService.saveUserSession(
        user: newUser,
        rememberMe: true,
      );

      if (!mounted) return;

      // 5. Tampilkan SnackBar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registrasi berhasil! Selamat datang di Litly.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green[700],
        ),
      );

      // 6. Arahkan pengguna ke halaman Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            username: newUser.name,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registrasi gagal: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: errorRed,
        ),
      );
    } finally {
      // 7. Mekanisme finally untuk memastikan loading selalu kembali false
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
              SizedBox(height: 10),
              // Logo karakter litly di bagian atas
              Center(
                child: Image.asset(
                  'assets/images/litly_logo.png',
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 16),
              // Judul "Create Account"
              Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              // Subtitle "Let's get started!"
              Text(
                "Let's get started!",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // 1. Field Full Name
              Container(
                decoration: BoxDecoration(
                  color: lavenderBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  onChanged: _validateName,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
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
              if (nameError != null)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      nameError!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: errorRed,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 14),

              // 2. Field Email Address
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: errorRed,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 14),

              // 3. Field Security PIN (untuk pemulihan akun Forgot Password)
              Container(
                decoration: BoxDecoration(
                  color: lavenderBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: _validatePin,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Security PIN (6 digit angka)',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.pin_outlined,
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
              if (pinError != null)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      pinError!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: errorRed,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 14),

              // 4. Field Password
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: errorRed,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 14),

              // 5. Field Confirm Password
              Container(
                decoration: BoxDecoration(
                  color: lavenderBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  onChanged: _validateConfirmPassword,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
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
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
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
              if (confirmPasswordError != null)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      confirmPasswordError!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: errorRed,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 28),

              // Tombol Register
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (isFormValid && !isLoading)
                      ? _handleRegister
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    disabledBackgroundColor: primaryPurple.withValues(alpha: 0.45),
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
                          'Register',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Teks navigasi kembali ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Login',
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
