import 'package:cloud_firestore/cloud_firestore.dart';

import 'book.dart';

enum EbookStatus {
  draft('Draft'),
  published('Published');

  const EbookStatus(this.label);
  final String label;
}

/// A digital book (e-book), stored in Firestore at `ebooks/{id}`, separate
/// from the printed catalogue in `books`.
///
/// It has the normal book details (same field names as `books`, so the
/// Student side can read both the same way later) plus a Cloudinary PDF
/// reference. The file itself is never stored in Firestore.
class EbookRecord {
  const EbookRecord({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.language,
    this.isbn = '',
    this.description = '',
    this.publisher = '',
    this.publishedYear = 0,
    this.pages = 0,
    this.location = defaultLocation,
    this.coverAsset,
    this.coverPublicId,
    this.pdfUrl,
    this.pdfPath,
    this.pdfPublicId,
    this.pdfResourceType,
    this.pdfFormat,
    this.pdfFileName,
    this.pdfSizeBytes = 0,
    this.status = EbookStatus.draft,
    this.updatedAt,
  });

  /// Where students find e-books (they have no shelf).
  static const String defaultLocation = 'E-Library';

  final String id;
  final String title;
  final String author;
  final String category;
  final String language;
  final String isbn;
  final String description;
  final String publisher;
  final int publishedYear;
  final int pages;
  final String location;

  /// Cover image: a Cloudinary HTTPS URL, or an older bundled asset path.
  final String? coverAsset;

  /// Cloudinary public ID of an uploaded cover (null for asset covers).
  final String? coverPublicId;

  /// HTTPS delivery URL of the PDF.
  final String? pdfUrl;

  /// Legacy Firebase Storage path, read for older documents only.
  final String? pdfPath;
  final String? pdfPublicId;
  final String? pdfResourceType;
  final String? pdfFormat;
  final String? pdfFileName;
  final int pdfSizeBytes;
  final EbookStatus status;
  final DateTime? updatedAt;

  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
  bool get isPublished => status == EbookStatus.published;

  factory EbookRecord.fromMap(String id, Map<String, dynamic> map) {
    String? nonEmpty(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return EbookRecord(
      id: id,
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      category: map['category'] as String? ?? '',
      language: map['language'] as String? ?? '',
      isbn: map['isbn'] as String? ?? '',
      description: map['description'] as String? ?? '',
      publisher: map['publisher'] as String? ?? '',
      publishedYear: (map['publishedYear'] as num?)?.toInt() ?? 0,
      pages: (map['pages'] as num?)?.toInt() ?? 0,
      location: map['location'] as String? ?? defaultLocation,
      coverAsset: nonEmpty(map['coverAsset']),
      coverPublicId: nonEmpty(map['coverPublicId']),
      pdfUrl: nonEmpty(map['pdfUrl']),
      pdfPath: nonEmpty(map['pdfPath']),
      pdfPublicId: nonEmpty(map['pdfPublicId']),
      pdfResourceType: nonEmpty(map['pdfResourceType']),
      pdfFormat: nonEmpty(map['pdfFormat']),
      pdfFileName: nonEmpty(map['pdfFileName']),
      pdfSizeBytes: (map['pdfSizeBytes'] as num?)?.toInt() ?? 0,
      status: map['status'] == EbookStatus.published.name
          ? EbookStatus.published
          : EbookStatus.draft,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields written to Firestore (`createdAt` is added when it is created).
  Map<String, dynamic> toMap() {
    return {
      'bookId': id,
      'title': title,
      'author': author,
      'category': category,
      'language': language,
      'isbn': isbn,
      'isbnKey': BookRecord.isbnKeyOf(isbn),
      'description': description,
      'publisher': publisher,
      'publishedYear': publishedYear,
      'pages': pages,
      'location': location,
      'coverAsset': coverAsset ?? '',
      'coverPublicId': coverPublicId ?? '',
      'pdfUrl': pdfUrl,
      'pdfPath': pdfPath,
      'pdfPublicId': pdfPublicId,
      'pdfResourceType': pdfResourceType,
      'pdfFormat': pdfFormat,
      'pdfFileName': pdfFileName,
      'pdfSizeBytes': pdfSizeBytes,
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  EbookRecord copyWith({
    String? coverAsset,
    String? coverPublicId,
    String? pdfUrl,
    String? pdfPath,
    String? pdfPublicId,
    String? pdfResourceType,
    String? pdfFormat,
    String? pdfFileName,
    int? pdfSizeBytes,
    EbookStatus? status,
    bool clearPdfPath = false,
  }) {
    return EbookRecord(
      id: id,
      title: title,
      author: author,
      category: category,
      language: language,
      isbn: isbn,
      description: description,
      publisher: publisher,
      publishedYear: publishedYear,
      pages: pages,
      location: location,
      coverAsset: coverAsset ?? this.coverAsset,
      coverPublicId: coverPublicId ?? this.coverPublicId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfPath: clearPdfPath ? null : pdfPath ?? this.pdfPath,
      pdfPublicId: pdfPublicId ?? this.pdfPublicId,
      pdfResourceType: pdfResourceType ?? this.pdfResourceType,
      pdfFormat: pdfFormat ?? this.pdfFormat,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      pdfSizeBytes: pdfSizeBytes ?? this.pdfSizeBytes,
      status: status ?? this.status,
      updatedAt: updatedAt,
    );
  }

  /// e.g. "2.4 MB"
  static String formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
