import '../models/book_record.dart';

/// Search text + filters chosen on the Book Management screen.
/// A null [stock], [category] or [author] means "All".
class BookFilter {
  const BookFilter({this.query = '', this.stock, this.category, this.author});

  final String query;
  final BookStock? stock;
  final String? category;
  final String? author;

  List<BookRecord> apply(List<BookRecord> books) {
    final text = query.trim().toLowerCase();
    final isbnText = text.replaceAll('-', '');

    return books.where((book) {
      if (stock != null && book.stock != stock) return false;
      if (category != null && book.category != category) return false;
      if (author != null && book.author != author) return false;
      if (text.isEmpty) return true;
      return book.title.toLowerCase().contains(text) ||
          book.author.toLowerCase().contains(text) ||
          book.category.toLowerCase().contains(text) ||
          (isbnText.isNotEmpty && book.isbn.replaceAll('-', '').contains(isbnText));
    }).toList();
  }

  /// Distinct, sorted values for the Category / Author filter menus.
  static List<String> categoriesOf(List<BookRecord> books) =>
      (books.map((b) => b.category).toSet().toList()..sort());

  static List<String> authorsOf(List<BookRecord> books) =>
      (books.map((b) => b.author).toSet().toList()..sort());
}
