import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/book_history_provider.dart';
import 'package:litly/widgets/history/book_summary_card.dart';
import 'package:litly/widgets/history/history_timeline.dart';
import 'package:litly/widgets/history/update_progress_sheet.dart';

// BARU: Halaman Book History untuk melihat riwayat membaca dan update progres
class BookHistoryScreen extends StatefulWidget {
  BookHistoryScreen({Key? key}) : super(key: key);

  @override
  _BookHistoryScreenState createState() => _BookHistoryScreenState();
}

class _BookHistoryScreenState extends State<BookHistoryScreen> {
  int? _bookId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    // Ambil id buku dari arguments Navigator
    final args = ModalRoute.of(context)?.settings.arguments;
    int? parsedId;

    if (args is int) {
      parsedId = args;
    } else if (args is String) {
      parsedId = int.tryParse(args);
    }

    BookHistoryProvider provider =
        Provider.of<BookHistoryProvider>(context, listen: false);

    if (parsedId != null) {
      _bookId = parsedId;
      provider.loadHistory(parsedId);
    } else {
      // Jika arguments kosong dan dalam debug mode, otomatis gunakan data contoh
      if (kDebugMode) {
        _bookId = 999;
        provider.setDebugMockData();
      } else {
        provider.isLoading = false;
      }
    }
  }

  // Buka modal bottom sheet untuk update progress
  void _openUpdateProgressSheet(BookHistoryProvider provider) {
    if (provider.book == null) return;

    int totalPages = (provider.book!['totalPages'] as num?)?.toInt() ?? 0;
    int currentPage = (provider.book!['currentPage'] as num?)?.toInt() ?? 0;
    String title = provider.book!['title'] ?? 'Buku';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return UpdateProgressSheet(
          bookId: _bookId ?? 999,
          bookTitle: title,
          currentPage: currentPage,
          totalPages: totalPages,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    BookHistoryProvider provider = Provider.of<BookHistoryProvider>(context);

    bool isCompleted = provider.book?['status'] == 'Completed';

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : Color(0xFFF8F6FF),
      appBar: AppBar(
        title: Text(
          'Book History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          // ==========================================
          // // HAPUS SEBELUM DIKUMPULKAN: Tombol Debug
          // ==========================================
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.science, color: Colors.orange),
              tooltip: 'Set Mock Debug Data (Infinite Country)',
              onPressed: () {
                provider.setDebugMockData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Debug: Data contoh Infinite Country dimuat!'),
                    backgroundColor: Color(0xFFB5294E),
                  ),
                );
              },
            ),
        ],
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : provider.book == null && !provider.isDebugData
              ? Center(
                  child: Text(
                    'Buku tidak ditemukan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                )
              : SafeArea(
                  child: Stack(
                    children: [
                      // Area Konten Scrollable
                      RefreshIndicator(
                        onRefresh: () async {
                          if (_bookId != null && !provider.isDebugData) {
                            await provider.loadHistory(_bookId!);
                          }
                        },
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Kartu Ringkasan Buku
                              BookSummaryCard(
                                book: provider.book,
                                progressPercent: provider.progressPercent,
                                pagesLeft: provider.pagesLeft,
                                timeLeftText: provider.timeLeftText,
                              ),
                              SizedBox(height: 16),

                              // 2. Timeline Riwayat Baca
                              HistoryTimeline(
                                sessions: provider.recentSessions,
                                totalSessionCount: provider.sessionCount,
                              ),

                              // Padding bawah agar konten tidak tertutup tombol fixed
                              SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),

                      // Tombol Update Progress Menempel di Bawah Layar
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isCompleted
                                ? null
                                : () => _openUpdateProgressSheet(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1F1F3D), // Navy
                              disabledBackgroundColor: Color(0xFF1F1F3D).withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_box_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Update Progress & Log Session',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
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
