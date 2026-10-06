import 'dart:async';
import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'ebook_service.dart';

/// Downloader for the web build.
EbookDownloader createEbookDownloader() => WebEbookDownloader();

/// Fetches the Cloudinary HTTPS PDF, then hands it to the browser as a file
/// download. If the cross-origin fetch is blocked, the link can still be
/// opened directly in the browser.
class WebEbookDownloader implements EbookDownloader {
  WebEbookDownloader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const int _maxBytes = 30 * 1024 * 1024;

  @override
  Future<SavedPdf> download({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const EbookDownloadException(
        'The PDF link is invalid. Please tell the library.',
      );
    }
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(minutes: 2));
    } on TimeoutException {
      throw const EbookDownloadException(
        'PDF download timed out. Check your internet connection and try again.',
        canOpenInBrowser: true,
      );
    } on http.ClientException {
      throw const EbookDownloadException(
        'The PDF could not be downloaded here. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    } catch (_) {
      throw const EbookDownloadException(
        'The PDF could not be downloaded here. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EbookDownloadException(
        'PDF download failed (HTTP ${response.statusCode}). Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const EbookDownloadException(
        'The PDF is empty. Please tell the library.',
      );
    }
    if (bytes.length > _maxBytes) {
      throw const EbookDownloadException(
        'The PDF is too large to download here. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }

    final name = fileName.toLowerCase().endsWith('.pdf')
        ? fileName
        : '$fileName.pdf';
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = name;
    web.document.body?.append(link);
    link.click();
    link.remove();
    // Give the browser a moment to start saving before releasing the data.
    Timer(
      const Duration(seconds: 30),
      () => web.URL.revokeObjectURL(objectUrl),
    );
    onProgress?.call(1);
    return SavedPdf(
      fileName: name,
      location: "your browser's Downloads folder",
    );
  }
}
