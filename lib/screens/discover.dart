import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../constants/colors.dart';
import '../services/book_service.dart';
import 'book_detail.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // Service untuk komunikasi dengan Google Books API
  final BookService _bookService = BookService();

  // Controller input pencarian
  final TextEditingController _searchController = TextEditingController();

  // Timer untuk mekanisme debounce 500ms (PB-010)
  Timer? _debounce;

  final List<String> _categories = [
    'All',
    'Novel',
    'Biografi',
    'Sains',
    'Sejarah',
  ];

  // Kategori aktif saat ini
  String _selectedCategory = 'All';

  // Data hasil buku dari Google Books API
  List<Book> _books = [];

  // Status tampilan pencarian (Search States)
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBooksByCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── LOGIKA PENGAMBILAN DATA (API) ──────────────────────────────────────────

  // Mengambil buku berdasarkan kategori terpilih (PB-011)
  void _fetchBooksByCategory(String category) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      var result = await _bookService.fetchBooksByCategory(category);
      var completeBooks = _completeBooks(result);
      if (category == 'All' && completeBooks.isEmpty) {
        result = await _bookService.searchGoogleBooks('books', maxResults: 40);
        completeBooks = _completeBooks(result);
      }
      if (!mounted) return;
      setState(() {
        _books = completeBooks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage =
            'Gagal memuat buku untuk kategori $category. Periksa koneksi internet Anda.';
        _isLoading = false;
      });
    }
  }

  // Melakukan pencarian buku berdasarkan judul, penulis, atau ISBN (PB-010)
  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      // Jika input kosong, kembalikan ke kategori yang sedang aktif
      _fetchBooksByCategory(_selectedCategory);
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      List<Book> result = await _bookService.searchGoogleBooks(query.trim());
      if (!mounted) return;
      setState(() {
        _books = _completeBooks(result);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage =
            'Gagal melakukan pencarian untuk "$query". Periksa koneksi internet Anda.';
        _isLoading = false;
      });
    }
  }

  List<Book> _completeBooks(Iterable<Book> books) {
    return books.where((book) {
      return book.title.trim().isNotEmpty &&
          book.author.trim().isNotEmpty &&
          book.author != 'Penulis Tidak Diketahui' &&
          (book.coverUrl?.trim().isNotEmpty ?? false);
    }).toList();
  }

  // Handler saat teks input pencarian berubah dengan Debounce 500ms
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  // Menghapus query pencarian dan mengembalikan ke kategori aktif
  void _clearSearch() {
    _searchController.clear();
    _fetchBooksByCategory(_selectedCategory);
  }

  // Memilih chip kategori (PB-011)
  void _onCategorySelected(String category) {
    if (_selectedCategory == category && _searchController.text.isEmpty) return;

    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });

    _fetchBooksByCategory(category);
  }

  // ─── WARNA CHIP KATEGORI (Sesuai Referensi Desain) ──────────────────────────

  // Mendapatkan warna latar belakang chip ketika tidak aktif
  Color _getChipBgColor(String category) {
    final normalizedCategory = category.toLowerCase();
    if (normalizedCategory == 'all') return Color(0xFFF1EEF6);
    if (normalizedCategory.contains('novel')) return Color(0xFFFCEAEF);
    if (normalizedCategory.contains('biografi')) return Color(0xFFECE5F8);
    if (normalizedCategory.contains('sains')) return Color(0xFFE5F2F8);
    if (normalizedCategory.contains('sejarah')) return Color(0xFFFAF2DE);
    return Color(0xFFE9EAF1);
  }

  // Mendapatkan warna teks chip ketika tidak aktif
  Color _getChipTextColor(String category) {
    final normalizedCategory = category.toLowerCase();
    if (normalizedCategory.contains('novel')) return Color(0xFFD45278);
    if (normalizedCategory.contains('biografi')) return Color(0xFF7856A9);
    if (normalizedCategory.contains('sains')) return Color(0xFF3E82A8);
    if (normalizedCategory.contains('sejarah')) return Color(0xFFA38332);
    return kNavy;
  }

  // ─── BUILD UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F4FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Judul "Discover"
            Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 14),
              child: Text(
                'Discover',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // 2. Search Bar Rounded (PB-010)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: kNavy,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search title, author or genre ...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black38,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: kNavy.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: kNavy,
                              size: 20,
                            ),
                            tooltip: 'Hapus Pencarian',
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // 3. Category Filter Chips Horizontal (PB-011)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20),
              physics: BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((category) {
                  bool isSelected = _selectedCategory == category;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _onCategorySelected(category),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? kNavy : _getChipBgColor(category),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: kNavy.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '# ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : _getChipTextColor(category)
                                          .withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : _getChipTextColor(category),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 16),

            // 4. Area Konten Hasil Pencarian & Eksplorasi (Search States)
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── TAMPILAN SEARCH STATES ────────────────────────────────────────────────

  Widget _buildBody() {
    return ListView(
      padding: EdgeInsets.only(bottom: 24),
      physics: BouncingScrollPhysics(),
      children: [
        if (_isLoading)
          _buildLoadingState()
        else if (_isError)
          _buildErrorState()
        else if (_books.isEmpty)
          _buildEmptyState()
        else
          ..._books.map(
            (book) => Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: _buildBookCard(book),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(color: kNavy, strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text(
              'Memuat data buku...',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color(0xFFFDECEC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 36,
                  color: Color(0xFFD32F2F),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Gagal Memuat Data',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    _performSearch(_searchController.text.trim());
                  } else {
                    _fetchBooksByCategory(_selectedCategory);
                  }
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: kLavender,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 38,
                  color: kNavy.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Buku Tidak Ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Tidak ditemukan buku dengan informasi lengkap untuk "${_searchController.text}". Coba kata kunci lain.'
                    : 'Tidak ada buku dengan informasi lengkap untuk kategori ini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover(
    Book book, {
    required double width,
    required double height,
  }) {
    final coverUrl = book.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: kLavender,
        alignment: Alignment.center,
        child: Icon(
          Icons.menu_book_rounded,
          color: kNavy.withValues(alpha: 0.4),
          size: 34,
        ),
      );
    }

    return Image.network(
      coverUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Gagal memuat cover $coverUrl: $error');
        return Container(
          color: kLavender,
          alignment: Alignment.center,
          child: Icon(
            Icons.menu_book_rounded,
            color: kNavy.withValues(alpha: 0.4),
            size: 34,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: kLavender,
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kNavy.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }

  void _openBookDetails(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  // ─── KARTU BUKU (Sesuai Referensi Desain) ───────────────────────────────────

  Widget _buildBookCard(Book book) {
    final categoryName =
        book.category?.split('/').first.trim() ??
        (_selectedCategory == 'All' ? 'Bestseller' : _selectedCategory);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openBookDetails(book),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: kNavy.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildBookCover(book, width: 96, height: 142),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 142,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getChipBgColor(categoryName),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '# ${categoryName.toUpperCase()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _getChipTextColor(categoryName),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (book.rating != null) ...[
                              SizedBox(width: 4),
                              Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFA900),
                                size: 15,
                              ),
                              SizedBox(width: 2),
                              Text(
                                book.rating!.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kNavy,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kNavy,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${book.author}${book.publishedYear == null ? '' : ' • ${book.publishedYear}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Color(0xFF85879A),
                          ),
                        ),
                        if (book.description?.isNotEmpty ?? false) ...[
                          SizedBox(height: 5),
                          Expanded(
                            child: Text(
                              book.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                height: 1.35,
                                color: Color(0xFF85879A),
                              ),
                            ),
                          ),
                        ] else
                          Spacer(),
                        Divider(height: 12, color: Color(0xFFEDEDF2)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                book.totalPages > 0
                                    ? '${book.totalPages} pages'
                                    : 'Pages n/a',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Color(0xFF85879A),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _openBookDetails(book),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.only(left: 5, top: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 15,
                                      color: kNavy,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Shelf',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
