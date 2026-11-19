import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/book_ui.dart';
import 'book_detail.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth > 600 ? 40.0 : 20.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, 22, padding, 16),
                child: Text(
                  'My Library',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF252A3D),
                  ),
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: BookShimmerList(),
                      )
                    : state.error != null
                    ? ErrorState(
                        message: state.error!,
                        onRetry: state.loadBooks,
                      )
                    : state.books.isEmpty
                    ? EmptyState(
                        title: 'Koleksimu masih kosong',
                        message: 'Simpan buku yang menarik untuk dibaca nanti.',
                        actionLabel: 'Temukan Buku',
                        onAction: onDiscover,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                        itemCount: state.books.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final book = state.books[index];
                          return BookTile(
                            book: book,
                            showStatus: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BookDetailScreen(book: book),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
