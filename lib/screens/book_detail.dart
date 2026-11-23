import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/app_colors.dart';
import '../models/book.dart';
import '../providers/achievement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/goal_provider.dart';
import '../state/app_state.dart';

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
                  leading: const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.kPurple,
                  ),
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
      final authProvider = context.read<AuthProvider>();
      final goalProvider = context.read<GoalProvider>();
      final achievementProvider = context.read<AchievementProvider>();
      final userId = authProvider.user?.id ?? 0;
      if (state.containsBook(widget.book.id)) {
        final saved = state.books.firstWhere(
          (book) => book.id == widget.book.id,
        );
        saved.status = selected;
        saved.completedAt = selected == 'Completed' ? DateTime.now() : null;
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
            completedAt: selected == 'Completed' ? DateTime.now() : null,
          ),
        );
      }
      if (!mounted) return;
      String? progressWarning;
      try {
        await goalProvider.loadGoals(userId);
        await achievementProvider.checkAndShow(userId);
      } on Exception catch (error) {
        progressWarning =
            'Buku tersimpan, tetapi progres gagal diperbarui: $error';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            progressWarning ?? 'Status buku diperbarui ke $selected.',
          ),
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
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Book Details',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.kNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final saved = state.books
                .where((savedBook) => savedBook.id == book.id)
                .firstOrNull;
            final metadata = _editionMetadata(book);
            final stats = _buildStats(book);

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth > 620
                    ? 32.0
                    : 20.0;
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(book),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              18,
                              horizontalPadding,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_hasDisplayValue(book.title))
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(width: 44),
                                      Expanded(
                                        child: Text(
                                          book.title,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                            color: AppColors.kNavy,
                                          ),
                                        ),
                                      ),
                                      IconButton(
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
                                          color: AppColors.kPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_hasDisplayValue(book.author)) ...[
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      book.author,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_hasDisplayValue(book.category)) ...[
                                  const SizedBox(height: 12),
                                  Center(
                                    child: _DetailChip(
                                      label: book.category!.trim(),
                                    ),
                                  ),
                                ],
                                if (stats != null) ...[
                                  const SizedBox(height: 20),
                                  stats,
                                ],
                                const SizedBox(height: 20),
                                if (saved == null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _saving ? null : _selectStatus,
                                      icon: const Icon(
                                        Icons.bookmark_add_outlined,
                                      ),
                                      label: Text(
                                        _saving
                                            ? 'Saving...'
                                            : 'Add to My Library',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.kPurple,
                                        foregroundColor: Colors.white,
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
                                      color: AppColors.kNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    maxLines: _descriptionExpanded ? null : 5,
                                    overflow: _descriptionExpanded
                                        ? null
                                        : TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      height: 1.65,
                                      color: AppColors.textSecondary,
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
                                        foregroundColor: AppColors.kPurple,
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
                                if (metadata.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    'Edition Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.kNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _MetadataCard(metadata: metadata),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(Book book) {
    final coverUrl = _hasDisplayValue(book.coverUrl) ? book.coverUrl : null;
    return SizedBox(
      height: 252,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null)
            ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: AppColors.kLightPurple),
                  errorWidget: (_, _, _) =>
                      const ColoredBox(color: AppColors.kLightPurple),
                ),
              ),
            )
          else
            const ColoredBox(color: AppColors.kLightPurple),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.kYellow.withValues(alpha: 0.7),
                  AppColors.kLightPurple.withValues(alpha: 0.84),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 148,
              height: 214,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.kNavy.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: coverUrl == null
                    ? const _DetailCoverPlaceholder()
                    : CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _DetailCoverPlaceholder(),
                        errorWidget: (_, _, _) =>
                            const _DetailCoverPlaceholder(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildStats(Book book) {
    final stats = <Widget>[
      if (book.rating != null)
        _DetailStat(
          icon: Icons.star_rounded,
          iconColor: AppColors.kNavy,
          iconBackground: AppColors.kYellow,
          value: book.rating!.toStringAsFixed(1),
          label: 'Rating',
        ),
      if (book.totalPages > 0)
        _DetailStat(
          icon: Icons.menu_book_rounded,
          iconColor: AppColors.kPurple,
          iconBackground: AppColors.kLightPurple,
          value: '${book.totalPages}',
          label: 'Pages',
        ),
      if (_hasDisplayValue(book.language))
        _DetailStat(
          icon: Icons.translate_rounded,
          iconColor: AppColors.kPurple,
          iconBackground: AppColors.kLightPurple,
          value: _languageLabel(book.language!.trim()),
          label: 'Language',
        )
      else if ((book.ratingsCount ?? 0) > 0)
        _DetailStat(
          icon: Icons.rate_review_outlined,
          iconColor: AppColors.kPurple,
          iconBackground: AppColors.kLightPurple,
          value: '${book.ratingsCount}',
          label: 'Reviews',
        ),
    ];

    if (stats.isEmpty) return null;
    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: stats[index]),
        ],
      ],
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

class _DetailCoverPlaceholder extends StatelessWidget {
  const _DetailCoverPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.kLightPurple,
    child: Center(
      child: Icon(Icons.menu_book_rounded, color: AppColors.kPurple, size: 38),
    ),
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kLightPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.kPurple,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kNavy,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.textSecondary,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: AppColors.kPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reading Status',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kNavy,
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
                    color: AppColors.kLightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _readingStatusLabel(book.status),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kPurple,
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${(book.progress * 100).round()}% Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kPurple,
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
                backgroundColor: AppColors.kLightPurple,
                color: AppColors.kPurple,
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
            color: AppColors.kNavy.withValues(alpha: 0.04),
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
                      color: AppColors.textSecondary,
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
                      color: AppColors.kNavy,
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
