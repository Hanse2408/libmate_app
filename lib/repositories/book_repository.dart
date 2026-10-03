import '../core/services/book_service.dart';
import '../models/book.dart';

class BookRepository {
  BookRepository({BookService? bookService})
      : _bookService = bookService ?? BookService();

  final BookService _bookService;

  Future<List<Book>> getBooks() {
    return _bookService.getBooks();
  }

  Future<Book?> getBook(String bookId) {
    return _bookService.getBook(bookId);
  }
}