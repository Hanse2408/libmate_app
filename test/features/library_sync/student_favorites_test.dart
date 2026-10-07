import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/book_reservation/screens/find_books_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/favorite_books_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/book_details_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/reserve_book_screen.dart';
import 'package:libmate_app/features/student/ebooks/screens/ebook_details_screen.dart';
import 'library_test_support.dart';

void main() {
  test('favourites persist per user, separate formats, and remove atomically', () async {
    final db = await seededFirestore();
    final first = studentRepo(db);
    final other = studentRepo(db, uid: otherStudentUid);
    addTearDown(first.dispose);
    addTearDown(other.dispose);
    await settle();
    expect((await first.setFavorite('same-id', favorite: true)).success, isTrue);
    expect((await first.setFavorite('same-id', favorite: true, ebook: true)).success, isTrue);
    await first.setFavorite('same-id', favorite: true);
    await settle();
    expect(first.isFavorite('same-id'), isTrue);
    expect(first.isFavorite('same-id', ebook: true), isTrue);
    expect(other.isFavorite('same-id'), isFalse);
    expect((await db.collection('users').doc(studentUid).get()).data()!['favoriteBookIds'], ['same-id']);
    final reopened = studentRepo(db);
    addTearDown(reopened.dispose);
    await settle();
    expect(reopened.isFavorite('same-id'), isTrue);
    await reopened.setFavorite('same-id', favorite: false);
    await settle();
    expect(first.isFavorite('same-id'), isFalse);
    expect(first.isFavorite('same-id', ebook: true), isTrue);
  });

  for (final dark in [false, true]) {
    testWidgets('favourite hearts, categories and reserve link (dark: $dark)', (tester) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await seededFirestore();
      await db.collection('books').doc('print').set({
        'title': 'Interface Design', 'author': 'Test Author', 'category': 'Programming',
        'totalCopies': 3, 'availableCopies': 3,
      });
      await db.collection('ebooks').doc('digital').set({
        'title': 'Digital Design', 'author': 'Digital Author', 'category': 'Programming',
        'status': 'published',
      });
      final library = studentRepo(db);
      addTearDown(library.dispose);
      Future<void> pump(Widget screen) async {
        await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light, home: screen));
        await tester.pumpAndSettle();
      }
      await pump(BookDetailsScreen(library: library, bookId: 'print'));
      await tester.tap(find.byTooltip('Add to favourites'));
      await tester.pumpAndSettle();
      expect(library.isFavorite('print'), isTrue);
      await pump(EbookDetailsScreen(library: library, ebookId: 'digital'));
      await tester.tap(find.byTooltip('Add to favourites'));
      await tester.pumpAndSettle();
      expect(library.isFavorite('digital', ebook: true), isTrue);
      await pump(FindBooksScreen(library: library));
      await tester.tap(find.byTooltip('My Favourites'));
      await tester.pumpAndSettle();
      expect(find.byType(FavoriteBooksScreen), findsOneWidget);
      expect(find.text('Interface Design'), findsOneWidget);
      expect(find.text('Digital Design'), findsOneWidget);
      final digitalChip = find.widgetWithText(ChoiceChip, 'eBooks');
      await tester.ensureVisible(digitalChip);
      await tester.tap(digitalChip);
      await tester.pumpAndSettle();
      expect(find.text('Interface Design'), findsNothing);
      expect(find.text('Digital Design'), findsOneWidget);
      await tester.tap(find.text('Read Online'));
      await tester.pumpAndSettle();
      expect(find.byType(EbookDetailsScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Remove from favourites'));
      await tester.pumpAndSettle();
      expect(library.isFavorite('digital', ebook: true), isFalse);
      Navigator.of(tester.element(find.byType(EbookDetailsScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Programming'));
      await tester.pumpAndSettle();
      expect(find.text('Interface Design'), findsOneWidget);
      await tester.tap(find.text('Reserve Book'));
      await tester.pumpAndSettle();
      expect(find.byType(ReserveBookScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}