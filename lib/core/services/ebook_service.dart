import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/book.dart';
import '../../models/ebook.dart';
import '../constants/cloudinary_config.dart';
import '../constants/firestore_collections.dart';
import 'cloudinary_upload_service.dart';
import 'image_storage_service.dart';

/// A PDF the librarian selected, ready to upload to Cloudinary.
class PdfFile {
  const PdfFile({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  int get sizeBytes => bytes.length;

  static const int maxBytes = 25 * 1024 * 1024; // 25 MB (as in the design)

  /// Builds a PdfFile, or returns why the file is refused.
  static (PdfFile?, String?) validate({
    required Uint8List bytes,
    required String fileName,
  }) {
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      return (null, 'Please choose a PDF file (.pdf).');
    }
    if (bytes.isEmpty) return (null, 'The selected PDF is empty.');
    if (bytes.length > maxBytes) {
      return (
        null,
        'The PDF is larger than 25 MB. Please choose a smaller file.',
      );
    }
    // Real PDFs start with "%PDF"; a renamed image or document does not.
    const signature = [0x25, 0x50, 0x44, 0x46];
    for (var i = 0; i < signature.length; i++) {
      if (bytes.length <= i || bytes[i] != signature[i]) {
        return (null, 'This file is not a valid PDF.');
      }
    }
    return (PdfFile(bytes: bytes, fileName: fileName), null);
  }
}

/// Opens the system file chooser for a PDF. Replaceable in widget tests.
class PdfPickerService {
  const PdfPickerService();

  static PdfPickerService instance = const PdfPickerService();

  /// The chosen PDF, `(null, null)` if cancelled, or `(null, reason)`.
  Future<(PdfFile?, String?)> pickPdf() async {
    const pdfs = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
      uniformTypeIdentifiers: ['com.adobe.pdf'],
      webWildCards: ['application/pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [pdfs]);
    if (file == null) return (null, null);
    return PdfFile.validate(
      bytes: await file.readAsBytes(),
      fileName: file.name,
    );
  }
}

/// Opens a PDF link in the device's PDF viewer / browser. Replaceable in tests.
class PdfLauncher {
  const PdfLauncher();

  static PdfLauncher instance = const PdfLauncher();

  Future<bool> open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Where a downloaded PDF was saved, e.g. "Download/LibMate/Clean Code.pdf".
class SavedPdf {
  const SavedPdf({required this.fileName, required this.location});

  final String fileName;

  /// Human-readable place the file was saved to.
  final String location;
}

/// A download that did not finish; [message] is shown to the user.
/// [canOpenInBrowser] means the PDF can still be opened via its link.
class EbookDownloadException implements Exception {
  const EbookDownloadException(this.message, {this.canOpenInBrowser = false});

  final String message;
  final bool canOpenInBrowser;

  @override
  String toString() => message;
}

/// Downloads an e-book PDF from its HTTPS URL and saves it on the device.
/// Each platform has its own implementation (see createEbookDownloader).
abstract class EbookDownloader {
  /// Downloads [url] as [fileName]. Completes only when the file is fully
  /// saved; throws EbookDownloadException otherwise.
  /// [onProgress] gets 0.0–1.0 where the platform reports progress.
  Future<SavedPdf> download({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  });
}

/// Stores e-book PDFs. An interface so tests can use a fake.
abstract class EbookFileStorage {
  /// Uploads [pdf] and returns the Cloudinary asset metadata.
  Future<CloudMediaAsset> upload(
    PdfFile pdf, {
    void Function(double progress)? onProgress,
  });
}

class CloudinaryEbookFileStorage implements EbookFileStorage {
  CloudinaryEbookFileStorage({CloudinaryUploadClient? uploader})
    : _uploader = uploader ?? CloudinaryUploadClient();

  final CloudinaryUploadClient _uploader;

  @override
  Future<CloudMediaAsset> upload(
    PdfFile pdf, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      return await _uploader.upload(
        bytes: pdf.bytes,
        fileName: pdf.fileName,
        uploadPreset: CloudinaryConfig.pdfUploadPreset,
        onProgress: onProgress,
      );
    } on CloudinaryUploadException catch (e) {
      throw ImageStorageException(e.message);
    }
  }
}

/// All Firestore calls for e-books. No widget talks to Firebase directly.
class EbookService {
  EbookService({
    required FirebaseFirestore firestore,
    required this._files,
    ImageStorage? images,
  }) : _db = firestore,
       _images = images;

  final FirebaseFirestore _db;
  final EbookFileStorage _files;

  /// Cover images (Cloudinary image preset); null where covers cannot upload.
  final ImageStorage? _images;

  CollectionReference<Map<String, dynamic>> get _ebooks =>
      _db.collection(FirestoreCollections.ebooks);

  /// Live list of all e-books (drafts and published).
  Stream<List<EbookRecord>> watchEbooks() {
    return _ebooks.snapshots().map(
      (snapshot) => [
        for (final d in snapshot.docs) EbookRecord.fromMap(d.id, d.data()),
      ],
    );
  }

  /// Live list of published e-books only (what students may read; the
  /// security rules refuse drafts to students, so the query must match).
  Stream<List<EbookRecord>> watchPublishedEbooks() {
    return _ebooks
        .where('status', isEqualTo: EbookStatus.published.name)
        .snapshots()
        .map(
          (snapshot) => [
            for (final d in snapshot.docs) EbookRecord.fromMap(d.id, d.data()),
          ],
        );
  }

  /// A new document id (nothing is written yet).
  String newId() => _ebooks.doc().id;

  /// True if another e-book already has this ISBN.
  Future<bool> isbnInUse(String isbn, {String? exceptId}) async {
    final key = BookRecord.isbnKeyOf(isbn);
    if (key.isEmpty) return false;
    final same = await _ebooks.where('isbnKey', isEqualTo: key).get();
    return same.docs.any((d) => d.id != exceptId);
  }

  Future<CloudMediaAsset> uploadPdf(
    PdfFile pdf, {
    void Function(double)? onProgress,
  }) => _files.upload(pdf, onProgress: onProgress);

  Future<CloudMediaAsset> uploadCover(
    ImageUpload image, {
    void Function(double)? onProgress,
  }) {
    final images = _images;
    if (images == null) {
      throw const ImageStorageException('Cover uploads are not available.');
    }
    return images.upload(image, onProgress: onProgress);
  }

  Future<void> create(EbookRecord ebook, {required String createdBy}) {
    return _ebooks.doc(ebook.id).set({
      ...ebook.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    });
  }

  /// Updates an existing e-book (fails if it was deleted meanwhile).
  Future<void> update(EbookRecord ebook) =>
      _ebooks.doc(ebook.id).update(ebook.toMap());

  Future<void> delete(String id) => _ebooks.doc(id).delete();

  /// Reads one e-book from the server (used to confirm a save).
  Future<EbookRecord?> fetchFromServer(String id) async {
    final snapshot = await _ebooks
        .doc(id)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    return data == null ? null : EbookRecord.fromMap(id, data);
  }
}
