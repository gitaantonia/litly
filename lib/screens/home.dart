import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/book.dart';
import '../services/book_service.dart';

// import 'search_book.dart';
// import 'book_detail.dart';
// import '../widgets/book_card.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = BookService();
  List<Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await _service.getBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  // Future<void> _openSearch() async {
  //   final added = await Navigator.push<bool>(
  //     context,
  //     MaterialPageRoute(builder: (_) => const SearchBookScreen()),
  //   );
  //   if (added == true) _loadBooks();
  // }

  // Future<void> _openDetail(Book book) async {
  //   final changed = await Navigator.push<bool>(
  //     context,
  //     MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
  //   );
  //   if (changed == true) _loadBooks();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/liti_mascot.png', width: 40),
                      const SizedBox(width: 10),
                      Text(
                        'Litly',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hai, ${widget.username}! 👋',
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats ringkas
            if (_books.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _StatsRow(books: _books),
              ),

            const SizedBox(height: 20),

            // Label daftar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Sedang Dibaca',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // // Daftar buku / empty state
            // Expanded(
            //   child: _loading
            //       ? const Center(
            //           child: CircularProgressIndicator(color: kPurple))
            //       : _books.isEmpty
            //           ? _EmptyState(onAdd: _openSearch)
            //           : ListView.separated(
            //               padding: const EdgeInsets.symmetric(horizontal: 24),
            //               itemCount: _books.length,
            //               separatorBuilder: (_, __) =>
            //                   const SizedBox(height: 12),
            //               itemBuilder: (_, i) => BookCard(
            //                 book: _books[i],
            //                 onTap: () => _openDetail(_books[i]),
            //               ),
            //             ),
            // ),
          ],
        ),
      ),
    );
    // Tombol tambah buku
    //   floatingActionButton: FloatingActionButton.extended(
    //     // onPressed: _openSearch,
    //     backgroundColor: kPurple,
    //     icon: const Icon(Icons.search, color: Colors.white),
    //     label: Text(
    //       'Cari Buku',
    //       style: GoogleFonts.poppins(
    //         fontWeight: FontWeight.w600,
    //         color: Colors.white,
    //       ),
    //     ),
    //   ),
    // );
  }
}

// ─── Widget Statistik ───────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<Book> books;
  const _StatsRow({required this.books});

  @override
  Widget build(BuildContext context) {
    final finished = books.where((b) => b.isFinished).length;
    final reading = books.length - finished;
    return Row(
      children: [
        _StatChip(label: 'Dibaca', value: '$reading', icon: Icons.menu_book),
        const SizedBox(width: 12),
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
  final String label, value;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kLightPurple,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kPurple),
            const SizedBox(width: 8),
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

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 72,
            color: kButtonColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada buku nih...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cari dan tambahkan buku pertamamu!',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.search, color: Colors.white),
            label: Text(
              'Cari Buku',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
