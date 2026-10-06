import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/ebook_service.dart';
import '../../../core/services/firestore_errors.dart';
import '../../../models/action_result.dart';
import '../../../models/ebook.dart';
import '../../../repositories/ebook_repository.dart';

/// Screen state for E-book Management: the live list, search, loading /
/// error states and saving / upload progress. Created once by LibrarianShell
/// (only when an e-book screen is first opened) and read through
/// LibrarianScope, like the Librarian repository.
class EbookProvider extends ChangeNotifier {
  EbookProvider(this._repository) {
    _subscription = _repository.watchEbooks().listen(
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
  bool _isSaving = false;
  double? _uploadProgress;

  List<EbookRecord> get ebooks => _ebooks;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String get query => _query;
  bool get isSaving => _isSaving;

  /// 0.0–1.0 while a PDF uploads, otherwise null.
  double? get uploadProgress => _uploadProgress;

  int get publishedCount => _ebooks.where((e) => e.isPublished).length;

  /// E-books matching the search (title, author or ISBN).
  List<EbookRecord> get visibleEbooks {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _ebooks;
    final digits = q.replaceAll(RegExp(r'[^0-9x]'), '');
    return _ebooks.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.author.toLowerCase().contains(q) ||
          (digits.isNotEmpty && e.isbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toLowerCase().contains(digits));
    }).toList();
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

  /// Saves a new or edited e-book (see EbookRepository.save).
  Future<ActionResult> save({
    required EbookRecord ebook,
    required bool isNew,
    PdfFile? newPdf,
  }) {
    return _busy(
      uploading: newPdf != null,
      () => _repository.save(
        ebook: ebook,
        isNew: isNew,
        newPdf: newPdf,
        onUploadProgress: (value) {
          _uploadProgress = value;
          _notify();
        },
      ),
    );
  }

  /// Quick Action: uploads [pdf] as the new PDF of [ebook].
  Future<ActionResult> replacePdf(EbookRecord ebook, PdfFile pdf) =>
      save(ebook: ebook, isNew: false, newPdf: pdf);

  Future<ActionResult> delete(EbookRecord ebook) => _busy(() => _repository.delete(ebook));

  /// Runs an action with the saving state on, and always turns it off.
  Future<ActionResult> _busy(Future<ActionResult> Function() action, {bool uploading = false}) async {
    if (_isSaving) return const ActionResult.failure('Please wait for the current save to finish.');
    _isSaving = true;
    _uploadProgress = uploading ? 0 : null;
    _notify();
    try {
      return await action();
    } catch (_) {
      return const ActionResult.failure('Something went wrong. Please try again.');
    } finally {
      _isSaving = false;
      _uploadProgress = null;
      _notify();
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
