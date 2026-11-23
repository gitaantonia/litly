import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/colors.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/book_service.dart';
import '../state/app_state.dart';

// Halaman Statistik dan Kebiasaan Membaca Litly (PB-010 & PB-011 / PB-023)
class StatisticsScreen extends StatefulWidget {
  final BookService? bookService;
  final List<ReadingSession>? initialSessions;
  final List<Book>? initialBooks;
  final int? initialAnnualGoal;

  StatisticsScreen({
    super.key,
    this.bookService,
    this.initialSessions,
    this.initialBooks,
    this.initialAnnualGoal,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final BookService _bookService;

  // Filter periode aktif: 'This Week', 'This Month', 'Year'
  String _selectedPeriod = 'This Week';

  bool _isLoading = true;
  String? _errorMessage;

  List<ReadingSession> _allSessions = [];
  List<Book> _allBooks = [];
  int _annualGoalTarget = 24;
  int? _lastAppDataVersion;

  @override
  void initState() {
    super.initState();
    _bookService = widget.bookService ?? BookService();

    if (widget.initialSessions != null || widget.initialBooks != null || widget.initialAnnualGoal != null) {
      _allSessions = widget.initialSessions ?? [];
      _allBooks = widget.initialBooks ?? [];
      _annualGoalTarget = widget.initialAnnualGoal ?? 24;
      _isLoading = false;
    } else {
      _loadStatisticsData();
    }
  }

  // Memuat data dari database SQLite dan preferensi lokal
  Future<void> _loadStatisticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessions = await _bookService.getReadingSessions();
      final books = await _bookService.getBooks();
      final currentYear = _now.year;
      final annualGoal = await _bookService.getAnnualReadingGoal(currentYear);

      if (mounted) {
        setState(() {
          _allSessions = sessions;
          _allBooks = books;
          _annualGoalTarget = annualGoal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data statistik. Silakan coba kembali.';
          _isLoading = false;
        });
      }
    }
  }

  DateTime get _now =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  // Menentukan rentang tanggal berdasarkan tab periode yang dipilih
  DateTimeRange _getPeriodRange() {
    final now = _now;
    if (_selectedPeriod == 'This Week') {
      final startOfWeek = DateTime.utc(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );
      return DateTimeRange(
        start: startOfWeek,
        end: startOfWeek.add(const Duration(days: 7)),
      );
    } else if (_selectedPeriod == 'This Month') {
      final startOfMonth = DateTime.utc(now.year, now.month);
      return DateTimeRange(
        start: startOfMonth,
        end: DateTime.utc(now.year, now.month + 1),
      );
    } else {
      return DateTimeRange(
        start: DateTime.utc(now.year),
        end: DateTime.utc(now.year + 1),
      );
    }
  }

  // Mengambil daftar sesi membaca yang berada dalam periode yang dipilih
  List<ReadingSession> get _periodSessions {
    final range = _getPeriodRange();
    return _allSessions.where((s) {
      final createdAt = s.createdAtInWib;
      return !createdAt.isBefore(range.start) && createdAt.isBefore(range.end);
    }).toList();
  }

  // 1. Reading Time: Total durasi membaca dalam format Xh Ym
  int get _totalReadingMinutes {
    final totalSeconds = _periodSessions.fold(
      0,
      (total, session) => total + session.trackedDurationSeconds,
    );
    return totalSeconds ~/ 60;
  }

  String get _formattedReadingTime {
    final total = _totalReadingMinutes;
    final hours = total ~/ 60;
    final minutes = total % 60;
    return '${hours}h ${minutes}m';
  }

  // 2. Pages Read: Total halaman yang dibaca dalam periode
  int get _totalPagesRead {
    int sum = 0;
    for (final s in _periodSessions) {
      sum += s.pagesRead;
    }
    return sum;
  }

  // 3. Books Done: Jumlah buku yang sudah selesai dibaca di My Library
  List<Book> _completedBooks(List<Book> books) {
    return books
        .where((book) => book.status.trim().toLowerCase() == 'completed')
        .toList();
  }

  int _booksDoneCount(List<Book> books) => _completedBooks(books).length;

  // 4. Active Streak: Jumlah hari berturut-turut membaca hingga hari ini atau kemarin
  int get _activeStreak {
    if (_allSessions.isEmpty) return 0;

    final now = _now;
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Kumpulan tanggal unik membaca
    final Set<DateTime> readDays = _allSessions
        .where(
          (session) =>
              session.trackedDurationSeconds > 0 || session.pagesRead > 0,
        )
        .map((session) => session.readingDateInWib)
        .toSet();

    if (readDays.contains(today)) {
      int streak = 1;
      DateTime checkDate = today.subtract(Duration(days: 1));
      while (readDays.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      }
      return streak;
    } else if (readDays.contains(yesterday)) {
      int streak = 1;
      DateTime checkDate = yesterday.subtract(Duration(days: 1));
      while (readDays.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      }
      return streak;
    } else {
      return 0;
    }
  }

