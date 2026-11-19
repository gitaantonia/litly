import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/book_service.dart';
import '../services/focus_timer_service.dart';
import '../state/app_state.dart';

// Halaman Focus Timer untuk mencatat sesi fokus membaca
class FocusTimerScreen extends StatefulWidget {
  final Book? initialBook;

  FocusTimerScreen({super.key, this.initialBook});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  final FocusTimerService timerService = FocusTimerService();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi buku jika diberikan dan belum ada buku aktif
    if (widget.initialBook != null && timerService.selectedBook == null) {
      timerService.setSelectedBook(widget.initialBook);
    }
    timerService.addListener(_onTimerUpdate);
  }

  @override
  void dispose() {
    timerService.removeListener(_onTimerUpdate);
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  // Menampilkan modal pemilihan buku dari koleksi perpustakaan
  void _showBookPicker(List<Book> books) {
    if (timerService.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jeda timer terlebih dahulu sebelum mengganti buku.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: kPurple,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Buku untuk Sesi Fokus',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                SizedBox(height: 12),
                if (books.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada buku di My Library.',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: books.length,
                      separatorBuilder: (_, _) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final isSelected = timerService.selectedBook?.id == book.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.book_rounded,
                            color: isSelected ? kPurple : Colors.grey,
                          ),
                          title: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? kPurple : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            book.author,
                            maxLines: 1,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: kPurple)
                              : null,
                          onTap: () {
                            timerService.setSelectedBook(book);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Menampilkan modal pemilihan durasi timer (PB-032)
  void _showDurationPicker() {
    if (timerService.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jeda atau reset timer terlebih dahulu sebelum mengubah durasi.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: kPurple,
        ),
      );
      return;
    }

    final durations = [15, 25, 30, 45, 60];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengaturan Durasi Fokus',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pilih durasi waktu untuk sesi membaca kamu:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: durations.map((mins) {
                    final isCurrent = timerService.totalDurationSeconds == mins * 60;
                    return ChoiceChip(
                      label: Text(
                        '$mins Menit',
                        style: GoogleFonts.poppins(
                          color: isCurrent ? Colors.white : kNavy,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isCurrent,
                      selectedColor: kNavy,
                      backgroundColor: kLavender,
                      onSelected: (selected) {
                        if (selected) {
                          timerService.setDuration(mins);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // Menyelesaikan dan menyimpan sesi membaca ke SQLite (PB-033 & PB-034)
  void _completeAndSaveSession() async {
    if (isSaving) return; // Mencegah double submit

    setState(() {
      isSaving = true;
    });

    try {
      final bookService = BookService();
      final appState = Provider.of<AppState>(context, listen: false);

      final String sessionBookTitle = timerService.selectedBook != null
          ? timerService.selectedBook!.title
          : 'Membaca Bebas';

      final String? sessionBookId = timerService.selectedBook?.id;
      final int spentMinutes = timerService.elapsedMinutes;
      final int spentSeconds = timerService.totalDurationSeconds - timerService.remainingSeconds;
      final int loggedPages = timerService.pagesRead;

      // 1. Buat data sesi membaca
      final session = ReadingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: sessionBookId,
        bookTitle: sessionBookTitle,
        durationMinutes: spentMinutes,
        durationSeconds: spentSeconds > 0 ? spentSeconds : spentMinutes * 60,
        pagesRead: loggedPages,
        createdAt: DateTime.now(),
      );

      // 2. Simpan sesi membaca ke SQLite
      await bookService.addReadingSession(session);

      // 3. Update progres halaman buku jika ada buku yang dipilih
      if (sessionBookId != null && loggedPages > 0) {
        final updated = await bookService.updateBookProgress(sessionBookId, loggedPages);
        if (updated != null) {
          await appState.loadBooks();
        }
      }

      if (!mounted) return;

      // 4. Tampilkan dialog ringkasan sesi membaca (PB-033)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final timeStr = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB";
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 28),
                SizedBox(width: 10),
                Text(
                  'Sesi Selesai!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Sesi Membaca:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 12),
                _summaryRow('Buku', sessionBookTitle),
                SizedBox(height: 8),
                _summaryRow('Durasi', '$spentMinutes menit'),
                SizedBox(height: 8),
                _summaryRow('Halaman', '$loggedPages halaman'),
                SizedBox(height: 8),
                _summaryRow('Waktu', timeStr),
                SizedBox(height: 8),
                _summaryRow('Status', 'Berhasil Disimpan ✓'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Tutup & Kembali',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );

      // 5. Reset timer ke keadaan semula
      timerService.resetSessionAfterSave();

      if (!mounted) return;

      // 6. SnackBar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sesi fokus membaca berhasil disimpan!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green[700],
        ),
      );

      // 7. Kembali ke halaman Home
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan sesi: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bookList = appState.books;

    // Jika belum ada buku yang dipilih, ambil buku reading pertama dari perpustakaan
    if (timerService.selectedBook == null && bookList.isNotEmpty) {
      final candidate = bookList.firstWhere(
        (b) => b.status == 'Currently Reading' || !b.isFinished,
        orElse: () => bookList.first,
      );
      timerService.setSelectedBook(candidate);
    }

    final book = timerService.selectedBook;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Focus Timer',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: kNavy),
            tooltip: 'Pengaturan Durasi',
            onPressed: _showDurationPicker,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Kartu Info Buku yang sedang dibaca
              GestureDetector(
                onTap: () => _showBookPicker(bookList),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kLavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, color: kPurple, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book != null ? book.title : 'Pilih Buku Bacaan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kNavy,
                              ),
                            ),
                            Text(
                              book != null ? book.author : 'Ketuk untuk memilih buku',
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: kNavy),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 28),

              // 2. Lingkaran Timer Besar Berwarna Kuning Muda
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lingkaran luar background
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 14,
                          valueColor: AlwaysStoppedAnimation<Color>(kLavender),
                        ),
                      ),
                      // Progress lingkaran warna kuning muda sesuai desain
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: timerService.timerProgress,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(kYellow),
                        ),
                      ),
                      // Teks waktu di dalam lingkaran
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timerService.formattedTime,
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: kNavy,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            timerService.isRunning
                                ? 'FOCUS FLOW'
                                : timerService.isPaused
                                ? 'PAUSED'
                                : (timerService.status == FocusTimerStatus.completed
                                    ? 'SESI SELESAI'
                                    : 'SIAP MEMBACA'),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: kPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 28),

              // 3. Tombol Pause Flow / Start Flow dan Kontrol Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tombol Reset
                  Container(
                    decoration: BoxDecoration(
                      color: kLavender,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.refresh_rounded, color: kNavy),
                      tooltip: 'Reset Timer',
                      onPressed: timerService.resetTimer,
                    ),
                  ),

                  SizedBox(width: 16),

                  // Tombol Utama "Pause Flow" / "Start Flow"
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: timerService.toggleTimer,
                      icon: Icon(
                        timerService.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      label: Text(
                        timerService.isRunning
                            ? 'Pause Flow'
                            : (timerService.isPaused ? 'Resume Flow' : 'Start Flow'),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNavy,
                        padding: EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Tombol Centang untuk menyelesaikan sesi secara manual
                  Container(
                    decoration: BoxDecoration(
                      color: kLavender,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.check_rounded, color: Colors.green[700]),
                      tooltip: 'Selesaikan Sesi',
                      onPressed: timerService.completeTimer,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 28),

              // 4. Bagian Log Session Progress (PB-034)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: kPurple),
                        SizedBox(width: 8),
                        Text(
                          'Log Session Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Berapa halaman yang kamu baca dalam sesi ini?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tombol minus
                        InkWell(
                          onTap: timerService.decrementPages,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kLavender,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.remove_rounded, color: kNavy),
                          ),
                        ),
                        SizedBox(width: 24),
                        // Nilai halaman
                        Text(
                          '${timerService.pagesRead} Halaman',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                          ),
                        ),
                        SizedBox(width: 24),
                        // Tombol plus
                        InkWell(
                          onTap: timerService.incrementPages,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kLavender,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_rounded, color: kNavy),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // 5. Bagian Informasi Streak Secured
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFFCE08B)),
                ),
                child: Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Streak Secured!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8A5A00),
                            ),
                          ),
                          Text(
                            'Sesi fokus membaca ini akan memperbarui target harianmu.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Color(0xFF8A5A00).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // 6. Tombol Complete & Save Session (PB-033 & PB-034)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _completeAndSaveSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple,
                    disabledBackgroundColor: kPurple.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Complete & Save Session',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
