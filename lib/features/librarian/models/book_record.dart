enum BookStock {
  available('Available'),
  lowStock('Low Stock'),
  notAvailable('Not Available');

  const BookStock(this.label);
  final String label;
}

/// A book in the library catalogue, as the Librarian sees it.
/// Local model used with mock data until the shared Book model is integrated.
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

  bool get isAvailable => availableCopies > 0;

  /// Copies currently reserved or borrowed by students.
  int get copiesOut => totalCopies - availableCopies;

  /// "Low Stock" when only one copy of a multi-copy book is left.
  BookStock get stock {
    if (availableCopies <= 0) return BookStock.notAvailable;
    if (availableCopies == 1 && totalCopies > 1) return BookStock.lowStock;
    return BookStock.available;
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
    );
  }
}
