import 'package:flutter/material.dart';

import '../../../../models/ebook.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import '../providers/student_ebook_provider.dart';
import '../widgets/ebook_ui.dart';

/// E-book details with the Download PDF action. Reads the e-book live, so
/// changes made by a librarian (or removal) show up straight away.
class EbookDetailsScreen extends StatefulWidget {
  const EbookDetailsScreen({super.key, required this.library, required this.ebookId});

  final StudentLibraryRepository library;
  final String ebookId;

  @override
  State<EbookDetailsScreen> createState() => _EbookDetailsScreenState();
}

class _EbookDetailsScreenState extends State<EbookDetailsScreen> {
  /// Last finished download, shown under the button.
  EbookDownloadResult? _result;

  StudentEbookProvider get _provider => widget.library.ebooks;

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _download(EbookRecord ebook) async {
    setState(() => _result = null);
    final result = await _provider.download(ebook);
    if (!mounted) return;
    setState(() => _result = result);
    // Only now is the file saved (or the download refused).
    _snack(result.success ? 'Download complete: ${result.saved!.location}' : result.message!);
  }

  Future<void> _openInBrowser(EbookRecord ebook) async {
    final opened = await _provider.openInBrowser(ebook);
    if (!opened && mounted) _snack('Could not open the PDF on this device.');
  }

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _provider,
          builder: (context, _) {
            final ebook = _provider.ebookById(widget.ebookId);
            return Column(
              children: [
                const EbookPageHeader(title: 'E-book Details'),
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
    );
  }

  Widget _details(BuildContext context, EbookRecord ebook) {
    final c = EbookColors.of(context);
    final downloading = _provider.downloadingId == ebook.id;
    final busy = _provider.downloadingId != null;
    final progress = _provider.downloadProgress;
    final size = EbookRecord.formatSize(ebook.pdfSizeBytes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      children: [
        Center(
          child: StudentBookCover(
            title: ebook.title,
            author: ebook.author,
            imageUrl: ebook.coverAsset, // an assets/images/books/ path
            width: 158,
            height: 218,
            radius: 12,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          ebook.title,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.text, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text('by ${ebook.author}', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 14)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const EbookBadge(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(8)),
              child: Text(ebook.category, style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w600)),
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
        Text('Description', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          ebook.description.isEmpty ? 'No description has been added yet.' : ebook.description,
          style: TextStyle(color: c.muted, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 22),
        // The PDF file (or why it cannot be downloaded).
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ebook.hasPdf ? c.border : c.error.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                ebook.hasPdf ? Icons.picture_as_pdf_rounded : Icons.report_gmailerrorred_rounded,
                color: c.error, // PDF red, also for the warning icon
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ebook.hasPdf
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
            onPressed: ebook.hasPdf && !busy ? () => _download(ebook) : null,
            icon: downloading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: c.onPrimary),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              downloading
                  ? (progress == null ? 'Downloading…' : 'Downloading… ${(progress * 100).round()}%')
                  : ebook.hasPdf
                  ? 'Download PDF'
                  : 'PDF not available',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (downloading && progress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
        if (_result != null && !downloading) ...[
          const SizedBox(height: 12),
          Text(
            _result!.success
                ? 'Saved to ${_result!.saved!.location}'
                : _result!.message!,
            key: const ValueKey('ebook-download-result'),
            style: TextStyle(color: _result!.success ? c.success : c.error, fontSize: 13),
          ),
          if (!_result!.success && _result!.canOpenInBrowser) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openInBrowser(ebook),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open in browser'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 34, color: c.border),
            Expanded(
              child: Column(
                children: [
                  Text(items[i].$1, style: TextStyle(color: c.muted, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(
                    items[i].$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w700),
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
