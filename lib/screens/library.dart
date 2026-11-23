import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../state/app_state.dart';
import '../widgets/book_ui.dart';
import '../widgets/litly_mascot.dart';
import 'book_detail.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 20.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 18, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Book Nook',
                        style: GoogleFonts.poppins(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF38323B),
                        ),
                      ),
                    ),
                    LitlyMascot(
                      mood: state.error != null
                          ? LitlyMood.frustrated
                          : state.books.isEmpty
                          ? LitlyMood.greeting
                          : LitlyMood.pointing,
                      width: 108,
                      height: 120,
                    ),
                  ],
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
                        title: 'Rak bukumu masih kosong',
                        message: 'Simpan buku yang ingin kamu baca.',
                        actionLabel: 'Temukan Buku',
                        onAction: onDiscover,
                      )
                    : _buildBookNook(
                        context,
                        state,
                        constraints.maxWidth,
                        horizontalPadding,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookNook(
    BuildContext context,
    AppState state,
    double screenWidth,
    double horizontalPadding,
  ) {
    final currentlyReading = state.books
        .where((book) => book.status == 'Currently Reading')
        .toList();

    return ListView(
      padding: EdgeInsets.only(bottom: 24),
      children: [
        if (currentlyReading.isNotEmpty)
          _buildCurrentlyReading(
            context,
            currentlyReading,
            screenWidth,
            horizontalPadding,
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading List',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF38323B),
                ),
              ),
              Text(
                'Recent',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF292840),
                ),
              ),
            ],
          ),
        ),
        for (final book in state.books)
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              12,
            ),
            child: _ReadingListCard(
              book: book,
              onTap: () => _openBook(context, book),
              onStart: () => _startReading(context, book),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentlyReading(
    BuildContext context,
    List<Book> books,
    double screenWidth,
    double horizontalPadding,
  ) {
    final cardWidth = (screenWidth * 0.53).clamp(195.0, 225.0).toDouble();
    final coverWidth = cardWidth * 0.78;

    return SizedBox(
      height: coverWidth * 1.45 + 58,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, right: 4),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                '${books.length} items',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF89899A),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(left: horizontalPadding - 12, right: 18),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: books.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final book = books[index];
                return SizedBox(
                  width: cardWidth,
                  child: GestureDetector(
                    onTap: () => _openBook(context, book),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BookCover(url: book.coverUrl, width: coverWidth),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF292840),
                          ),
                        ),
                        if (book.totalPages > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${book.progressText} completed',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF746D72),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openBook(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  Future<void> _startReading(BuildContext context, Book book) async {
    final updatedBook = Book(
      id: book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      publisher: book.publisher,
      publishedDate: book.publishedDate,
      publishedYear: book.publishedYear,
      language: book.language,
      category: book.category,
      isbn: book.isbn,
      description: book.description,
      totalPages: book.totalPages,
      rating: book.rating,
      ratingsCount: book.ratingsCount,
      status: 'Currently Reading',
      currentPage: book.currentPage,
      addedAt: book.addedAt,
    );

    try {
      await context.read<AppState>().updateBook(updatedBook);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status buku belum dapat diperbarui.')),
      );
    }
  }
}

class _ReadingListCard extends StatelessWidget {
  const _ReadingListCard({
    required this.book,
    required this.onTap,
    required this.onStart,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final hasProgress =
        book.totalPages > 0 &&
        (book.currentPage > 0 || book.status == 'Currently Reading');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(url: book.coverUrl, width: 68),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF202039),
                            ),
                          ),
                        ),
                        if (book.totalPages > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${book.totalPages} pages',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: const Color(0xFF858599),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (book.author.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF858599),
                        ),
                      ),
                    ],
                    if (book.rating != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            book.rating!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((book.category?.trim().isNotEmpty ?? false) ||
                        book.status == 'Want to Read') ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (book.category?.trim().isNotEmpty ?? false)
                            _ShelfTag(
                              label: book.category!.split('/').first.trim(),
                              color: const Color(0xFFFCE4EB),
                              textColor: const Color(0xFFD6385D),
                            ),
                          if (book.status == 'Want to Read')
                            const _ShelfTag(
                              label: 'Wishlist',
                              color: Color(0xFFF0EEFA),
                              textColor: Color(0xFF77758C),
                            ),
                        ],
                      ),
                    ],
                    if (hasProgress) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: book.progress,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFECEBF4),
                                color: const Color(0xFF28233E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            book.progressText,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else if (book.status == 'Want to Read') ...[
                      const SizedBox(height: 7),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFE99B),
                            foregroundColor: const Color(0xFF27243A),
                            minimumSize: const Size(62, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            'Start',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else if (book.status.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        book.status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B3657),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfTag extends StatelessWidget {
  const _ShelfTag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '# $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