  // 5. Top Genre: Kategori buku yang paling sering dibaca
  String _topGenreFor(List<Book> books) {
    final Map<String, int> genreCounts = {};
    final Map<String, String> genreLabels = {};

    for (final s in _periodSessions) {
      if (s.bookId != null && s.bookId!.isNotEmpty) {
        final book = books.where((b) => b.id == s.bookId).firstOrNull;
        if (book != null && book.category != null && book.category!.trim().isNotEmpty) {
          final cat = book.category!.trim();
          final key = cat.toLowerCase();
          genreLabels.putIfAbsent(key, () => cat);
          genreCounts[key] =
              (genreCounts[key] ?? 0) + (s.pagesRead > 0 ? s.pagesRead : 1);
        }
      }
    }

    if (genreCounts.isEmpty) {
      return 'Belum tersedia';
    }

    String topCategoryKey = '';
    int maxCount = 0;
    genreCounts.forEach((genre, count) {
      if (count > maxCount) {
        maxCount = count;
        topCategoryKey = genre;
      }
    });

    return genreLabels[topCategoryKey]!;
  }

  // 6. Reading Velocity: Distribusi durasi membaca per hari dalam seminggu (M, T, W, T, F, S, S)
  List<int> get _dailyReadingMinutes {
    final List<int> secondsPerDay = [0, 0, 0, 0, 0, 0, 0];

    for (final s in _periodSessions) {
      final dayIndex = s.createdAtInWib.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        secondsPerDay[dayIndex] += s.trackedDurationSeconds;
      }
    }

