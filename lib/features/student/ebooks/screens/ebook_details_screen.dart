import '../../common/widgets/favorite_button.dart';
import 'package:flutter/material.dart';

import '../../../../models/ebook.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import '../providers/student_ebook_provider.dart';
import '../widgets/ebook_ui.dart';
import 'ebook_reader_screen.dart';

/// E-book details with the Read Online action (the PDF opens in the app). Reads the e-book live, so
/// changes made by a librarian (or removal) show up straight away.
class EbookDetailsScreen extends StatefulWidget {
  const EbookDetailsScreen({
    super.key,
    required this.library,
    required this.ebookId,
  });

  final StudentLibraryRepository library;
  final String ebookId;

  @override
  State<EbookDetailsScreen> createState() => _EbookDetailsScreenState();
}

class _EbookDetailsScreenState extends State<EbookDetailsScreen> {
  StudentEbookProvider get _provider => widget.library.ebooks;

  void _readOnline() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EbookReaderScreen(library: widget.library, ebookId: widget.ebookId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return StudentEbookTheme(
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _provider,
            builder: (context, _) {
              final ebook = _provider.ebookById(widget.ebookId);
              return Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: EbookPageHeader(title: 'E-book Details')),
                      if (ebook != null) Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: FavoriteButton(library: widget.library, itemId: widget.ebookId, ebook: true),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ebook == null
                        ? Center(
                            child: _provider.isLoading
                                ? const CircularProgressIndicator()
                                : Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'This e-book is no longer available.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: c.muted, fontSize: 15),
                                    ),
                                  ),
                          )
                        : _details(context, ebook),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _details(BuildContext context, EbookRecord ebook) {
    final c = EbookColors.of(context);
    final canRead = _provider.readOnlineUri(ebook) != null;
    final size = EbookRecord.formatSize(ebook.pdfSizeBytes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color.alphaBlend(c.primary.withValues(alpha: .12), c.surface), c.surface]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.primary.withValues(alpha: .2)),
          ),
          child: Center(child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .2),
                blurRadius: 22, offset: const Offset(0, 10))]),
            child: StudentBookCover(title: ebook.title, author: ebook.author,
              imageUrl: ebook.coverAsset, width: 150, height: 206, radius: 12),
          )),
        ),
        const SizedBox(height: 20),
        Text(
          ebook.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.text,
            fontSize: 25,
            letterSpacing: -.6,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'by ${ebook.author}',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.muted, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const EbookBadge(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: c.tint,
                border: Border.all(color: c.primary.withValues(alpha: .2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ebook.category,
                style: TextStyle(
                  color: c.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _InfoRow(
          items: [
            ('Publisher', ebook.publisher.isEmpty ? '—' : ebook.publisher),
            ('Year', ebook.publishedYear > 0 ? '${ebook.publishedYear}' : '—'),
            ('Pages', ebook.pages > 0 ? '${ebook.pages}' : '—'),
          ],
        ),
        const SizedBox(height: 10),
        _InfoRow(
          items: [
            ('Language', ebook.language.isEmpty ? '—' : ebook.language),
            ('ISBN', ebook.isbn.isEmpty ? '—' : ebook.isbn),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Description',
          style: TextStyle(
            color: c.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ebook.description.isEmpty
              ? 'No description has been added yet.'
              : ebook.description,
          style: TextStyle(color: c.muted, fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 22),
        // The PDF file (or why it cannot be read yet).
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: canRead ? c.primary.withValues(alpha: .22) : c.error.withValues(alpha: .5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                canRead
                    ? Icons.picture_as_pdf_rounded
                    : Icons.report_gmailerrorred_rounded,
                color: c.error, // PDF red, also for the warning icon
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  canRead
                      ? '${ebook.pdfFileName ?? 'E-book PDF'}${size.isEmpty ? '' : ' · $size'}'
                      : 'The PDF for this e-book is not available yet. Please check again later.',
                  style: TextStyle(color: c.text, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: canRead ? _readOnline : null,
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(
              canRead ? 'Read Online' : 'PDF not available',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              elevation: 0,
              foregroundColor: c.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of label / value pairs in a bordered card (as on Book Details).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.primary.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 34, color: c.primary.withValues(alpha: .15)),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].$1,
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    items[i].$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
