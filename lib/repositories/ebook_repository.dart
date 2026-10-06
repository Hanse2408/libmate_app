import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../core/services/ebook_service.dart';
import '../core/services/firestore_errors.dart';
import '../core/services/image_storage_service.dart';
import '../models/action_result.dart';
import '../models/ebook.dart';

/// E-book rules and the order of Firestore / Storage steps. Sits between
/// EbookProvider (screen state) and EbookService (Firebase calls).
///
/// Every action returns an ActionResult, so a screen only reports success
/// when Firestore (and Storage) really confirmed it.
class EbookRepository {
  EbookRepository({
    required this._service,
    this._downloader,
    this.librarianUid = '',
    this.uploadTimeout = const Duration(minutes: 3),
    this.writeTimeout = const Duration(seconds: 30),
  });

  final EbookService _service;

  /// Saves PDFs on the device (Student side); null on the Librarian side.
  final EbookDownloader? _downloader;
  final String librarianUid;

  /// Longest wait for a PDF upload (PDFs can be up to 25 MB).
  final Duration uploadTimeout;

  /// Longest wait for Firestore to confirm a write.
  final Duration writeTimeout;

  Stream<List<EbookRecord>> watchEbooks() => _service.watchEbooks();

  /// Published e-books only (Student side).
  Stream<List<EbookRecord>> watchPublishedEbooks() => _service.watchPublishedEbooks();

  /// Downloads the e-book's PDF to the device. Completes only when the file
  /// is saved; otherwise throws EbookDownloadException with the reason.
  Future<SavedPdf> downloadPdf(EbookRecord ebook, {void Function(double progress)? onProgress}) {
    final downloader = _downloader;
    if (downloader == null) {
      throw const EbookDownloadException('Downloads are not available here.');
    }
    if (!ebook.hasPdf) {
      throw const EbookDownloadException('No PDF is available for this e-book yet.');
    }
    return downloader.download(
      storagePath: ebook.pdfPath,
      url: ebook.pdfUrl!,
      fileName: _fileNameFor(ebook),
      onProgress: onProgress,
    );
  }

  /// A safe file name from the title, e.g. "Clean Code.pdf".
  static String _fileNameFor(EbookRecord ebook) {
    final cleaned = ebook.title.replaceAll(RegExp(r'[\/:*?"<>|]'), '').trim();
    return '${cleaned.isEmpty ? 'ebook' : cleaned}.pdf';
  }

  /// Creates ([isNew]) or updates [ebook]. [newPdf] is uploaded first and
  /// replaces the current PDF. Publishing needs a PDF; drafts do not.
  Future<ActionResult> save({
    required EbookRecord ebook,
    required bool isNew,
    PdfFile? newPdf,
    void Function(double progress)? onUploadProgress,
  }) async {
    if (ebook.isPublished && !ebook.hasPdf && newPdf == null) {
      return const ActionResult.failure('Upload the PDF before publishing the e-book.');
    }

    final id = isNew ? _service.newId() : ebook.id;
    String? uploadedPath;
    // True once the write was sent but not confirmed (offline): Firestore
    // may still save it later, so the uploaded PDF must be kept.
    var writeMayArrive = false;

    final result = await _run(() async {
      if (ebook.isbn.trim().isNotEmpty &&
          await _service.isbnInUse(ebook.isbn, exceptId: isNew ? null : id)) {
        throw const ActionRefused('Another e-book already uses this ISBN.');
      }

      var record = EbookRecord(
        id: id,
        title: ebook.title.trim(),
        author: ebook.author.trim(),
        category: ebook.category.trim(),
        language: ebook.language.trim(),
        isbn: ebook.isbn.trim(),
        description: ebook.description.trim(),
        publisher: ebook.publisher.trim(),
        publishedYear: ebook.publishedYear,
        pages: ebook.pages,
        location: ebook.location.trim().isEmpty ? EbookRecord.defaultLocation : ebook.location.trim(),
        coverAsset: ebook.coverAsset,
        pdfUrl: ebook.pdfUrl,
        pdfPath: ebook.pdfPath,
        pdfFileName: ebook.pdfFileName,
        pdfSizeBytes: ebook.pdfSizeBytes,
        status: ebook.status,
      );

      if (newPdf != null) {
        uploadedPath = _service.pdfPathFor(id);
        final url = await _service
            .uploadPdf(uploadedPath!, newPdf, onProgress: onUploadProgress)
            .timeout(
              uploadTimeout,
              onTimeout: () => throw ImageStorageException(
                'The PDF upload did not finish within ${uploadTimeout.inMinutes} '
                'minutes, so nothing was saved. Check your connection and that '
                'Firebase Storage is enabled.',
              ),
            );
        record = record.copyWith(
          pdfUrl: url,
          pdfPath: uploadedPath,
          pdfFileName: newPdf.fileName,
          pdfSizeBytes: newPdf.sizeBytes,
        );
      }

      final write = isNew
          ? _service.create(record, createdBy: librarianUid)
          : _service.update(record);
      try {
        await write.timeout(writeTimeout);
      } on TimeoutException {
        writeMayArrive = true;
        throw ActionRefused(
          'Firebase did not confirm the save within ${writeTimeout.inSeconds} '
          'seconds (you may be offline). Check E-book Management before trying again.',
        );
      }

      // Read it back: success is only reported when the document exists.
      final saved = await _service.fetchFromServer(id).timeout(writeTimeout);
      if (saved == null || saved.pdfPath != record.pdfPath) {
        throw const ActionRefused('Firebase did not return the saved e-book. Please check the list.');
      }
    });

    if (result.success) {
      // The replaced PDF is no longer used.
      final oldPath = ebook.pdfPath;
      if (!isNew && uploadedPath != null && oldPath != null && oldPath != uploadedPath) {
        await _deleteQuietly(oldPath);
      }
    } else if (uploadedPath != null && !writeMayArrive) {
      // The e-book was not saved: do not leave its new PDF behind.
      await _deleteQuietly(uploadedPath!);
    }
    return result;
  }

  /// Deletes the e-book document, then its PDF from Storage.
  Future<ActionResult> delete(EbookRecord ebook) async {
    final removed = await _run(() => _service.delete(ebook.id).timeout(writeTimeout));
    if (!removed.success) return removed;
    final path = ebook.pdfPath;
    if (path == null) return removed;
    try {
      await _service.deletePdf(path);
      return removed;
    } catch (e) {
      return ActionResult.failure(
        '"${ebook.title}" was deleted, but its PDF could not be removed from '
        'Storage ($e). You can delete $path in the Firebase console.',
      );
    }
  }

  Future<ActionResult> _run(Future<void> Function() action) async {
    try {
      await action();
      return const ActionResult.success();
    } on ActionRefused catch (e) {
      return ActionResult.failure(e.message);
    } on ImageStorageException catch (e) {
      return ActionResult.failure(e.message);
    } on FirebaseException catch (e) {
      return ActionResult.failure(describeFirestoreError(e));
    } on TimeoutException {
      return const ActionResult.failure('Firebase did not respond in time. Please try again.');
    } catch (_) {
      return const ActionResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await _service.deletePdf(path);
    } catch (_) {}
  }
}
