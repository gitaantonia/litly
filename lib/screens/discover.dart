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
  // Service untuk komunikasi dengan Google Books API
  final BookService _bookService = BookService();

  // Controller input pencarian
  final TextEditingController _searchController = TextEditingController();

  // Timer untuk mekanisme debounce 500ms (PB-010)
  Timer? _debounce;

  // Daftar kategori buku sesuai pembagian tugas PB-011
  final List<String> _categories = [
    'All',
    'Fiction',
    'Self-Improvement',
    'Technology',
    'Business',
    'History',
    'Psychology',
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
    // Memuat data buku kategori awal saat halaman pertama kali dibuka
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
      List<Book> result = await _bookService.fetchBooksByCategory(category);
      if (!mounted) return;
      setState(() {
        _books = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage = 'Gagal memuat buku untuk kategori $category. Periksa koneksi internet Anda.';
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
        _books = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage = 'Gagal melakukan pencarian untuk "$query". Periksa koneksi internet Anda.';
        _isLoading = false;
      });
    }
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
    switch (category) {
      case 'Fiction':
        return Color(0xFFFCEAEF); // Pink lembut
      case 'Self-Improvement':
        return Color(0xFFECE5F8); // Lavender lembut
      case 'Technology':
        return Color(0xFFE5F2F8); // Biru muda lembut
      case 'Business':
        return Color(0xFFFCF0E8); // Peach lembut
      case 'History':
        return Color(0xFFFAF2DE); // Krem lembut
      case 'Psychology':
        return Color(0xFFFAF5E4); // Kuning muda lembut
      case 'All':
      default:
        return Color(0xFFF1EEF6);
    }
  }

  // Mendapatkan warna teks chip ketika tidak aktif
  Color _getChipTextColor(String category) {
    switch (category) {
      case 'Fiction':
        return Color(0xFFD45278);
      case 'Self-Improvement':
        return Color(0xFF7856A9);
      case 'Technology':
        return Color(0xFF3E82A8);
      case 'Business':
        return Color(0xFFC87442);
      case 'History':
        return Color(0xFFA38332);
      case 'Psychology':
        return Color(0xFF9A7E24);
      case 'All':
      default:
        return kNavy;
    }
  }

  // ─── BUILD UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBFE),
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
                  color: kLavender,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Color(0xFFE8E0F0)),
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
                        : Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.tune_rounded,
                              color: kNavy.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
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
                                    : _getChipTextColor(category).withValues(alpha: 0.6),
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
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAMPILAN SEARCH STATES ────────────────────────────────────────────────

  Widget _buildBody() {
    // A. Loading State
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: kNavy,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat data buku...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // B. Error State
    if (_isError) {
      return Center(
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
                icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
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
      );
    }

    // C. Empty State
    if (_books.isEmpty) {
      return Center(
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
                    ? 'Tidak ada buku yang cocok dengan "${_searchController.text}". Coba cari dengan judul, penulis, atau nomor ISBN lain.'
                    : 'Tidak ada koleksi buku yang tersedia untuk kategori ini.',
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
      );
    }

    // D. Success State (Daftar Kartu Buku Dinamis dari Google Books API)
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 6, 20, 24),
      physics: BouncingScrollPhysics(),
      itemCount: _books.length,
      separatorBuilder: (context, index) => SizedBox(height: 14),
      itemBuilder: (context, index) {
        Book book = _books[index];
        return _buildBookCard(book);
      },
    );
  }

  // ─── KARTU BUKU (Sesuai Referensi Desain) ───────────────────────────────────

  Widget _buildBookCard(Book book) {
    String categoryName = book.category ?? _selectedCategory;
    if (categoryName.toLowerCase() == 'all') {
      categoryName = 'READING';
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFEFEBF5)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2E365A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cover Buku
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 82,
              height: 118,
              color: kLavender,
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: kNavy.withValues(alpha: 0.35),
                            size: 28,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
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
                    )
                  : Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: kNavy.withValues(alpha: 0.35),
                        size: 32,
                      ),
                    ),
            ),
          ),

          SizedBox(width: 14),

          // 2. Informasi Buku
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Tag Kategori & Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tag Kategori
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getChipBgColor(categoryName),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '# ${categoryName.toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getChipTextColor(categoryName),
                        ),
                      ),
                    ),

                    // Rating bintang (jika tersedia)
                    if (book.rating != null)
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 16,
                          ),
                          SizedBox(width: 3),
                          Text(
                            book.rating!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                SizedBox(height: 6),

                // Judul Buku
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kNavy,
                    height: 1.25,
                  ),
                ),

                SizedBox(height: 3),

                // Penulis & Tahun Terbit
                Text(
                  '${book.author}${book.publishedYear != null ? " • ${book.publishedYear}" : ""}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: 5),

                // Deskripsi singkat jika ada
                if (book.description != null && book.description!.isNotEmpty)
                  Text(
                    book.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black45,
                      height: 1.3,
                    ),
                  ),

                SizedBox(height: 8),

                // Informasi Jumlah Halaman
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: kNavy.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 5),
                    Text(
                      book.totalPages > 0
                          ? '${book.totalPages} pages'
                          : 'Pages not specified',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
