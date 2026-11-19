import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litly/database/db_helper.dart';

// Halaman Lupa Password dengan verifikasi PIN keamanan lokal
class ForgotPasswordScreen extends StatefulWidget {
  ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Warna tema sesuai referensi Litly
  final Color primaryPurple = Color(0xFF8550A0);
  final Color lavenderBg = Color(0xFFF7F0FC);
  final Color errorRed = Color(0xFFD32F2F);

  // Controller input form
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Pesan error real-time
  String? emailError;
  String? pinError;
  String? newPasswordError;
  String? confirmPasswordError;

  // Status tampilan form
  bool isVerified = false; // True jika email & PIN berhasil diverifikasi
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    pinController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Validasi format email secara real-time
  void _validateEmail(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        emailError = 'Email wajib diisi';
      } else {
        RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          emailError = 'Format email tidak valid';
        } else {
          emailError = null;
        }
      }
    });
  }

  // Validasi PIN keamanan secara real-time
  void _validatePin(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        pinError = 'PIN keamanan wajib diisi';
      } else if (value.trim().length != 6) {
        pinError = 'PIN harus terdiri dari 6 digit angka';
      } else {
        pinError = null;
      }
    });
  }

  // Validasi password baru secara real-time
  void _validateNewPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        newPasswordError = 'Password baru wajib diisi';
      } else if (value.length < 6) {
        newPasswordError = 'Password minimal 6 karakter';
      } else {
        bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
        bool hasDigit = RegExp(r'[0-9]').hasMatch(value);
        if (!hasLetter || !hasDigit) {
          newPasswordError = 'Password harus kombinasi huruf dan angka';
        } else {
          newPasswordError = null;
        }
      }

      // Validasi ulang konfirmasi password jika sudah terisi
      if (confirmPasswordController.text.isNotEmpty) {
        if (confirmPasswordController.text != value) {
          confirmPasswordError = 'Konfirmasi password tidak cocok';
        } else {
          confirmPasswordError = null;
        }
      }
    });
  }

  // Validasi konfirmasi password secara real-time
  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        confirmPasswordError = 'Konfirmasi password wajib diisi';
      } else if (value != newPasswordController.text) {
        confirmPasswordError = 'Konfirmasi password tidak cocok';
      } else {
        confirmPasswordError = null;
      }
    });
  }

  // Cek apakah form verifikasi PIN sudah valid
  bool get isVerifyFormValid {
    return emailError == null &&
        pinError == null &&
        emailController.text.trim().isNotEmpty &&
        pinController.text.trim().isNotEmpty;
  }

  // Cek apakah form password baru sudah valid
  bool get isResetFormValid {
    return newPasswordError == null &&
        confirmPasswordError == null &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;
  }

  // Proses verifikasi akun & PIN di SQLite
  void _handleVerifyPin() async {
    if (!isVerifyFormValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      DbHelper db = DbHelper();
      bool emailExists = await db.checkEmailExists(emailController.text.trim());

      if (!emailExists) {
        if (!mounted) return;
        setState(() {
          emailError = 'Email tidak ditemukan';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email tidak ditemukan dalam sistem',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: errorRed,
          ),
        );
        return;
      }

      bool isPinValid = await db.verifySecurityPin(
        emailController.text.trim(),
        pinController.text.trim(),
      );

      if (!mounted) return;

      if (isPinValid) {
        setState(() {
          isVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN valid! Silakan masukkan password baru.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        setState(() {
          pinError = 'PIN keamanan salah';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN keamanan salah, coba lagi.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: errorRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verifikasi gagal: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Proses simpan password baru ke SQLite
  void _handleResetPassword() async {
    if (!isResetFormValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      DbHelper db = DbHelper();
      String newHash = DbHelper.hashPassword(newPasswordController.text);
      int result = await db.updatePassword(emailController.text.trim(), newHash);

      if (!mounted) return;

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kata sandi berhasil diperbarui! Silakan login.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green[700],
          ),
        );
        // Kembali ke halaman Login
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui kata sandi. Coba lagi.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: errorRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan kata sandi: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: errorRed,
        ),
      );
    } finally {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo karakter litly
              Center(
                child: Image.asset(
                  'assets/images/litly_logo.png',
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 16),
              // Judul Halaman
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              // Subtitle
              Text(
                isVerified
                    ? 'Buat kata sandi baru untuk akun Anda'
                    : 'Masukkan email dan 6-digit PIN keamanan lokal',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 28),

              // Bagian 1: Verifikasi Email & PIN
              if (!isVerified) ...[
                // Input Email Address
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Address',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 6),
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

                SizedBox(height: 16),

                // Input Security PIN
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Security PIN (6 Angka)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 6),
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
                    style: GoogleFonts.poppins(fontSize: 14, letterSpacing: 3),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '6-digit PIN',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        letterSpacing: 0,
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

                SizedBox(height: 28),

                // Tombol Verifikasi
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (isVerifyFormValid && !isLoading)
                        ? _handleVerifyPin
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      disabledBackgroundColor: primaryPurple.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: (isVerifyFormValid && !isLoading) ? 4 : 0,
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
                            'Verifikasi PIN',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],

              // Bagian 2: Password Baru setelah verifikasi berhasil
              if (isVerified) ...[
                // Banner verifikasi berhasil
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green[700]),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verifikasi sukses untuk:\n${emailController.text}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Input New Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'New Password',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: lavenderBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    onChanged: _validateNewPassword,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'New Password',
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
                          obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
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
                if (newPasswordError != null)
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        newPasswordError!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: errorRed,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 16),

                // Input Confirm Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confirm New Password',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 6),
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
                      hintText: 'Confirm New Password',
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

                // Tombol Simpan Password Baru
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (isResetFormValid && !isLoading)
                        ? _handleResetPassword
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      disabledBackgroundColor: primaryPurple.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: (isResetFormValid && !isLoading) ? 4 : 0,
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
                            'Simpan Password Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],

              SizedBox(height: 24),

              // Kembali ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ingat kata sandi Anda? ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
