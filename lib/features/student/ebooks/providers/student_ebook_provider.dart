import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/ebook_service.dart';
import '../../../../core/services/firestore_errors.dart';
import '../../../../models/ebook.dart';
import '../../../../repositories/ebook_repository.dart';

/// Result of a PDF download shown on the e-book details screen.
class EbookDownloadResult {
  const EbookDownloadResult.saved(SavedPdf this.saved)
    : success = true,
      message = null,
      canOpenInBrowser = false;

  const EbookDownloadResult.failed(String this.message, {this.canOpenInBrowser = false})
    : success = false,
      saved = null;

  final bool success;
  final SavedPdf? saved;
  final String? message;

  /// The PDF can still be opened with its link (e.g. saving is not allowed).
  final bool canOpenInBrowser;
}

/// Student e-book screens state: the live list of published e-books from
/// the shared `ebooks` collection, search, and PDF downloads.
class StudentEbookProvider extends ChangeNotifier {
  StudentEbookProvider(this._repository) {
    _subscription = _repository.watchPublishedEbooks().listen(
      (ebooks) {
        _ebooks = [...ebooks]
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        _isLoading = false;
        _loadError = null;
        _notify();
      },
      onError: (Object error) {
        _isLoading = false;
        _loadError = 'Could not load e-books. '
            '${error is FirebaseException ? describeFirestoreError(error) : ''}'
            .trim();
        _notify();
      },
    );
  }

  final EbookRepository _repository;
  late final StreamSubscription<List<EbookRecord>> _subscription;
  bool _disposed = false;

  List<EbookRecord> _ebooks = const [];
  bool _isLoading = true;
  String? _loadError;
  String _query = '';
  String? _downloadingId;
  double? _progress;

  List<EbookRecord> get ebooks => _ebooks;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String get query => _query;

  /// The e-book whose PDF is downloading, if any (one at a time).
  String? get downloadingId => _downloadingId;

  /// 0.0–1.0 while downloading, when the platform reports progress.
  double? get downloadProgress => _progress;

  /// E-books matching the search (title, author or category).
  List<EbookRecord> get visibleEbooks {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _ebooks;
    return _ebooks
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.author.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q),
        )
        .toList();
  }

  EbookRecord? ebookById(String id) {
    for (final e in _ebooks) {
      if (e.id == id) return e;
    }
    return null;
  }

  void search(String query) {
    _query = query;
    _notify();
  }

  /// Downloads [ebook]'s PDF. Success is only returned after the file is
  /// saved; a second tap while downloading is ignored.
  Future<EbookDownloadResult> download(EbookRecord ebook) async {
    if (_downloadingId != null) {
      return const EbookDownloadResult.failed('A download is already in progress.');
    }
    if (!ebook.hasPdf) {
      return const EbookDownloadResult.failed('No PDF is available for this e-book yet.');
    }
    _downloadingId = ebook.id;
    _progress = null;
    _notify();
    try {
      final saved = await _repository.downloadPdf(
        ebook,
        onProgress: (value) {
          _progress = value;
          _notify();
        },
      );
      return EbookDownloadResult.saved(saved);
    } on EbookDownloadException catch (e) {
      return EbookDownloadResult.failed(e.message, canOpenInBrowser: e.canOpenInBrowser);
    } catch (_) {
      return const EbookDownloadResult.failed(
        'The download failed. Please try again.',
        canOpenInBrowser: true,
      );
    } finally {
      _downloadingId = null;
      _progress = null;
      _notify();
    }
  }

  /// Opens the PDF link in the browser / PDF viewer (fallback when the app
  /// cannot save files on this device).
  Future<bool> openInBrowser(EbookRecord ebook) async {
    if (!ebook.hasPdf) return false;
    try {
      return await PdfLauncher.instance.open(ebook.pdfUrl!);
    } catch (_) {
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
