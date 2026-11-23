import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import '../state/app_state.dart';
import '../widgets/book_ui.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _descriptionExpanded = false;
  bool _saving = false;

  Future<void> _selectStatus() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih status membaca',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (final status in const [
                'Want to Read',
                'Currently Reading',
                'Completed',
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined, color: navy),
                  title: Text(switch (status) {
                    'Want to Read' => 'Ingin Dibaca',
                    'Currently Reading' => 'Sedang Dibaca',
                    _ => 'Selesai',
                  }, style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () => Navigator.pop(context, status),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final state = context.read<AppState>();
      if (state.containsBook(widget.book.id)) {
        final saved = state.books.firstWhere(
          (book) => book.id == widget.book.id,
        );
        saved.status = selected;
        await state.updateBook(saved);
      } else {
        final source = widget.book;
        await state.addBook(
          Book(
            id: source.id.isEmpty ? const Uuid().v4() : source.id,
            title: source.title,
            author: source.author,
            coverUrl: source.coverUrl,
            publisher: source.publisher,
            publishedDate: source.publishedDate,
            publishedYear: source.publishedYear,
            language: source.language,
            category: source.category,
            isbn: source.isbn,
            description: source.description,
            totalPages: source.totalPages,
            rating: source.rating,
            ratingsCount: source.ratingsCount,
            status: selected,
            currentPage: source.currentPage,
            addedAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status buku diperbarui ke $selected.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku belum dapat disimpan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeFromLibrary() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().removeBook(widget.book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book removed from My Library.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book could not be removed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _plainDescription(String text) => text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final description = _plainDescription(book.description ?? '');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FC),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Book Details',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF17162D),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 620 ? 32.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Consumer<AppState>(
                    builder: (context, state, _) {
                      final saved = state.books
                          .where((savedBook) => savedBook.id == book.id)
                          .firstOrNull;
                      final metadata = _editionMetadata(book);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(book),
                          if (_hasDisplayValue(book.author)) ...[
                            const SizedBox(height: 20),
                            Text(
                              book.author.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: const Color(0xFFCE3155),
                              ),
                            ),
                          ],
                          if (_hasDisplayValue(book.title)) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    book.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      color: const Color(0xFF17162D),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    tooltip: saved == null
                                        ? 'Add to My Library'
                                        : 'Remove from My Library',
                                    onPressed: _saving
                                        ? null
                                        : saved == null
                                        ? _selectStatus
                                        : _removeFromLibrary,
                                    icon: Icon(
                                      saved == null
                                          ? Icons.bookmark_border_rounded
                                          : Icons.bookmark_added_rounded,
                                      color: const Color(0xFFCE3155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_hasDisplayValue(book.category)) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _DetailChip(label: book.category!.trim()),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (saved == null)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _selectStatus,
                                icon: const Icon(Icons.bookmark_add_outlined),
                                label: Text(
                                  _saving ? 'Saving...' : 'Add to My Library',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: navy,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            _ReadingStatusCard(
                              book: saved,
                              onStatusTap: _saving ? null : _selectStatus,
                            ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Synopsis',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17162D),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: navy.withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    maxLines: _descriptionExpanded ? null : 4,
                                    overflow: _descriptionExpanded
                                        ? null
                                        : TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: const Color(0xFF626274),
                                    ),
                                  ),
                                  if (description.length > 200)
                                    TextButton(
                                      onPressed: () => setState(
                                        () => _descriptionExpanded =
                                            !_descriptionExpanded,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.only(top: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: const Color(
                                          0xFFCE3155,
                                        ),
                                      ),
                                      child: Text(
                                        _descriptionExpanded
                                            ? 'Read less'
                                            : 'Read more',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (metadata.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Edition Details',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17162D),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _MetadataCard(metadata: metadata),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(Book book) {
    final hasCover = _hasDisplayValue(book.coverUrl);
    final stats = <Widget>[
      if (book.rating != null)
        _DetailStat(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF6D3B12),
          iconBackground: const Color(0xFFFFE1BC),
          value: book.rating!.toStringAsFixed(1),
          label: 'Rating / 5.0',
        ),
      if (book.totalPages > 0)
        _DetailStat(
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFFB32D54),
          iconBackground: const Color(0xFFFFDCE6),
          value: '${book.totalPages}',
          label: 'Pages',
        ),
      if ((book.ratingsCount ?? 0) > 0)
        _DetailStat(
          icon: Icons.rate_review_outlined,
          iconColor: const Color(0xFF5141A4),
          iconBackground: const Color(0xFFE7E1FF),
          value: '${book.ratingsCount}',
          label: 'Reviews',
        ),
    ];

    if (!hasCover && stats.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth = (constraints.maxWidth * 0.43)
            .clamp(125.0, 180.0)
            .toDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasCover) BookCover(url: book.coverUrl, width: coverWidth),
            if (hasCover && stats.isNotEmpty) const SizedBox(width: 16),
            if (stats.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0; index < stats.length; index++) ...[
                      if (index > 0) const SizedBox(height: 10),
                      stats[index],
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  bool _hasDisplayValue(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return !const {
      'tanpa judul',
      'penulis tidak diketahui',
      'unknown author',
    }.contains(value.trim().toLowerCase());
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E6FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '# $label',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF39315F),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17162D),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF777787),
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

class _ReadingStatusCard extends StatelessWidget {
  const _ReadingStatusCard({required this.book, required this.onStatusTap});

  final Book book;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final hasPageCount = book.totalPages > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xFFC52F55)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reading Status',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF17162D),
                  ),
                ),
              ),
              InkWell(
                onTap: onStatusTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _readingStatusLabel(book.status),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF25223F),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.expand_more_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hasPageCount) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Page ${book.currentPage.clamp(0, book.totalPages)} of ${book.totalPages}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F5E6D),
                    ),
                  ),
                ),
                Text(
                  '${(book.progress * 100).round()}% Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC52F55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: book.progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFECE9FB),
                color: const Color(0xFFCF3158),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _readingStatusLabel(String status) => switch (status) {
  'Want to Read' => 'Want to Read',
  'Currently Reading' => 'Currently Reading',
  'Completed' => 'Completed',
  _ => status,
};

List<(String, String)> _editionMetadata(Book book) => [
  if (book.publisher?.trim().isNotEmpty ?? false)
    ('Publisher', book.publisher!.trim()),
  if (book.publishedDate?.trim().isNotEmpty ?? false)
    ('Published', book.publishedDate!.trim()),
  if (book.isbn?.trim().isNotEmpty ?? false) ('ISBN', book.isbn!.trim()),
  if (book.language?.trim().isNotEmpty ?? false)
    ('Language', _languageLabel(book.language!.trim())),
];

String _languageLabel(String language) => switch (language.toLowerCase()) {
  'en' => 'English',
  'id' => 'Indonesian',
  _ => language.toUpperCase(),
};

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.metadata});

  final List<(String, String)> metadata;

  @override
  Widget build(BuildContext context) {
    if (metadata.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < metadata.length; index++) ...[
            if (index > 0) const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    metadata[index].$1,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF777787),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    metadata[index].$2,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF17162D),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
