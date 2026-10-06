import 'package:flutter/material.dart';

import '../../../core/services/ebook_service.dart';
import '../../../models/ebook.dart';
import '../providers/ebook_provider.dart';
import '../theme/librarian_theme.dart';

/// PDF Quick Action for one e-book: open the PDF, replace it, or upload one
/// when it is missing, without opening the edit form.
Future<void> showEbookPdfSheet(
  BuildContext context, {
  required EbookProvider provider,
  required String ebookId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _EbookPdfSheet(provider: provider, ebookId: ebookId),
  );
}

class _EbookPdfSheet extends StatefulWidget {
  const _EbookPdfSheet({required this.provider, required this.ebookId});

  final EbookProvider provider;
  final String ebookId;

  @override
  State<_EbookPdfSheet> createState() => _EbookPdfSheetState();
}

class _EbookPdfSheetState extends State<_EbookPdfSheet> {
  String? _message;
  bool _messageIsError = false;

  void _show(String message, {bool error = false}) {
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  Future<void> _open(EbookRecord ebook) async {
    try {
      final opened = await PdfLauncher.instance.open(ebook.pdfUrl!);
      if (!opened) _show('Could not open the PDF on this device.', error: true);
    } catch (_) {
      _show('Could not open the PDF on this device.', error: true);
    }
  }

  Future<void> _replace(EbookRecord ebook) async {
    final (PdfFile? pdf, String? error) picked;
    try {
      picked = await PdfPickerService.instance.pickPdf();
    } catch (_) {
      _show('Could not open the file picker.', error: true);
      return;
    }
    final (pdf, error) = picked;
    if (error != null) return _show(error, error: true);
    if (pdf == null) return; // cancelled
    final result = await widget.provider.replacePdf(ebook, pdf);
    if (!mounted) return;
    result.success
        ? _show('PDF ${ebook.hasPdf ? 'replaced' : 'uploaded'}: ${pdf.fileName}.')
        : _show(result.message!, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final ebook = widget.provider.ebookById(widget.ebookId);
        final busy = widget.provider.isSaving;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LibrarianSpacing.lg,
              0,
              LibrarianSpacing.lg,
              LibrarianSpacing.lg,
            ),
            child: ebook == null
                ? Text('This e-book no longer exists.', style: TextStyle(color: LibrarianColors.secondaryText))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PDF Quick Actions',
                        style: TextStyle(color: LibrarianColors.text, fontSize: 21, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(ebook.title, style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 15)),
                      const SizedBox(height: LibrarianSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(LibrarianSpacing.md),
                        decoration: BoxDecoration(
                          color: LibrarianColors.lightBlue,
                          borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              ebook.hasPdf ? Icons.picture_as_pdf_outlined : Icons.report_gmailerrorred_outlined,
                              color: ebook.hasPdf ? LibrarianColors.unavailable : LibrarianColors.gold,
                              size: 32,
                            ),
                            const SizedBox(width: LibrarianSpacing.md),
                            Expanded(
                              child: Text(
                                ebook.hasPdf
                                    ? '${ebook.pdfFileName ?? 'book.pdf'}'
                                        '${ebook.pdfSizeBytes > 0 ? ' · ${EbookRecord.formatSize(ebook.pdfSizeBytes)}' : ''}'
                                    : 'No PDF has been uploaded for this e-book yet.',
                                style: TextStyle(color: LibrarianColors.text, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.provider.uploadProgress != null) ...[
                        const SizedBox(height: LibrarianSpacing.sm),
                        LinearProgressIndicator(value: widget.provider.uploadProgress),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: LibrarianSpacing.sm),
                        Text(
                          _message!,
                          style: TextStyle(
                            color: _messageIsError ? LibrarianColors.unavailable : LibrarianColors.available,
                          ),
                        ),
                      ],
                      const SizedBox(height: LibrarianSpacing.md),
                      if (ebook.hasPdf) ...[
                        FilledButton.icon(
                          onPressed: busy ? null : () => _open(ebook),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open PDF'),
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                        ),
                        const SizedBox(height: LibrarianSpacing.sm),
                      ],
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => _replace(ebook),
                        icon: Icon(ebook.hasPdf ? Icons.swap_horiz : Icons.upload_file_outlined),
                        label: Text(ebook.hasPdf ? 'Replace PDF' : 'Upload PDF'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
