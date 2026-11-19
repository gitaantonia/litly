import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../services/focus_timer_service.dart';
import '../services/session_service.dart';
import '../state/app_state.dart';
import 'book_detail.dart';
import 'discover.dart';
import 'focus_timer.dart';
import 'library.dart';
import 'profile.dart';
import 'statistics.dart';

// Halaman utama aplikasi Litly dengan navigasi bottom bar
class HomeScreen extends StatefulWidget {
  final String username;
  HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _activeUserName = '';

  @override
  void initState() {
    super.initState();
    _activeUserName = widget.username;
    _loadActiveUser();
  }

  // Mengambil nama pengguna dari session SharedPreferences
  void _loadActiveUser() async {
    final sessionData = await SessionService.getSessionData();
    final name = sessionData['user_name'] as String?;
    if (name != null && name.trim().isNotEmpty && mounted) {
      setState(() {
        _activeUserName = name.trim();
      });
    }
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTab(
        username: _activeUserName.isNotEmpty ? _activeUserName : widget.username,
      ),
      DiscoverScreen(),
      LibraryScreen(onDiscover: () => _selectTab(1)),
      StatisticsScreen(),
      ProfileScreen(username: _activeUserName.isNotEmpty ? _activeUserName : widget.username),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE9EAF0),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Shelf',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Konten tab Home (Greeting, Daily Goal, Active Focus Session, Sedang Dibaca)
class HomeTab extends StatefulWidget {
  final String username;

  HomeTab({
    super.key,
    required this.username,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final FocusTimerService _timerService = FocusTimerService();
  final BookService _bookService = BookService();

  int _todayMinutes = 0;
  int _todayPages = 0;
  int _dailyTargetMinutes = 30;

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onTimerTick);
    _loadDailyGoalData();
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerTick);
    super.dispose();
  }

  void _onTimerTick() {
    if (mounted) {
      setState(() {});
    }
  }

