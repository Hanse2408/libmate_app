import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/widgets/book_list_tile.dart';

import 'librarian_test_helpers.dart';

/// The text field under the given uppercase form label.
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await scrollTo(tester, find.text(label)); // make sure the field is built
  await scrollTo(tester, _field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Book Management lists the catalogue', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.books);
    expect(find.text('Book Management'), findsOneWidget);
    expect(find.byType(BookListTile), findsWidgets);
    // Title appears on the card and on its generated cover.
    expect(find.text('Clean Code'), findsWidgets);
  });

  testWidgets('Search and availability filter', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.books);

    await tester.enterText(find.byType(TextField).first, 'madol');
    await tester.pumpAndSettle();
    expect(find.byType(BookListTile), findsOneWidget);
    expect(find.text('Madol Doova'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Availability: All'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<int>, 'Not Available'));
    await tester.pumpAndSettle();
    expect(find.byType(BookListTile, skipOffstage: false), findsNWidgets(3));
  });

  testWidgets('Add Book validates the form', (tester) async {
    await pumpLibrarian(tester, LibrarianRoutes.addBook);

    await tapVisible(tester, find.text('Save Book'));
    expect(find.text('Book title is required'), findsOneWidget);
    expect(find.text('Author is required'), findsOneWidget);

    await _type(tester, 'ISBN', '123');
    expect(find.text('ISBN must have 10 or 13 digits'), findsOneWidget);

    await _type(tester, 'ISBN', '978-0132350884');
    expect(find.text('A book with this ISBN already exists'), findsOneWidget);

    await _type(tester, 'TOTAL COPIES', '0');
    expect(find.text('Total copies must be at least 1'), findsOneWidget);
    expect(repositoryOf(tester).books.length, 9);
  });

  testWidgets('Saving a valid book adds it to Book Management', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.addBook);

    await _type(tester, 'BOOK TITLE', 'Refactoring');
    await _type(tester, 'AUTHOR', 'Martin Fowler');
    await _type(tester, 'ISBN', '9780134757599');
    await _type(tester, 'CATEGORY', 'Software Engineering');
    await _type(tester, 'TOTAL COPIES', '3');
    await _type(tester, 'SHELF-LOCATION', 'SE-02-A');
    await tapVisible(tester, find.text('Save Book'));

    expect(router.currentPath, LibrarianRoutes.books);
    expect(find.text('"Refactoring" added to the catalogue.'), findsOneWidget);
    expect(find.text('Refactoring'), findsWidgets);
    expect(repositoryOf(tester).books.first.title, 'Refactoring');
  });

  testWidgets('Edit opens the form pre-filled and saves changes', (tester) async {
    final router = await pumpLibrarian(tester, LibrarianRoutes.books);

    await tapVisible(tester, find.widgetWithText(TextButton, 'Edit').first);
    expect(router.currentPath, LibrarianRoutes.editBook('B001'));
    expect(find.text('Edit Book'), findsOneWidget);
    final titleField = tester.widget<TextFormField>(_field('BOOK TITLE'));
    expect(titleField.controller!.text, 'Clean Code');

    await _type(tester, 'TOTAL COPIES', '6');
    await tapVisible(tester, find.text('Save Changes'));

    expect(router.currentPath, LibrarianRoutes.books);
    expect(find.text('"Clean Code" was updated.'), findsOneWidget);
    expect(repositoryOf(tester).bookById('B001')!.totalCopies, 6);
  });
}
