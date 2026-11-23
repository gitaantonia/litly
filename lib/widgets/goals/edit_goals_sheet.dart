import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/achievement_provider.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/widgets/auth/auth_text_field.dart';

// Bottom sheet untuk menyesuaikan 4 target membaca (PB-035, PB-036, PB-038)
class EditGoalsSheet extends StatefulWidget {
  final int userId;
  final int initialDailyPages;
  final int initialDailyMinutes;
  final int initialMonthlyBooks;
  final int initialAnnualBooks;

  EditGoalsSheet({
    Key? key,
    required this.userId,
    required this.initialDailyPages,
    required this.initialDailyMinutes,
    required this.initialMonthlyBooks,
    required this.initialAnnualBooks,
  }) : super(key: key);

  @override
  _EditGoalsSheetState createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<EditGoalsSheet> {
  final TextEditingController _dailyPagesController = TextEditingController();
  final TextEditingController _dailyMinutesController = TextEditingController();
  final TextEditingController _monthlyBooksController = TextEditingController();
  final TextEditingController _annualBooksController = TextEditingController();

  String? _dailyPagesError;
  String? _dailyMinutesError;
  String? _monthlyBooksError;
  String? _annualBooksError;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Isi field dengan nilai saat ini (jika 0 biarkan kosong agar mudah diketik)
    _dailyPagesController.text = widget.initialDailyPages > 0
        ? widget.initialDailyPages.toString()
        : '';
    _dailyMinutesController.text = widget.initialDailyMinutes > 0
        ? widget.initialDailyMinutes.toString()
        : '';
    _monthlyBooksController.text = widget.initialMonthlyBooks > 0
        ? widget.initialMonthlyBooks.toString()
        : '';
    _annualBooksController.text = widget.initialAnnualBooks > 0
        ? widget.initialAnnualBooks.toString()
        : '';
  }

  @override
  void dispose() {
    _dailyPagesController.dispose();
    _dailyMinutesController.dispose();
    _monthlyBooksController.dispose();
    _annualBooksController.dispose();
    super.dispose();
  }

  // Validasi nilai angka target
  String? _validateGoal(String val, int maxLimit) {
    String text = val.trim();
    if (text.isEmpty) {
      return null; // Kosong artinya tidak diatur (disimpan 0)
    }

    int? numVal = int.tryParse(text);
    if (numVal == null || numVal <= 0) {
      return 'Masukkan angka lebih dari 0';
    }
    if (numVal > maxLimit) {
      return 'Maksimal $maxLimit';
    }
    return null;
  }

  void _onDailyPagesChanged(String val) {
    setState(() {
      _dailyPagesError = _validateGoal(val, 1000);
    });
  }

  void _onDailyMinutesChanged(String val) {
    setState(() {
      _dailyMinutesError = _validateGoal(val, 1440);
    });
  }

  void _onMonthlyBooksChanged(String val) {
    setState(() {
      _monthlyBooksError = _validateGoal(val, 100);
    });
  }

  void _onAnnualBooksChanged(String val) {
    setState(() {
      _annualBooksError = _validateGoal(val, 1000);
    });
  }

  // Memeriksa apakah semua field valid dan ada perubahan dari nilai awal
  bool get _isFormValid {
    if (_dailyPagesError != null ||
        _dailyMinutesError != null ||
        _monthlyBooksError != null ||
        _annualBooksError != null) {
      return false;
    }

    int currentPages = int.tryParse(_dailyPagesController.text.trim()) ?? 0;
    int currentMinutes = int.tryParse(_dailyMinutesController.text.trim()) ?? 0;
    int currentMonthly = int.tryParse(_monthlyBooksController.text.trim()) ?? 0;
    int currentAnnual = int.tryParse(_annualBooksController.text.trim()) ?? 0;

    bool hasChanged =
        currentPages != widget.initialDailyPages ||
        currentMinutes != widget.initialDailyMinutes ||
        currentMonthly != widget.initialMonthlyBooks ||
        currentAnnual != widget.initialAnnualBooks;

    return hasChanged;
  }

  void _handleSave() async {
    if (!_isFormValid || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    int pages = int.tryParse(_dailyPagesController.text.trim()) ?? 0;
    int minutes = int.tryParse(_dailyMinutesController.text.trim()) ?? 0;
    int monthly = int.tryParse(_monthlyBooksController.text.trim()) ?? 0;
    int annual = int.tryParse(_annualBooksController.text.trim()) ?? 0;

    GoalProvider provider = Provider.of<GoalProvider>(context, listen: false);
    final achievementProvider = context.read<AchievementProvider>();
    String? error = await provider.saveGoals(
      widget.userId,
      pages,
      minutes,
      monthly,
      annual,
    );
    String? achievementWarning;
    if (error == null) {
      try {
        await achievementProvider.checkAndShow(widget.userId);
      } on Exception catch (exception) {
        achievementWarning =
            'Target tersimpan, tetapi achievement gagal diperbarui: $exception';
      }
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(achievementWarning ?? 'Target berhasil diperbarui'),
          backgroundColor: achievementWarning == null
              ? Colors.green[700]
              : Colors.orange[800],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Judul & Tombol Batal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sesuaikan Target',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Field 1: Halaman per hari
            AuthTextField(
              controller: _dailyPagesController,
              label: 'Halaman per hari',
              hintText: 'Contoh: 20',
              prefixIcon: Icons.menu_book,
              keyboardType: TextInputType.number,
              errorText: _dailyPagesError,
              onChanged: _onDailyPagesChanged,
            ),
            SizedBox(height: 14),

            // Field 2: Menit per hari
            AuthTextField(
              controller: _dailyMinutesController,
              label: 'Menit per hari',
              hintText: 'Contoh: 30',
              prefixIcon: Icons.timer,
              keyboardType: TextInputType.number,
              errorText: _dailyMinutesError,
              onChanged: _onDailyMinutesChanged,
            ),
            SizedBox(height: 14),

            // Field 3: Buku per bulan
            AuthTextField(
              controller: _monthlyBooksController,
              label: 'Buku per bulan',
              hintText: 'Contoh: 4',
              prefixIcon: Icons.auto_stories,
              keyboardType: TextInputType.number,
              errorText: _monthlyBooksError,
              onChanged: _onMonthlyBooksChanged,
            ),
            SizedBox(height: 14),

            // Field 4: Buku per tahun
            AuthTextField(
              controller: _annualBooksController,
              label: 'Buku per tahun',
              hintText: 'Contoh: 24',
              prefixIcon: Icons.emoji_events,
              keyboardType: TextInputType.number,
              errorText: _annualBooksError,
              onChanged: _onAnnualBooksChanged,
            ),
            SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kNavyDark,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                onPressed: _isFormValid && !_isSaving ? _handleSave : null,
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
