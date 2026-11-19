import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import 'discover.dart';
import 'library.dart';
import 'profile.dart';
import 'statistics.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

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
            Row(
              children: [
                Image.asset('assets/images/liti_mascot.png', width: 42),
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
            const SizedBox(height: 32),
            Text(
              'Hai, $username! 👋',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF252A3D),
              ),
            ),
            Text(
              'Lanjutkan perjalanan bacamu hari ini.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF2E365A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFFFAE696),
                    size: 30,
                  ),
                  const SizedBox(height: 16),
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
            const SizedBox(height: 26),
            Text(
              'Mulai dari yang kamu suka',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF252A3D),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickCategory(label: 'Fiksi', icon: Icons.auto_stories),
                _QuickCategory(label: 'Pengembangan Diri', icon: Icons.spa),
                _QuickCategory(label: 'Fantasi', icon: Icons.nightlight_round),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuickCategory extends StatelessWidget {
  const _QuickCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17, color: const Color(0xFF2E365A)),
      label: Text(label),
      backgroundColor: const Color(0xFFF0F1F6),
      side: BorderSide.none,
      labelStyle: GoogleFonts.poppins(fontSize: 11),
    );
  }
}
