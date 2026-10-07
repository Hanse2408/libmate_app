import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/services/ebook_service.dart';
import '../../../../models/ebook.dart';
import '../../common/data/student_library_repository.dart';
import '../providers/student_ebook_provider.dart';
import '../widgets/ebook_ui.dart';

/// Builds the PDF view for the loaded [bytes]. Tests swap it out, because
/// the real viewer needs the PDF engine.
typedef EbookPdfViewBuilder = Widget Function(
  BuildContext context,
  Uint8List bytes,
  String sourceName,
  EbookPdfViewCallbacks callbacks,
);

/// What the PDF view reports back to the reader screen.
class EbookPdfViewCallbacks {
  const EbookPdfViewCallbacks({
    required this.controller,
    required this.onReady,
    required this.onPageChanged,
    required this.onRetry,
  });

  final PdfViewerController controller;
  final void Function(int pageCount) onReady;
  final void Function(int? pageNumber) onPageChanged;
  final VoidCallback onRetry;
}

/// Reads an e-book's PDF inside the app (no download). The PDF is the one
/// the librarian uploaded to Cloudinary, loaded from its saved `pdfUrl`
/// through StudentEbookProvider (which reports the real reason if the file
/// host refuses it) and rendered by pdfrx.
/// Scrolls through the pages; pinch / Ctrl + scroll or the buttons zoom.
class EbookReaderScreen extends StatefulWidget {
  const EbookReaderScreen({
    super.key,
    required this.library,
    required this.ebookId,
  });

  final StudentLibraryRepository library;
  final String ebookId;

  /// The PDF view; replaced in tests.
  static EbookPdfViewBuilder pdfViewBuilder = _pdfrxView;

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  final _controller = PdfViewerController();
  int _attempt = 0; // bumped by Try again to load the PDF again

  String? _requestedUrl; // the pdfUrl being (or last) loaded
  Uint8List? _bytes;
  String? _error;
  double? _progress;
  int? _pageCount;
  int? _page;

  StudentEbookProvider get _provider => widget.library.ebooks;

  /// Loads [ebook]'s PDF once per URL (and again on Try again).
  void _loadIfNeeded(EbookRecord ebook) {
    final url = ebook.pdfUrl;
    if (url == null || url == _requestedUrl) return;
    _requestedUrl = url;
    final attempt = ++_attempt;
    _bytes = null;
    _error = null;
    _progress = null;
    _pageCount = null;
    _page = null;
    unawaited(_load(ebook, attempt));
  }

  Future<void> _load(EbookRecord ebook, int attempt) async {
    try {
      final bytes = await _provider.loadForReading(
        ebook,
        onProgress: (received, total) {
          if (mounted && attempt == _attempt && total != null && total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (mounted && attempt == _attempt) setState(() => _bytes = bytes);
    } on EbookReadException catch (e) {
      if (mounted && attempt == _attempt) setState(() => _error = e.message);
    } catch (_) {
      if (mounted && attempt == _attempt) {
        setState(
          () => _error = 'Could not open this e-book. Please try again.',
        );
      }
    }
  }

  void _retry() => setState(() => _requestedUrl = null);

  void _zoom({required bool up}) {
    if (!_controller.isReady) return;
    up ? _controller.zoomUp() : _controller.zoomDown();
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
              final uri = ebook == null ? null : _provider.readOnlineUri(ebook);
              if (ebook != null && uri != null) _loadIfNeeded(ebook);
              return Column(
                children: [
                  EbookPageHeader(
                    title: ebook?.title ?? 'Read Online',
                    subtitle: _pageCount == null
                        ? ebook?.author
                        : 'Page ${_page ?? 1} of $_pageCount',
                  ),
                  Expanded(
                    child: uri == null
                        ? _message(
                            context,
                            _provider.isLoading && ebook == null
                                ? null
                                : ebook == null
                                ? 'This e-book is no longer available.'
                                : 'The PDF for this e-book is not available yet. Please check again later.',
                          )
                        : _error != null
                        ? EbookReaderError(message: _error!, onRetry: _retry)
                        : _bytes == null
                        ? EbookReaderLoading(progress: _progress)
                        : Stack(
                            children: [
                              Positioned.fill(
                                child: KeyedSubtree(
                                  key: ValueKey('$uri#$_attempt'),
                                  child: EbookReaderScreen.pdfViewBuilder(
                                    context,
                                    _bytes!,
                                    uri.toString(),
                                    EbookPdfViewCallbacks(
                                      controller: _controller,
                                      onReady: (count) {
                                        if (mounted && count != _pageCount) {
                                          setState(() => _pageCount = count);
                                        }
                                      },
                                      onPageChanged: (page) {
                                        if (mounted &&
                                            page != null &&
                                            page != _page) {
                                          setState(() => _page = page);
                                        }
                                      },
                                      onRetry: _retry,
                                    ),
                                  ),
                                ),
                              ),
                              if (_pageCount != null)
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: _ZoomButtons(
                                    onZoomIn: () => _zoom(up: true),
                                    onZoomOut: () => _zoom(up: false),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// A spinner (null text) or a centred message.
  Widget _message(BuildContext context, String? text) {
    final c = EbookColors.of(context);
    return Center(
      child: text == null
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 15),
              ),
            ),
    );
  }
}

/// The real viewer: pdfrx renders the loaded PDF (PDFium; WebAssembly on
/// Flutter Web).
Widget _pdfrxView(
  BuildContext context,
  Uint8List bytes,
  String sourceName,
  EbookPdfViewCallbacks callbacks,
) {
  final c = EbookColors.of(context);
  return PdfViewer.data(
    bytes,
    sourceName: sourceName,
    controller: callbacks.controller,
    params: PdfViewerParams(
      backgroundColor: c.background,
      pageDropShadow: BoxShadow(
        color: c.text.withValues(alpha: 0.18),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
      onViewerReady: (document, controller) =>
          callbacks.onReady(document.pages.length),
      onPageChanged: callbacks.onPageChanged,
      loadingBannerBuilder: (context, downloaded, total) =>
          const EbookReaderLoading(),
      errorBannerBuilder: (context, error, stackTrace, documentRef) =>
          EbookReaderError(
            message: 'This file could not be opened as a PDF. Please tell the library.',
            onRetry: callbacks.onRetry,
          ),
    ),
  );
}

/// Shown while the PDF is loading.
class EbookReaderLoading extends StatelessWidget {
  const EbookReaderLoading({super.key, this.progress});

  /// 0.0–1.0 when the size is known.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return ColoredBox(
      color: c.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress, color: c.primary),
            const SizedBox(height: 14),
            Text(
              progress == null
                  ? 'Opening the e-book…'
                  : 'Opening the e-book… ${(progress! * 100).round()}%',
              style: TextStyle(color: c.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the PDF cannot be opened, with the reason ([message]).
class EbookReaderError extends StatelessWidget {
  const EbookReaderError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return ColoredBox(
      color: c.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.report_gmailerrorred_rounded,
                color: c.error,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                key: const ValueKey('ebook-reader-error'),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.text, fontSize: 15),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  foregroundColor: c.primary,
                  side: BorderSide(color: c.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    Widget button(IconData icon, String tip, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, color: c.text),
    );
    return Material(
      color: c.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.add_rounded, 'Zoom in', onZoomIn),
          Container(width: 28, height: 1, color: c.border),
          button(Icons.remove_rounded, 'Zoom out', onZoomOut),
        ],
      ),
    );
  }
}
