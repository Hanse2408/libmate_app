import 'package:cloud_firestore/cloud_firestore.dart';

enum BookStock {
  available('Available'),
  lowStock('Low Stock'),
  notAvailable('Not Available');

  const BookStock(this.label);
  final String label;
}

/// A book in the library catalogue, stored in Firestore at `books/{id}`.
///
/// Shared by the Librarian (who creates and edits books) and the Student
/// screens (which browse and reserve them).
class BookRecord {
  const BookRecord({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.language,
    required this.shelfLocation,
    required this.totalCopies,
    required this.availableCopies,
    this.description = '',
    this.coverAsset,
    this.publisher = '',
    this.publishedYear = 0,
    this.pages = 0,
  });

  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String language;
  final String shelfLocation;
  final int totalCopies;
  final int availableCopies;
  final String description;

  /// Cover image bundled with the app, e.g. "assets/images/books/book1.jpg"
  /// (the file lives in the project's assets/images/books/ folder). Null when
  /// the book has no cover; a cover is then generated from the title.
  final String? coverAsset;

  /// Optional details shown on the Student book screens ('' / 0 = unknown).
  final String publisher;
  final int publishedYear;
  final int pages;

  bool get isAvailable => availableCopies > 0;

  /// Copies currently reserved or borrowed by students.
  int get copiesOut => totalCopies - availableCopies;

  /// "Low Stock" when only one copy of a multi-copy book is left.
  BookStock get stock {
    if (availableCopies <= 0) return BookStock.notAvailable;
    if (availableCopies == 1 && totalCopies > 1) return BookStock.lowStock;
    return BookStock.available;
  }

  /// ISBNs are compared without hyphens or spaces (also stored as `isbnKey`
  /// so duplicates can be found with a Firestore query).
  static String isbnKeyOf(String isbn) =>
      isbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

  factory BookRecord.fromMap(String id, Map<String, dynamic> map) {
    return BookRecord(
      id: id,
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      isbn: map['isbn'] as String? ?? '',
      category: map['category'] as String? ?? '',
      language: map['language'] as String? ?? '',
      shelfLocation: map['shelfLocation'] as String? ?? '',
      totalCopies: (map['totalCopies'] as num?)?.toInt() ?? 0,
      availableCopies: (map['availableCopies'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      coverAsset: _nonEmpty(map['coverAsset']),
      publisher: map['publisher'] as String? ?? '',
      publishedYear: (map['publishedYear'] as num?)?.toInt() ?? 0,
      pages: (map['pages'] as num?)?.toInt() ?? 0,
    );
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  /// Fields written to Firestore (timestamps are added by the repository).
  ///
  /// `bookId`, `coverAsset`, `publisher`, `publishedYear`, `pages`,
  /// `available` and `location` are the fields the Student book service reads
  /// (and requires), so they are always written with a value of the right type.
  Map<String, dynamic> toMap() {
    return {
      'bookId': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'isbnKey': isbnKeyOf(isbn),
      'category': category,
      'language': language,
      'shelfLocation': shelfLocation,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'description': description,
      'coverAsset': coverAsset ?? '',
      'publisher': publisher,
      'publishedYear': publishedYear,
      'pages': pages,
      'available': isAvailable,
      'location': shelfLocation,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BookRecord copyWith({
    String? title,
    String? author,
    String? isbn,
    String? category,
    String? language,
    String? shelfLocation,
    int? totalCopies,
    int? availableCopies,
    String? description,
    String? coverAsset,
    String? publisher,
    int? publishedYear,
    int? pages,
    bool clearCover = false,
  }) {
    return BookRecord(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      category: category ?? this.category,
      language: language ?? this.language,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      description: description ?? this.description,
      coverAsset: clearCover ? null : coverAsset ?? this.coverAsset,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      pages: pages ?? this.pages,
    );
  }
}