  // Mengambil progres membaca harian dan target dari SQLite (PB-023)
  Future<void> _loadDailyGoalData() async {
    try {
      final minutes = await _bookService.getTodayReadingMinutes();
      final pages = await _bookService.getTodayPagesRead();
      final target = await _bookService.getDailyTargetMinutes();

      if (mounted) {
        setState(() {
          _todayMinutes = minutes;
          _todayPages = pages;
          _dailyTargetMinutes = target;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Sapaan dinamis berdasarkan waktu saat ini
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  // Membuka halaman Focus Timer
  void _openFocusTimer(Book? currentBook) {
    if (currentBook != null && _timerService.selectedBook == null) {
      _timerService.setSelectedBook(currentBook);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusTimerScreen(initialBook: currentBook),
      ),
    ).then((_) {
      _loadDailyGoalData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final books = state.books;

        // Mencari buku yang memiliki status "Currently Reading" atau "Sedang Dibaca" di My Library
        Book? currentlyReadingBook;
        final readingList = books.where((b) {
          final s = b.status.trim().toLowerCase();
          return s == 'currently reading' || s == 'sedang dibaca';
        }).toList();

        if (readingList.isNotEmpty) {
          // Jika ada buku yang sedang aktif di Focus Timer, prioritaskan buku tersebut
          if (_timerService.selectedBook != null &&
              readingList.any((b) => b.id == _timerService.selectedBook!.id)) {
            currentlyReadingBook = readingList.firstWhere(
              (b) => b.id == _timerService.selectedBook!.id,
            );
          } else {
            // Urutkan berdasarkan yang paling baru ditambahkan atau diperbarui
            readingList.sort((a, b) => b.addedAt.compareTo(a.addedAt));
            currentlyReadingBook = readingList.first;
          }
        }

        final double goalProgress = _dailyTargetMinutes > 0
            ? (_todayMinutes / _dailyTargetMinutes).clamp(0.0, 1.0)
            : 0.0;
        final bool isGoalAchieved = _todayMinutes >= _dailyTargetMinutes && _dailyTargetMinutes > 0;

        return RefreshIndicator(
          color: kPurple,
          onRefresh: () async {
            await state.loadBooks();
            await _loadDailyGoalData();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Maskot dan Sapaan Dinamis
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/liti_mascot.png', width: 42),
                        SizedBox(width: 10),
                        Text(
                          'Litly',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: kPurple,
                          ),
                        ),
                      ],
                    ),
                    // Badge status sesi fokus jika sedang berjalan
                    if (_timerService.isRunning)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kSoftPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: kPinkText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Flowing • ${_timerService.formattedTime}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: kPinkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 18),

                // Greeting teks berdasarkan waktu dan nama pengguna yang login
                Text(
                  '${_getGreeting()}, ${widget.username}! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Lanjutkan bacaanmu hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black45,
                  ),
                ),

                SizedBox(height: 20),

                // 2. PB-023: Daily Reading Goal
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('🎯', style: TextStyle(fontSize: 18)),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Reading Goal',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kNavy,
                                    ),
                                  ),
                                  Text(
                                    'Target Membaca Harian',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Label Progres Menit
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isGoalAchieved ? Colors.green[50] : kLavender,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isGoalAchieved
                                  ? 'Tercapai! 🎉'
                                  : '$_todayMinutes / $_dailyTargetMinutes Menit',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isGoalAchieved ? Colors.green[700] : kPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      // Progress Bar Target
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: goalProgress,
                          minHeight: 8,
                          backgroundColor: Color(0xFFF0F1F6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isGoalAchieved ? Colors.green[600]! : kYellow,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(goalProgress * 100).round()}% tercapai',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '$_todayPages hal dibaca hari ini',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18),

                // 3. Active Focus Session Card
                GestureDetector(
                  onTap: () => _openFocusTimer(currentlyReadingBook),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: kNavy.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Focus Session',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _timerService.isRunning
                                    ? 'Fokus membaca • Sisa ${_timerService.formattedTime}'
                                    : (_timerService.isPaused
                                        ? 'Sesi dijeda • ${_timerService.formattedTime}'
                                        : 'Siap mulai sesi • ${_timerService.formattedTime}'),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tombol Play / Pause langsung dari Home
                        IconButton(
                          icon: Icon(
                            _timerService.isRunning
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: kYellow,
                            size: 36,
                          ),
                          onPressed: () {
                            if (_timerService.isRunning) {
                              _timerService.pauseTimer();
                            } else {
                              _timerService.startTimer();
                              _openFocusTimer(currentlyReadingBook);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 22),

                // 4. Bagian Sedang Dibaca (Mengambil langsung dari My Library status Currently Reading)
                Text(
                  'Sedang Dibaca',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                if (state.isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(color: kPurple),
                    ),
                  )
                else if (currentlyReadingBook != null)
                  _CurrentlyReadingCard(
                    book: currentlyReadingBook,
                    onContinue: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(book: currentlyReadingBook!),
                        ),
                      );
                    },
                  )
                else
                  // Empty State sederhana jika belum ada buku Sedang Dibaca (tanpa tombol Discover)
                  _EmptyReadingState(),

                SizedBox(height: 20),

                // 5. Ringkasan Statistik Buku (Buku Dibaca vs Selesai)
                if (books.isNotEmpty)
                  _StatsRow(books: books),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Kartu Buku yang Sedang Dibaca (Currently Reading Card)
class _CurrentlyReadingCard extends StatelessWidget {
  final Book book;
  final VoidCallback onContinue;

  _CurrentlyReadingCard({
    required this.book,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Buku
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 110,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: kLavender,
                            child: Icon(Icons.book_rounded, color: kPurple),
                          ),
                        )
                      : Container(
                          color: kLavender,
                          child: Icon(Icons.book_rounded, color: kPurple),
                        ),
                ),
              ),

              SizedBox(width: 14),

              // Detail Informasi Buku
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori chip
                    if (book.category != null && book.category!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: kSoftPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: kPinkText,
                          ),
                        ),
                      ),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 6),
                    // Rating
                    if (book.rating != null)
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFFDB022), size: 16),
                          SizedBox(width: 4),
                          Text(
                            book.rating!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14),

          // Progres Membaca
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Membaca',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
              Text(
                '${book.currentPage} / ${book.totalPages} hal (${book.progressText})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: book.progress,
              minHeight: 6,
              backgroundColor: Color(0xFFF0F1F6),
              valueColor: AlwaysStoppedAnimation<Color>(kPurple),
            ),
          ),

          SizedBox(height: 14),

          // Tombol Continue Reading (membuka halaman detail buku)
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              icon: Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
              label: Text(
                'Continue Reading',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Empty state sederhana untuk Sedang Dibaca (tanpa tombol Discover)
class _EmptyReadingState extends StatelessWidget {
  _EmptyReadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_outlined, size: 36, color: kPurple),
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada buku yang sedang dibaca',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tambahkan buku dari My Library untuk mulai membaca',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

// Baris statistik jumlah buku dibaca dan selesai
class _StatsRow extends StatelessWidget {
  final List<Book> books;
  _StatsRow({required this.books});

  @override
  Widget build(BuildContext context) {
    final finished = books.where((book) => book.isFinished).length;
    final reading = books.length - finished;
    return Row(
      children: [
        _StatChip(label: 'Dibaca', value: '$reading', icon: Icons.menu_book),
        SizedBox(width: 12),
        _StatChip(
          label: 'Selesai',
          value: '$finished',
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kLightPurple,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kPurple),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kPurple,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
