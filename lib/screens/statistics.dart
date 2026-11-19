import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/book_ui.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final completed = state.books
            .where((book) => book.status == 'Completed')
            .length;
        final reading = state.books
            .where((book) => book.status == 'Currently Reading')
            .length;
        final wantToRead = state.books
            .where((book) => book.status == 'Want to Read')
            .length;
        final totalPages = state.books.fold<int>(
          0,
          (sum, book) =>
              sum + (book.status == 'Completed' ? book.totalPages : 0),
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          children: [
            Text(
              'Statistics',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF252A3D),
              ),
            ),
            Text(
              'Lihat perkembangan perjalanan membacamu',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (state.isLoading)
              const BookShimmerList(count: 3)
            else if (state.error != null)
              ErrorState(message: state.error!, onRetry: state.loadBooks)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _StatisticCard(
                      label: 'Total Buku',
                      value: '${state.books.length}',
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatisticCard(
                      label: 'Selesai',
                      value: '$completed',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatisticCard(
                label: 'Halaman dari buku selesai',
                value: '$totalPages halaman',
                icon: Icons.auto_stories_outlined,
                expanded: true,
              ),
              const SizedBox(height: 22),
              Text(
                'Status Bacaan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _StatusRow(label: 'Ingin Dibaca', count: wantToRead),
              _StatusRow(label: 'Sedang Dibaca', count: reading),
              _StatusRow(label: 'Selesai', count: completed),
            ],
          ],
        );
      },
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.label,
    required this.value,
    required this.icon,
    this.expanded = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy, size: 25),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
    trailing: CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFF0F1F6),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: navy,
        ),
      ),
    ),
  );
}
