import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../state/app_state.dart';
import 'discover.dart';
import 'library.dart';
import 'profile.dart';
import 'statistics.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages = [
    HomeTab(username: widget.username, onDiscover: () => _selectTab(1)),
    const DiscoverScreen(),
    LibraryScreen(onDiscover: () => _selectTab(1)),
    const StatisticsScreen(),
    ProfileScreen(username: widget.username),
  ];

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _loadBooks() async {
    final books = await _service.getBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscoverScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE9EAF0),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
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
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'My Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Statistics',
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.username, required this.onDiscover});

  final String username;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 600 ? 40.0 : 24.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            28,
          ),
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/liti_mascot.png', width: 40),
                          SizedBox(width: 10),
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
                      IconButton(
                        icon: Icon(Icons.explore_rounded, color: kNavy),
                        tooltip: 'Discover',
                        onPressed: _openSearch,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Temukan cerita\nfavoritmu berikutnya',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jelajahi pilihan buku dari seluruh dunia.',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onDiscover,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFAE696),
                      foregroundColor: const Color(0xFF2E365A),
                    ),
                    child: const Text('Jelajahi Buku'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Stats ringkas
            if (_books.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _StatsRow(books: _books),
              ),

            SizedBox(height: 20),

            // Label daftar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Sedang Dibaca',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: kPurple),
                    )
                  : _books.isEmpty
                      ? _EmptyState(onAdd: _openSearch)
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _books.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
                          itemBuilder: (_, i) => Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Color(0xFFEFEBF5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.book_rounded, color: kPurple),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _books[i].title,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _books[i].author,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSearch,
        backgroundColor: kNavy,
        icon: Icon(Icons.explore_rounded, color: Colors.white),
        label: Text(
          'Discover Buku',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Widget Statistik ───────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<Book> books;
  _StatsRow({required this.books});

  @override
  Widget build(BuildContext context) {
    final finished = books.where((b) => b.isFinished).length;
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
  final String label, value;
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
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCategory extends StatelessWidget {
  const _QuickCategory({required this.label, required this.icon});

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 72,
            color: kButtonColor,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada buku nih...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cari dan temukan buku di Discover!',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.explore_rounded, color: Colors.white),
            label: Text(
              'Buka Discover',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
