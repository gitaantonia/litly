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
            isbn: source.isbn,
            description: source.description,
            totalPages: source.totalPages,
            rating: source.rating,
            ratingsCount: source.ratingsCount,
            status: selected,
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

  String _plainDescription(String text) => text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final description = _plainDescription(widget.book.description ?? '');
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        title: Text(
          'Detail Buku',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 620;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 22,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: BookCover(url: widget.book.coverUrl, width: 180),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.book.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF252A3D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      widget.book.author,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  if (widget.book.rating != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF3B63F),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.book.rating!.toStringAsFixed(1)}'
                            '${widget.book.ratingsCount == null ? '' : ' (${widget.book.ratingsCount} ulasan)'}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _MetadataCard(book: widget.book),
                  const SizedBox(height: 22),
                  Text(
                    'Tentang Buku',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? 'Deskripsi buku belum tersedia.'
                        : description,
                    maxLines: _descriptionExpanded ? null : 5,
                    overflow: _descriptionExpanded
                        ? null
                        : TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.7,
                      color: Colors.black54,
                    ),
                  ),
                  if (description.length > 200)
                    TextButton(
                      onPressed: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded,
                      ),
                      child: Text(
                        _descriptionExpanded
                            ? 'Lebih Sedikit'
                            : 'Baca Selengkapnya',
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AppState>(
                      builder: (context, state, _) {
                        final saved = state.books
                            .where((book) => book.id == widget.book.id)
                            .firstOrNull;
                        return FilledButton.icon(
                          onPressed: _saving ? null : _selectStatus,
                          icon: Icon(
                            saved == null
                                ? Icons.bookmark_add_outlined
                                : Icons.bookmark_added_rounded,
                          ),
                          label: Text(
                            _saving
                                ? 'Menyimpan...'
                                : saved == null
                                ? 'Tambah ke Koleksi'
                                : 'Tersimpan • ${saved.status}',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: navy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final metadata = <(String, String)>[
      if (book.publisher?.isNotEmpty ?? false) ('Penerbit', book.publisher!),
      if (book.publishedDate?.isNotEmpty ?? false)
        ('Tahun terbit', book.publishedDate!),
      if (book.isbn?.isNotEmpty ?? false) ('ISBN', book.isbn!),
      (
        'Jumlah halaman',
        book.totalPages > 0 ? '${book.totalPages} halaman' : '—',
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var index = 0; index < metadata.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 105,
                  child: Text(
                    metadata[index].$1,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    metadata[index].$2,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
