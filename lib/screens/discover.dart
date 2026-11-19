import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../services/google_books_service.dart';
import '../widgets/book_ui.dart';
import 'book_detail.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _service = GoogleBooksService();
  final _searchController = TextEditingController();
  List<Book> _popular = [];
  List<Book> _editors = [];
  List<Book> _results = [];
  bool _loadingRecommendations = true;
  bool _searching = false;
  String? _recommendationError;
  String? _searchError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _loadingRecommendations = true;
      _recommendationError = null;
    });
    try {
      final books = await Future.wait([
        _service.recommendations('fiction'),
        _service.recommendations('self-help'),
      ]);
      if (!mounted) return;
      setState(() {
        _popular = books[0];
        _editors = books[1];
        _loadingRecommendations = false;
      });
    } on GoogleBooksException catch (error) {
      if (!mounted) return;
      setState(() {
        _recommendationError = error.message;
        _loadingRecommendations = false;
      });
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _searchError = null;
      });
      return;
    }
    setState(() {
      _query = query;
      _searching = true;
      _searchError = null;
    });
    try {
      final books = await _service.searchBooks(query);
      if (!mounted) return;
      setState(() {
        _results = books;
        _searching = false;
      });
    } on GoogleBooksException catch (error) {
      if (!mounted) return;
      setState(() {
        _searchError = error.message;
        _searching = false;
      });
    }
  }

  Future<void> _openBook(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 600 ? 40.0 : 20.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            22,
            horizontalPadding,
            28,
          ),
          children: [
            Text(
              'Discover',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF252A3D),
              ),
            ),
            Text(
              'Temukan bacaan yang cocok untukmu',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari judul, penulis, atau ISBN',
                prefixIcon: const Icon(Icons.search_rounded, color: navy),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward_rounded, color: navy),
                  tooltip: 'Cari buku',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (_query.isNotEmpty)
              _buildSearchResults()
            else
              _buildRecommendations(),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searching) return const BookShimmerList();
    if (_searchError != null) {
      return SizedBox(
        height: 300,
        child: ErrorState(message: _searchError!, onRetry: _search),
      );
    }
    if (_results.isEmpty) {
      return SizedBox(
        height: 300,
        child: EmptyState(
          title: 'Buku belum ditemukan',
          message: 'Coba kata kunci lain, misalnya nama penulis atau genre.',
          actionLabel: 'Lihat rekomendasi',
          onAction: () {
            _searchController.clear();
            setState(() => _query = '');
          },
          icon: Icons.search_off_rounded,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Hasil untuk “$_query”'),
        const SizedBox(height: 12),
        ..._results.map(
          (book) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BookTile(book: book, onTap: () => _openBook(book)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    if (_loadingRecommendations) return const BookShimmerList(count: 6);
    if (_recommendationError != null) {
      return SizedBox(
        height: 300,
        child: ErrorState(
          message: _recommendationError!,
          onRetry: _loadRecommendations,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookCarousel(
          title: 'Buku Populer Saat Ini',
          books: _popular,
          onTap: _openBook,
        ),
        const SizedBox(height: 24),
        _BookCarousel(
          title: 'Pilihan Editor',
          books: _editors,
          onTap: _openBook,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF252A3D),
    ),
  );
}

class _BookCarousel extends StatelessWidget {
  const _BookCarousel({
    required this.title,
    required this.books,
    required this.onTap,
  });

  final String title;
  final List<Book> books;
  final ValueChanged<Book> onTap;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 8),
          Text(
            'Rekomendasi belum tersedia saat ini.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 12),
        SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final book = books[index];
              return SizedBox(
                width: 132,
                child: InkWell(
                  onTap: () => onTap(book),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(url: book.coverUrl, width: 132),
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
