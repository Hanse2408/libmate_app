import 'package:flutter/foundation.dart';

import '../../../../models/book.dart';
import '../../../../repositories/book_repository.dart';

class BookProvider extends ChangeNotifier {
  BookProvider({BookRepository? bookRepository})
      : _bookRepository = bookRepository ?? BookRepository();

  final BookRepository _bookRepository;

  List<Book> _books = [];
  Book? _selectedBook;
  bool _isLoading = false;
  String? _error;

  List<Book> get books => _books;
  Book? get selectedBook => _selectedBook;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _bookRepository.getBooks();
    } catch (e) {
        _error = 'Failed to load books: $e';
        debugPrint('BOOK LOAD ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBook(String bookId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBook = await _bookRepository.getBook(bookId);
    } catch (e) {
      _error = 'Failed to load book.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}