import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';

class BookService {
  BookService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _booksCollection =>
      _firestore.collection('books');

  Future<List<Book>> getBooks() async {
    final snapshot = await _booksCollection.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Book(
        bookId: data['bookId'] as String,
        title: data['title'] as String,
        author: data['author'] as String,
        category: data['category'] as String,
        description: data['description'] as String,
        coverAsset: data['coverAsset'] as String,
        publisher: data['publisher'] as String,
        publishedYear: data['publishedYear'] as int,
        pages: data['pages'] as int,
        available: data['available'] as bool,
        location: data['location'] as String,
      );
    }).toList();
  }

  Future<Book?> getBook(String bookId) async {
    final snapshot = await _booksCollection
        .where('bookId', isEqualTo: bookId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final data = snapshot.docs.first.data();

    return Book(
      bookId: data['bookId'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      category: data['category'] as String,
      description: data['description'] as String,
      coverAsset: data['coverAsset'] as String,
      publisher: data['publisher'] as String,
      publishedYear: data['publishedYear'] as int,
      pages: data['pages'] as int,
      available: data['available'] as bool,
      location: data['location'] as String,
    );
  }
}