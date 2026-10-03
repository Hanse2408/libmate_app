class Book {
  final String bookId;
  final String title;
  final String author;
  final String category;
  final String description;
  final String coverAsset;
  final String publisher;
  final int publishedYear;
  final int pages;
  final bool available;
  final String location;

  const Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.coverAsset,
    required this.publisher,
    required this.publishedYear,
    required this.pages,
    required this.available,
    required this.location,
  });
}