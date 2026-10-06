import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'ebook_service.dart';

/// Downloader for Android and desktop.
EbookDownloader createEbookDownloader({FirebaseStorage? storage}) =>
    IoEbookDownloader(storage: storage);

/// Saves the PDF straight from Firebase Storage into the user's Downloads
/// folder (a "LibMate" sub-folder), reporting progress as it downloads:
/// - Android: Download/LibMate (the public Downloads folder)
/// - Windows / macOS / Linux: `<home>/Downloads/LibMate`
class IoEbookDownloader implements EbookDownloader {
  IoEbookDownloader({this._storage});

  final FirebaseStorage? _storage;
  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;

  @override
  Future<SavedPdf> download({
    required String? storagePath,
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
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

    final ref = storagePath != null ? _instance.ref(storagePath) : _instance.refFromURL(url);
    try {
      final task = ref.writeToFile(file);
      final progress = task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
      }, onError: (_) {});
      try {
        await task;
      } finally {
        await progress.cancel();
      }
    } on FirebaseException catch (e) {
      await _deletePartial(file);
      throw EbookDownloadException(_describe(e), canOpenInBrowser: e.code != 'object-not-found');
    } on FileSystemException {
      await _deletePartial(file);
      throw const EbookDownloadException(
        'The PDF could not be saved on this device. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }

    // Only report success when the whole file is really on the device.
    if (!await file.exists() || await file.length() == 0) {
      await _deletePartial(file);
      throw const EbookDownloadException('The download did not complete. Please try again.');
    }
    onProgress?.call(1);
    final name = file.uri.pathSegments.last;
    return SavedPdf(fileName: name, location: '$label/$name');
  }

  /// The folder to save in, and how to describe it to the user.
  (Directory, String) _downloadsFolder() {
    if (Platform.isAndroid) {
      return (Directory('/storage/emulated/0/Download/LibMate'), 'Download/LibMate');
    }
    final home = Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
    if (home == null || Platform.isIOS) {
      throw const EbookDownloadException(
        'Saving PDFs is not supported on this device. Use "Open in browser" instead.',
        canOpenInBrowser: true,
      );
    }
    final sep = Platform.pathSeparator;
    return (Directory('$home${sep}Downloads${sep}LibMate'), 'Downloads/LibMate');
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

  static String _describe(FirebaseException e) {
    return switch (e.code) {
      'object-not-found' => 'The PDF file for this e-book is missing. Please tell the library.',
      'unauthorized' || 'unauthenticated' => 'You do not have access to this PDF. Please sign in again.',
      'retry-limit-exceeded' || 'unknown' =>
        'Could not reach the server. Check your internet connection and try again.',
      'canceled' => 'The download was cancelled.',
      _ => 'The download failed (${e.code}). Please try again.',
    };
  }
}
