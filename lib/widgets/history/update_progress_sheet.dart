import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/achievement_provider.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/book_history_provider.dart';
import 'package:litly/providers/goal_provider.dart';

// BARU: Modal bottom sheet untuk memperbarui progres halaman dan mencatat sesi
class UpdateProgressSheet extends StatefulWidget {
  final int bookId;
  final String bookTitle;
  final int currentPage;
  final int totalPages;

  UpdateProgressSheet({
    Key? key,
    required this.bookId,
    required this.bookTitle,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  _UpdateProgressSheetState createState() => _UpdateProgressSheetState();
}

class _UpdateProgressSheetState extends State<UpdateProgressSheet> {
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _pageError;
  String? _durationError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController.text = widget.currentPage > 0 ? widget.currentPage.toString() : '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Validasi input form secara real-time
  void _validate() {
    setState(() {
      String pageStr = _pageController.text.trim();
      String durationStr = _durationController.text.trim();

      // 1. Validasi halaman
      if (pageStr.isEmpty) {
        _pageError = 'Masukkan angka halaman yang valid';
      } else {
        int? page = int.tryParse(pageStr);
        if (page == null || page < 0) {
          _pageError = 'Masukkan angka halaman yang valid';
        } else if (page > widget.totalPages && widget.totalPages > 0) {
          _pageError = 'Maksimal ${widget.totalPages} halaman';
        } else if (page == widget.currentPage && durationStr.isEmpty) {
          _pageError = 'Halaman sama dengan sebelumnya';
        } else {
          _pageError = null;
        }
      }

      // 2. Validasi durasi jika diisi
      if (durationStr.isNotEmpty) {
        int? duration = int.tryParse(durationStr);
        if (duration == null || duration < 0 || duration > 1440) {
          _durationError = 'Durasi tidak valid';
        } else {
          _durationError = null;
        }
      } else {
        _durationError = null;
      }
    });
  }

  // Cek apakah tombol simpan dapat diaktifkan
  bool get _isFormValid {
    if (_pageError != null || _durationError != null) return false;
    String pageStr = _pageController.text.trim();
    if (pageStr.isEmpty) return false;

    int? newPage = int.tryParse(pageStr);
    if (newPage == null) return false;

    String durationStr = _durationController.text.trim();
    int duration = int.tryParse(durationStr) ?? 0;

    // Ada perubahan halaman atau durasi membaca dicatat
    if (newPage == widget.currentPage && duration == 0) {
      return false;
    }
    return true;
  }

  // Simpan progres ke database / provider
  Future<void> _submit() async {
    String pageStr = _pageController.text.trim();
    int? newPage = int.tryParse(pageStr);
    if (newPage == null) return;

    String durationStr = _durationController.text.trim();
    int duration = int.tryParse(durationStr) ?? 0;

    // Jika halaman lebih kecil dari sebelumnya, tampilkan konfirmasi revisi
    if (newPage < widget.currentPage) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Konfirmasi Revisi Halaman',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Halamanmu lebih kecil dari sebelumnya. Apakah kamu membaca ulang atau ingin merevisi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1F1F3D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Ya, Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      BookHistoryProvider historyProvider =
          Provider.of<BookHistoryProvider>(context, listen: false);
      int userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;

      String? error = await historyProvider.saveProgress(
        bookId: widget.bookId,
        newPage: newPage,
        durationMinutes: duration,
      );

      if (error != null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      // Berhasil disimpan
      if (!mounted) return;
      Navigator.pop(context); // Tutup bottom sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress berhasil diperbarui'),
          backgroundColor: Color(0xFFB5294E),
        ),
      );

      // Jika buku baru saja selesai, tampilkan dialog perayaan
      if (newPage >= widget.totalPages && widget.totalPages > 0) {
        _showCelebrationDialog(widget.bookTitle);
      }

      // Panggil verifikasi lencana dan target harian
      if (context.mounted) {
        context.read<AchievementProvider>().checkAndShow(context, userId); // cek lencana
        context.read<GoalProvider>().checkGoalAndCelebrate(context, userId); // cek target harian
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  // Dialog perayaan saat buku berhasil diselesaikan
  void _showCelebrationDialog(String bookTitle) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Color(0xFFFDE8EE),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '🎉',
                          style: TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Text(
                'Selamat! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Kamu telah menyelesaikan $bookTitle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB5294E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Mantap!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis handle atas
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 18),

              // Judul & Subjudul
              Text(
                'Update Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Sebelumnya: p. ${widget.currentPage} dari ${widget.totalPages}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 20),

              // Field 1: Halaman terakhir dibaca
              Text(
                'Halaman terakhir dibaca',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _validate(),
                decoration: InputDecoration(
                  hintText: 'Contoh: 124',
                  errorText: _pageError,
                  prefixIcon: Icon(Icons.menu_book, color: Color(0xFFB5294E)),
                  filled: true,
                  fillColor: isDarkMode ? Color(0xFF282846) : Color(0xFFF1EEFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 16),

              // Field 2: Durasi membaca (menit), opsional
              Text(
                'Durasi membaca (menit), opsional',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _validate(),
                decoration: InputDecoration(
                  hintText: 'Contoh: 28',
                  errorText: _durationError,
                  prefixIcon: Icon(Icons.timer_outlined, color: Colors.orange[700]),
                  filled: true,
                  fillColor: isDarkMode ? Color(0xFF282846) : Color(0xFFF1EEFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1F1F3D), // Navy
                    disabledBackgroundColor: Color(0xFF1F1F3D).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 10),

              // Tombol Batal
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
