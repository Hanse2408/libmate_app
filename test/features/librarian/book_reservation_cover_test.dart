import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/librarian/widgets/book_cover.dart';
import 'package:libmate_app/features/librarian/widgets/book_summary_card.dart';

import '../library_sync/library_test_support.dart';
import 'librarian_test_helpers.dart';

/// Book Reservation Details shows the cover of the book the student
/// reserved (from that book's `coverAsset`), or the generated cover.
void main() {
  late FakeFirebaseFirestore db;
  late LibrarianFirestoreRepository librarian;

  setUp(() async {
    db = await seededFirestore();
    librarian = librarianRepo(db, FakeImageStorage());
  });
  // The Librarian shell disposes the repository it was given.

  /// Two books in the catalogue; the student reserves [title].
  Future<String> reserve(WidgetTester tester, String title) async {
    late String id;
    await tester.runAsync(() async {
      for (final (name, isbn, cover) in [
        ('Clean Code', '9780132350884', 'assets/images/books/book1.jpg'),
        ('Refactoring', '9780134757599', null),
      ]) {
        await librarian.addBook(
          title: name,
          author: 'Author',
          isbn: isbn,
          category: 'Software Engineering',
          language: 'English',
          shelfLocation: 'SE-1',
          totalCopies: 2,
          coverAsset: cover,
        );
      }
      await settle();
      final student = studentRepo(db);
      await settle();
      final result = await student.reserveBook(
        book: student.books.firstWhere((b) => b.title == title),
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      expect(result.success, isTrue, reason: result.message);
      await settle();
      student.dispose();
      id = librarian.reservations.single.id;
    });
    return id;
  }

  Future<void> openDetails(WidgetTester tester, String id) async {
    final router = await pumpLibrarian(
      tester,
      LibrarianRoutes.dashboard,
      size: const Size(800, 1600),
      createRepository: () => librarian,
    );
    await tester.runAsync(settle);
    router.go(LibrarianRoutes.reservationDetails(id));
    await tester.pumpAndSettle();
  }

  BookCover cover(WidgetTester tester) => tester.widget<BookCover>(
    find.descendant(
      of: find.byType(BookSummaryCard),
      matching: find.byType(BookCover),
    ),
  );

  testWidgets('shows the reserved book\'s own cover image', (tester) async {
    final id = await reserve(tester, 'Clean Code');
    await openDetails(tester, id);

    expect(find.text('Book Reservation Details'), findsOneWidget);
    expect(cover(tester).coverAsset, 'assets/images/books/book1.jpg');
    final image = tester.widget<Image>(
      find.descendant(of: find.byType(BookSummaryCard), matching: find.byType(Image)),
    );
    expect((image.image as AssetImage).assetName, 'assets/images/books/book1.jpg');
  });

  testWidgets('a book without a cover shows the generated cover', (tester) async {
    final id = await reserve(tester, 'Refactoring');
    await openDetails(tester, id);

    expect(cover(tester).coverAsset, isNull);
    expect(
      find.descendant(of: find.byType(BookSummaryCard), matching: find.byType(Image)),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byType(BookSummaryCard), matching: find.text('Refactoring')),
      findsWidgets,
    );
  });
}
