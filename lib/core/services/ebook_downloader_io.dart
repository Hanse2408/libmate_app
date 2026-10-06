import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ebook_service.dart';

/// Downloader for Android and desktop.
EbookDownloader createEbookDownloader() => IoEbookDownloader();

/// Saves the PDF from its HTTPS URL into the user's Downloads
/// folder (a "LibMate" sub-folder), reporting progress as it downloads:
/// - Android: Download/LibMate (the public Downloads folder)
/// - Windows / macOS / Linux: `<home>/Downloads/LibMate`
class IoEbookDownloader implements EbookDownloader {
  IoEbookDownloader({
    http.Client? client,
    this.timeout = const Duration(minutes: 2),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
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
    final (folder, label) = _downloadsFolder();
    final File file;
    try {
      await folder.create(recursive: true);
      file = _uniqueFile(folder, fileName);
    } on FileSystemException {
      throw const EbookDownloadException(
        'This device does not allow LibMate to save into Downloads. '
        'Use "Open in browser" to download the PDF instead.',
        canOpenInBrowser: true,
      );
    }

    try {
      final response = await _client
          .send(http.Request('GET', uri))
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EbookDownloadException(
          'PDF download failed (HTTP ${response.statusCode}). Use "Open in browser" instead.',
          canOpenInBrowser: true,
        );
      }
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > _maxBytes) {
        throw const EbookDownloadException(
          'The PDF is too large to download here. Use "Open in browser" instead.',
          canOpenInBrowser: true,
        );
      }
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream.timeout(timeout)) {
          received += chunk.length;
          if (received > _maxBytes) {
            throw const EbookDownloadException(
              'The PDF is too large to download here. Use "Open in browser" instead.',
              canOpenInBrowser: true,
            );
          }
          sink.add(chunk);
          if (contentLength != null && contentLength > 0) {
            onProgress?.call(
              (received / contentLength).clamp(0.0, 1.0).toDouble(),
            );
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (received == 0) {
        throw const EbookDownloadException(
          'The PDF is empty. Please tell the library.',
          canOpenInBrowser: true,
        );
      }
      if (contentLength != null && received != contentLength) {
        throw const EbookDownloadException(
          'The download did not complete. Please try again.',
          canOpenInBrowser: true,
        );
      }
    } on EbookDownloadException {
      await _deletePartial(file);
      rethrow;
    } on TimeoutException {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'PDF download timed out. Check your internet connection and try again.',
        canOpenInBrowser: true,
      );
    } on SocketException {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'Could not reach the PDF server. Check your internet connection and try again.',
        canOpenInBrowser: true,
      );
    } on http.ClientException {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'Could not reach the PDF server. Check your internet connection and try again.',
        canOpenInBrowser: true,
      );
    } on FileSystemException {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'The PDF could not be saved on this device. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    } catch (_) {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'PDF download failed. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }

    // Only report success when the whole file is really on the device.
    if (!await file.exists() || await file.length() == 0) {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'The download did not complete. Please try again.',
      );
    }
    onProgress?.call(1);
    final name = file.uri.pathSegments.last;
    return SavedPdf(fileName: name, location: '$label/$name');
  }

  /// The folder to save in, and how to describe it to the user.
  (Directory, String) _downloadsFolder() {
    if (Platform.isAndroid) {
      return (
        Directory('/storage/emulated/0/Download/LibMate'),
        'Download/LibMate',
      );
    }
    final home =
        Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
    if (home == null || Platform.isIOS) {
      throw const EbookDownloadException(
        'Saving PDFs is not supported on this device. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }
    final sep = Platform.pathSeparator;
    return (
      Directory('$home${sep}Downloads${sep}LibMate'),
      'Downloads/LibMate',
    );
  }

  /// "Clean Code.pdf", or "Clean Code (2).pdf" if that name is taken.
  static File _uniqueFile(Directory folder, String fileName) {
    final dot = fileName.toLowerCase().lastIndexOf('.pdf');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    final sep = Platform.pathSeparator;
    var candidate = File('${folder.path}$sep$base.pdf');
    for (var i = 2; candidate.existsSync(); i++) {
      candidate = File('${folder.path}$sep$base ($i).pdf');
    }
    return candidate;
  }

  static Future<void> _deletePartial(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
