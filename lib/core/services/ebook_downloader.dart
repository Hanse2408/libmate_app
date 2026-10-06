/// Picks the PDF downloader for the platform the app runs on:
/// - web: the browser saves the file (ebook_downloader_web.dart)
/// - Android / desktop: saved in the Downloads folder (ebook_downloader_io.dart)
library;

export 'ebook_downloader_io.dart' if (dart.library.js_interop) 'ebook_downloader_web.dart';
