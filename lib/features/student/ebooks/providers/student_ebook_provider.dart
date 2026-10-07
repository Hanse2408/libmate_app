import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/ebook_service.dart';
import '../../../../core/services/firestore_errors.dart';
import '../../../../models/ebook.dart';
import '../../../../repositories/ebook_repository.dart';

/// Student e-book screens state: the live list of published e-books from
/// the shared `ebooks` collection, search, and the PDF link for reading online.
class StudentEbookProvider extends ChangeNotifier {
  StudentEbookProvider(this._repository) {
    _subscription = _repository.watchPublishedEbooks().listen(
      (ebooks) {
        _ebooks = [...ebooks]
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        _isLoading = false;
        _loadError = null;
        _notify();
      },
      onError: (Object error) {
        _isLoading = false;
        _loadError =
            'Could not load e-books. '
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

  List<EbookRecord> get ebooks => _ebooks;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String get query => _query;

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

  /// The PDF to read online: the e-book's existing Cloudinary link
  /// (`pdfUrl`, the secure URL saved when the librarian uploaded it).
  /// Null when there is no PDF or the link is not a web address.
  Uri? readOnlineUri(EbookRecord ebook) {
    if (!ebook.hasPdf) return null;
    final uri = Uri.tryParse(ebook.pdfUrl!.trim());
    final isWeb = uri != null && (uri.isScheme('https') || uri.isScheme('http'));
    return isWeb ? uri : null;
  }

  /// Loads [ebook]'s PDF into memory for the reader (not saved anywhere).
  /// Throws EbookReadException with a message for the student.
  Future<Uint8List> loadForReading(
    EbookRecord ebook, {
    void Function(int received, int? total)? onProgress,
  }) {
    final uri = readOnlineUri(ebook);
    if (uri == null) {
      throw const EbookReadException(
        'The PDF for this e-book is not available yet. Please check again later.',
      );
    }
    return _repository.loadPdfForReading(uri, onProgress: onProgress);
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