    return secondsPerDay.map((seconds) => seconds ~/ 60).toList();
  }

  // Menemukan indeks hari dengan aktivitas membaca tertinggi
  int get _highestDayIndex {
    final minutes = _dailyReadingMinutes;
    int maxIndex = -1;
    int maxVal = 0;
    for (int i = 0; i < minutes.length; i++) {
      if (minutes[i] > maxVal) {
        maxVal = minutes[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  // 7. Best Session: Sesi membaca dengan durasi terlama pada periode yang dipilih
  ReadingSession? get _bestSession {
    if (_periodSessions.isEmpty) return null;
    ReadingSession? best;
    int maxDurationSeconds = -1;
    for (final s in _periodSessions) {
      if (s.trackedDurationSeconds > maxDurationSeconds) {
        maxDurationSeconds = s.trackedDurationSeconds;
        best = s;
      }
    }
    return best;
  }

  String get _bestSessionDayText {
    final session = _bestSession;
    if (session == null || session.trackedDurationSeconds <= 0) {
      return 'Belum ada sesi';
    }
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final date = session.createdAtInWib;
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day}/${date.month}';
  }

  String get _bestSessionDurationText {
    final session = _bestSession;
    if (session == null || session.trackedDurationSeconds <= 0) return '0m';
    final totalMinutes = (session.trackedDurationSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  // Dialog untuk mengedit target membaca tahunan
  void _showEditGoalDialog() {
    final controller = TextEditingController(text: _annualGoalTarget.toString());
    final currentYear = _now.year;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit $currentYear Reading Goal',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentukan target jumlah buku yang ingin diselesaikan tahun ini:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kNavy,
                ),
                decoration: InputDecoration(
                  labelText: 'Target Buku',
                  hintText: 'Contoh: 24',
                  filled: true,
                  fillColor: kLavender,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavy,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newTarget = int.tryParse(controller.text.trim());
                if (newTarget != null && newTarget > 0) {
                  await _bookService.setAnnualReadingGoal(currentYear, newTarget);
                  if (!mounted) return;
                  setState(() {
                    _annualGoalTarget = newTarget;
                  });
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Target membaca tahun $currentYear berhasil disimpan!'),
                      backgroundColor: kNavy,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Simpan',
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
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronisasi otomatis saat koleksi di AppState diperbarui
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (_lastAppDataVersion != appState.dataVersion) {
          final shouldReload = _lastAppDataVersion != null;
          _lastAppDataVersion = appState.dataVersion;
          if (shouldReload) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _lastAppDataVersion == appState.dataVersion) {
                _loadStatisticsData();
              }
            });
          }
        }
        final books = appState.isLoading || appState.error != null
            ? _allBooks
            : appState.books;
        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadStatisticsData,
              color: kNavy,
              child: _buildBody(books),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(List<Book> books) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: kNavy,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Color(0xFFD45278),
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loadStatisticsData,
                icon: Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        // 1. Header Judul Halaman
        _buildHeader(),
        SizedBox(height: 18),

        // 2. Filter Periode Statistik (This Week, This Month, Year)
        _buildPeriodFilter(),
        SizedBox(height: 20),

        // 3. Empat Kartu Statistik Utama (Reading Time, Pages Read, Books Done, Active Streak)
        _buildStatisticsCards(books),
        SizedBox(height: 12),

        // 4. Banner Top Genre
        _buildTopGenreBanner(books),
        SizedBox(height: 22),

        // 5. Grafik Reading Velocity & Best Session
        _buildReadingVelocitySection(),
        SizedBox(height: 22),

        // 6. Kartu Reading Goal Tahunan
        _buildReadingGoalCard(books),
      ],
    );
  }

  // Widget Header Judul
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics & Habit',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: kNavy,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pantau kebiasaan dan progres membacamu',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kLavender,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.insights_rounded,
            color: kNavy,
            size: 22,
          ),
        ),
      ],
    );
  }

  // Widget Filter Periode (This Week, This Month, Year)
  Widget _buildPeriodFilter() {
    final periods = ['This Week', 'This Month', 'Year'];

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFECEFF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kNavy.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget Empat Kartu Statistik
  Widget _buildStatisticsCards(List<Book> books) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Reading Time',
                value: _formattedReadingTime,
                icon: Icons.schedule_rounded,
                accentColor: Color(0xFF6B4585),
                bgColor: Color(0xFFF3EBF9),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Pages Read',
                value: '$_totalPagesRead',
                icon: Icons.auto_stories_rounded,
                accentColor: Color(0xFF2E365A),
                bgColor: Color(0xFFEDF0F7),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Books Done',
                value: '${_booksDoneCount(books)}',
                icon: Icons.bookmark_added_rounded,
                accentColor: Color(0xFFD45278),
                bgColor: Color(0xFFFCEAEF),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Active Streak',
                value: '$_activeStreak days',
                icon: Icons.local_fire_department_rounded,
                accentColor: Color(0xFFE59B2C),
                bgColor: Color(0xFFFEF6E9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Banner Top Genre
  Widget _buildTopGenreBanner(List<Book> books) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEBE6F2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF3EEF8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.category_rounded,
              color: Color(0xFF6B4585),
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Genre',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  _topGenreFor(books),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kNavy,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFCEAEF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Aktivitas Terbanyak',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD45278),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Reading Velocity & Best Session
  Widget _buildReadingVelocitySection() {
    final dailyMinutes = _dailyReadingMinutes;
    final highestIndex = _highestDayIndex;
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    int maxMinutes = 0;
    for (final m in dailyMinutes) {
      if (m > maxMinutes) maxMinutes = m;
    }

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Velocity',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                ),
              ),
              Text(
                'Menit / Hari',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          // Grafik Batang (Bar Chart)
          Container(
            height: 135,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final minutes = dailyMinutes[index];
                final isHighest = index == highestIndex && minutes > 0;

                // Hitung tinggi batang proporsional (maksimal 65px)
                double barHeight = 8;
                if (maxMinutes > 0 && minutes > 0) {
                  barHeight = (minutes / maxMinutes * 55) + 10;
                }

                // Warna batang: Lavender untuk biasa, Kuning Pastel untuk tertinggi
                final barColor = isHighest
                    ? Color(0xFFFAE696)
                    : (minutes > 0 ? Color(0xFFC3A6D8) : Color(0xFFE9EAF0));

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isHighest)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFAE696),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${minutes}m',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B4585),
                          ),
                        ),
                      )
                    else if (minutes > 0)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${minutes}m',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.black45,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 16),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 22,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      dayLabels[index],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isHighest ? FontWeight.w700 : FontWeight.w500,
                        color: isHighest ? kNavy : Colors.black45,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          SizedBox(height: 16),
          Divider(height: 1, color: Color(0xFFF0F1F6)),
          SizedBox(height: 14),

          // Best Session Information Card
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF6E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE59B2C),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Session',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      _bestSessionDayText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kNavy,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFF3EBF9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _bestSessionDurationText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B4585),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Kartu Reading Goal
  Widget _buildReadingGoalCard(List<Book> books) {
    final currentYear = _now.year;
    final completedBooks = _completedBooks(books);
    final completed = completedBooks.length;
    final target = _annualGoalTarget;
    final double progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    final int percentage = (progress * 100).round();
    final bool isAchieved = completed >= target && target > 0;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Reading Goal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: kNavy,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$currentYear Reading Goal',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showEditGoalDialog,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kLavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: kNavy,
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14),

          // Detail Target & Persentase
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed of $target books completed',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Color(0xFFE9EAF0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? Color(0xFF4CAF50) : Color(0xFF6B4585),
              ),
            ),
          ),

          if (isAchieved) ...[
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Target tercapai! Kerja bagus!',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16),

          // Mini Book Cover Previews
          Text(
            'Buku yang Selesai Dibaca',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 10),

          if (completedBooks.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFEBE6F2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                'Belum ada buku yang selesai dibaca',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: completedBooks.take(5).map((book) {
                  return Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 52,
                            height: 76,
                            color: Color(0xFFE9EAF0),
                            child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: book.coverUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) => Center(
                                      child: Icon(Icons.menu_book_rounded, color: Colors.black26, size: 20),
                                    ),
                                    errorWidget: (c, u, e) => Center(
                                      child: Icon(Icons.menu_book_rounded, color: Colors.black26, size: 20),
                                    ),
                                  )
                                : Center(
                                    child: Icon(Icons.menu_book_rounded, color: kNavy, size: 24),
                                  ),
                          ),
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          width: 52,
                          child: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: kNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
