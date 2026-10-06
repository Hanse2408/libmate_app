import 'dart:async';
import 'dart:js_interop';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:web/web.dart' as web;

import 'ebook_service.dart';

/// Downloader for the web build.
EbookDownloader createEbookDownloader({FirebaseStorage? storage}) =>
    WebEbookDownloader(storage: storage);

/// Fetches the PDF from Firebase Storage, then hands it to the browser as a
/// file download, which the browser saves in its Downloads folder.
/// (Needs a CORS rule on the Storage bucket; see the setup notes.)
class WebEbookDownloader implements EbookDownloader {
  WebEbookDownloader({this._storage});

  final FirebaseStorage? _storage;
  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;

  static const int _maxBytes = 30 * 1024 * 1024;

  @override
  Future<SavedPdf> download({
    required String? storagePath,
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final ref = storagePath != null ? _instance.ref(storagePath) : _instance.refFromURL(url);
    final bytes = await (() async {
      try {
        return await ref.getData(_maxBytes);
      } on FirebaseException catch (e) {
        throw EbookDownloadException(
          e.code == 'object-not-found'
              ? 'The PDF file for this e-book is missing. Please tell the library.'
              : 'The PDF could not be downloaded here. Use "Open in browser" instead.',
          canOpenInBrowser: e.code != 'object-not-found',
        );
      } catch (_) {
        // Usually a missing CORS rule on the bucket.
        throw const EbookDownloadException(
          'The PDF could not be downloaded here. Use "Open in browser" instead.',
          canOpenInBrowser: true,
        );
      }
    })();
    if (bytes == null || bytes.isEmpty) {
      throw const EbookDownloadException('The PDF is empty. Please tell the library.');
    }

    final name = fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
    final objectUrl = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = name;
    web.document.body?.append(link);
    link.click();
    link.remove();
    // Give the browser a moment to start saving before releasing the data.
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(objectUrl));
    onProgress?.call(1);
    return SavedPdf(fileName: name, location: "your browser's Downloads folder");
  }
}
