import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/librarian/widgets/book_cover_asset_field.dart';
import 'package:libmate_app/models/action_result.dart';

import '../librarian/librarian_test_helpers.dart';
import 'library_test_support.dart';

/// Add New Book save flow: validation -> cover chosen from
/// assets/images/books/ -> `books` document (Firestore) -> feedback.

const _cover = 'assets/images/books/book_new_01.jpg';

/// Firestore whose batch commits fail (rules refusal) or never finish
/// (offline: Firestore keeps the write queued).
class _BrokenBatchFirestore extends FakeFirebaseFirestore {
  _BrokenBatchFirestore({this.hang = false});
  final bool hang;

  @override
  WriteBatch batch() => _BrokenBatch(super.batch(), hang: hang);
}

class _BrokenBatch implements WriteBatch {
  _BrokenBatch(this._inner, {required this.hang});
  final WriteBatch _inner;
  final bool hang;

  @override
  Future<void> commit() {
    if (hang) return Completer<void>().future;
    return Future.error(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
  }

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) =>
      _inner.set(document, data, options);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _addUsersTo(FakeFirebaseFirestore db) async {
  final seeded = await seededFirestore();
  for (final doc in (await seeded.collection('users').get()).docs) {
    await db.collection('users').doc(doc.id).set(doc.data());
  }
}

/// The text field under the given uppercase form label.
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await scrollTo(tester, find.text(label));
  await scrollTo(tester, _field(label));
  await tester.enterText(_field(label), text);
  await tester.pump();
}

Future<void> _fillForm(WidgetTester tester) async {
  await _type(tester, 'BOOK TITLE', 'Refactoring');
  await _type(tester, 'AUTHOR', 'Martin Fowler');
  await _type(tester, 'ISBN', '9780134757599');
  await _type(tester, 'CATEGORY', 'Software Engineering');
  await _type(tester, 'TOTAL COPIES', '3');
  await _type(tester, 'SHELF-LOCATION', 'SE-02-A');
}

void main() {
  late FakeImageStorage storage;
  setUp(() => storage = FakeImageStorage());

  Future<ActionResult> addRefactoring(LibrarianFirestoreRepository repo) {
    return repo.addBook(
      title: 'Refactoring',
      author: 'Martin Fowler',
      isbn: '9780134757599',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'SE-02-A',
      totalCopies: 3,
      coverAsset: _cover,
    );
  }

  group('repository', () {
    test('success: the books document exists with coverAsset', () async {
      final db = await seededFirestore();
      final repo = librarianRepo(db, storage);
      final result = await addRefactoring(repo);
      repo.dispose();

      expect(result.success, isTrue, reason: result.message);
      final doc = (await db.collection('books').get()).docs.single.data();
      expect(doc['coverAsset'], _cover);
      expect(storage.files, isEmpty); // no Firebase Storage upload
    });

    test('Firestore refuses the write: the reason is returned, nothing saved', () async {
      final db = _BrokenBatchFirestore();
      await _addUsersTo(db);
      final repo = librarianRepo(db, storage);
      final result = await addRefactoring(repo);
      repo.dispose();

      expect(result.success, isFalse);
      expect(result.message, contains('do not have permission'));
      expect((await db.collection('books').get()).docs, isEmpty);
    });

    test('Firestore never confirms (offline): not reported as saved', () async {
      final db = _BrokenBatchFirestore(hang: true);
      await _addUsersTo(db);
      final repo = librarianRepo(db, storage, writeTimeout: const Duration(milliseconds: 50));
      final result = await addRefactoring(repo);
      repo.dispose();

      expect(result.success, isFalse);
      expect(result.message, contains('did not confirm'));
    });
  });

  group('Add Book form', () {
    final realList = BookCoverAssets.list;
    setUp(() => BookCoverAssets.list = () async => [_cover]);
    tearDown(() => BookCoverAssets.list = realList);

    Future<void> chooseCoverAndSave(WidgetTester tester) async {
      await _fillForm(tester);
      await tapVisible(tester, find.text('Choose Cover'));
      await tester.tap(find.text('book_new_01.jpg'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Save Book'));
      await tester.tap(find.text('Save Book'));
      await tester.pump();
    }

    testWidgets('loading stops and the error shows when the write is refused', (tester) async {
      final db = _BrokenBatchFirestore();
      await _addUsersTo(db);
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.addBook,
        size: const Size(400, 1600),
        createRepository: () => librarianRepo(db, storage),
      );

      await chooseCoverAndSave(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('do not have permission'), findsOneWidget);
      expect(find.textContaining('added to the catalogue'), findsNothing);
      final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save Book'));
      expect(save.onPressed, isNotNull); // spinner gone, can try again
      expect(router.currentPath, LibrarianRoutes.addBook);
    });

    testWidgets('loading stops when Firestore never confirms the write', (tester) async {
      final db = _BrokenBatchFirestore(hang: true);
      await _addUsersTo(db);
      await pumpLibrarian(
        tester,
        LibrarianRoutes.addBook,
        size: const Size(400, 1600),
        createRepository: () =>
            librarianRepo(db, storage, writeTimeout: const Duration(seconds: 5)),
      );

      await chooseCoverAndSave(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // saving
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(find.textContaining('did not confirm'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('success message only after the book document is saved', (tester) async {
      final db = await seededFirestore();
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.addBook,
        size: const Size(400, 1600),
        createRepository: () => librarianRepo(db, storage),
      );

      await chooseCoverAndSave(tester);
      await tester.pumpAndSettle();

      expect(router.currentPath, LibrarianRoutes.books);
      expect(find.text('"Refactoring" added to the catalogue.'), findsOneWidget);
      final doc = (await db.collection('books').get()).docs.single.data();
      expect(doc['coverAsset'], _cover);
    });

    testWidgets('the picker explains how to add a cover when the folder is empty', (
      tester,
    ) async {
      BookCoverAssets.list = () async => [];
      await pumpLibrarian(tester, LibrarianRoutes.addBook, size: const Size(400, 1600));
      await tapVisible(tester, find.text('Choose Cover'));
      expect(find.textContaining('No cover images found in assets/images/books/'), findsOneWidget);
    });
  });
}
