import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/core/services/ebook_service.dart';
import 'package:libmate_app/features/student/book_reservation/screens/find_books_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/ebooks/providers/student_ebook_provider.dart';
import 'package:libmate_app/features/student/ebooks/screens/ebook_details_screen.dart';
import 'package:libmate_app/features/student/ebooks/screens/ebooks_screen.dart';
import 'package:libmate_app/repositories/ebook_repository.dart';

import 'library_test_support.dart';

/// Pretends to save PDFs; can be held open or told to fail.
class _FakeDownloader implements EbookDownloader {
  final List<(String?, String, String)> calls = [];
  Completer<void>? gate;
  String? failWith;
  bool canOpenInBrowser = false;

  @override
  Future<SavedPdf> download({
    required String? storagePath,
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    calls.add((storagePath, url, fileName));
    onProgress?.call(0.5);
    if (gate != null) await gate!.future;
    if (failWith != null) {
      throw EbookDownloadException(failWith!, canOpenInBrowser: canOpenInBrowser);
    }
    onProgress?.call(1);
    return SavedPdf(fileName: fileName, location: 'Download/LibMate/$fileName');
  }
}

class _FakeLauncher extends PdfLauncher {
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}

/// An `ebooks` document as the Librarian side saves it.
Map<String, dynamic> _ebookDoc({
  required String id,
  String title = 'Clean Code',
  String author = 'Robert C. Martin',
  String category = 'Software Engineering',
  String status = 'published',
  bool withPdf = true,
}) {
  return {
    'bookId': id,
    'title': title,
    'author': author,
    'category': category,
    'language': 'English',
    'isbn': '9780132350884',
    'description': 'A handbook of agile software craftsmanship.',
    'publisher': 'Prentice Hall',
    'publishedYear': 2008,
    'pages': 464,
    'location': 'E-Library',
    'coverAsset': 'assets/images/books/book1.jpg',
    'pdfUrl': withPdf ? 'https://storage.test/ebooks/$id/1.pdf' : null,
    'pdfPath': withPdf ? 'ebooks/$id/1.pdf' : null,
    'pdfFileName': withPdf ? 'clean-code.pdf' : null,
    'pdfSizeBytes': withPdf ? 2457600 : 0,
    'status': status,
  };
}

void main() {
  late FakeFirebaseFirestore db;
  late _FakeDownloader downloader;

  setUp(() async {
    db = await seededFirestore();
    downloader = _FakeDownloader();
  });

  StudentEbookProvider newProvider() => StudentEbookProvider(
    EbookRepository(
      service: EbookService(firestore: db, files: _NoFiles()),
      downloader: downloader,
    ),
  );

  StudentLibraryRepository newLibrary() => StudentLibraryRepository(
    firestore: db,
    student: const StudentIdentity(
      uid: studentUid,
      studentId: 'IT23004512',
      name: 'Nethmi Perera',
      email: 'nethmi@student.test',
    ),
    createEbooks: newProvider,
  );

  group('provider / repository', () {
    test('no e-books yet: empty list, no error', () async {
      final provider = newProvider();
      await settle();
      expect(provider.isLoading, isFalse);
      expect(provider.loadError, isNull);
      expect(provider.ebooks, isEmpty);
      provider.dispose();
    });

    test('maps published e-books from `ebooks`; drafts are not shown', () async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      await db.collection('ebooks').doc('E2').set(_ebookDoc(id: 'E2', title: 'Draft Book', status: 'draft'));
      final provider = newProvider();
      await settle();

      final ebook = provider.ebooks.single;
      expect(ebook.title, 'Clean Code');
      expect(ebook.author, 'Robert C. Martin');
      expect(ebook.coverAsset, 'assets/images/books/book1.jpg');
      expect(ebook.publishedYear, 2008);
      expect(ebook.hasPdf, isTrue);
      expect(ebook.pdfPath, 'ebooks/E1/1.pdf');
      // Physical books are a different collection.
      expect((await db.collection('books').get()).docs, isEmpty);
      provider.dispose();
    });

    test('an e-book the librarian publishes appears live', () async {
      final provider = newProvider();
      await settle();
      expect(provider.ebooks, isEmpty);

      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1', status: 'draft'));
      await settle();
      expect(provider.ebooks, isEmpty); // still a draft
      await db.collection('ebooks').doc('E1').update({'status': 'published'});
      await settle();
      expect(provider.ebooks.single.id, 'E1');
      provider.dispose();
    });

    test('search by title, author or category', () async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      await db.collection('ebooks').doc('E2').set(
        _ebookDoc(id: 'E2', title: 'Madolduwa', author: 'Martin Wickramasinghe', category: 'Fiction'),
      );
      final provider = newProvider();
      await settle();
      provider.search('madol');
      expect(provider.visibleEbooks.single.id, 'E2');
      provider.search('robert');
      expect(provider.visibleEbooks.single.id, 'E1');
      provider.search('fiction');
      expect(provider.visibleEbooks.single.id, 'E2');
      provider.dispose();
    });

    test('download saves the PDF using its Storage path; one at a time', () async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      final provider = newProvider();
      await settle();
      final ebook = provider.ebooks.single;

      downloader.gate = Completer<void>();
      final first = provider.download(ebook);
      expect(provider.downloadingId, 'E1');
      final second = await provider.download(ebook);
      expect(second.success, isFalse);
      expect(second.message, contains('already in progress'));

      downloader.gate!.complete();
      final result = await first;
      expect(result.success, isTrue);
      expect(result.saved!.location, 'Download/LibMate/Clean Code.pdf');
      expect(downloader.calls.single, ('ebooks/E1/1.pdf', 'https://storage.test/ebooks/E1/1.pdf', 'Clean Code.pdf'));
      expect(provider.downloadingId, isNull);
      provider.dispose();
    });

    test('a failed download is reported, not shown as success', () async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      final provider = newProvider();
      await settle();
      downloader
        ..failWith = 'Could not reach the server.'
        ..canOpenInBrowser = true;

      final result = await provider.download(provider.ebooks.single);
      expect(result.success, isFalse);
      expect(result.message, 'Could not reach the server.');
      expect(result.canOpenInBrowser, isTrue);
      expect(provider.downloadingId, isNull);
      provider.dispose();
    });

    test('an e-book without a PDF is not downloaded', () async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1', withPdf: false));
      final provider = newProvider();
      await settle();
      final result = await provider.download(provider.ebooks.single);
      expect(result.success, isFalse);
      expect(result.message, contains('No PDF'));
      expect(downloader.calls, isEmpty);
      provider.dispose();
    });
  });

  group('screens', () {
    late _FakeLauncher launcher;

    setUp(() {
      launcher = _FakeLauncher();
      PdfLauncher.instance = launcher;
    });

    tearDown(() => PdfLauncher.instance = const PdfLauncher());

    Future<StudentLibraryRepository> pump(WidgetTester tester, Widget Function(StudentLibraryRepository) screen) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final library = newLibrary();
      addTearDown(library.dispose);
      await tester.pumpWidget(MaterialApp(home: screen(library)));
      await tester.pumpAndSettle();
      return library;
    }

    testWidgets('Find Books has an eBooks category that opens the empty E-books page', (tester) async {
      final book = librarianRepo(db, FakeImageStorage());
      addTearDown(book.dispose);
      await tester.runAsync(() async {
        await book.addBook(
          title: 'Refactoring',
          author: 'Martin Fowler',
          isbn: '9780134757599',
          category: 'Software Engineering',
          language: 'English',
          shelfLocation: 'SE-1',
          totalCopies: 2,
        );
      });
      await pump(tester, (library) => FindBooksScreen(library: library));

      // Physical books still work as before.
      expect(find.text('Refactoring'), findsWidgets);
      expect(find.text('Software Engineering'), findsWidgets);

      // "eBooks" is the last chip in the horizontally scrolling category bar.
      final chipBar = find
          .descendant(
            of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(find.text('eBooks'), 150, scrollable: chipBar);
      await tester.tap(find.text('eBooks'));
      await tester.pumpAndSettle();
      expect(find.text('E-books'), findsOneWidget);
      expect(find.text('Your library, wherever you are.'), findsOneWidget);
      expect(find.text('No e-books available yet'), findsOneWidget);
      expect(find.text('E-books added by the library will appear here.'), findsOneWidget);

      // Back on Find Books, the physical list is unchanged.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Refactoring'), findsWidgets);
    });

    testWidgets('list -> details -> Download PDF completes with a message', (tester) async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      await pump(tester, (library) => EbooksScreen(library: library));
      expect(find.text('1 e-book'), findsOneWidget);
      expect(find.text('PDF · 2.3 MB'), findsOneWidget);

      await tester.tap(find.text('Clean Code'));
      await tester.pumpAndSettle();
      expect(find.text('E-book Details'), findsOneWidget);
      expect(find.text('by Robert C. Martin'), findsOneWidget);
      expect(find.text('Prentice Hall'), findsOneWidget);
      expect(find.text('2008'), findsOneWidget);
      expect(find.text('464'), findsOneWidget);
      expect(find.text('clean-code.pdf · 2.3 MB'), findsOneWidget);

      downloader.gate = Completer<void>();
      await tester.ensureVisible(find.text('Download PDF'));
      await tester.tap(find.text('Download PDF'));
      await tester.pump();
      expect(find.text('Downloading… 50%'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull); // no second download while running
      expect(find.textContaining('Download complete'), findsNothing);

      downloader.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Download complete: Download/LibMate/Clean Code.pdf'), findsOneWidget);
      expect(find.text('Saved to Download/LibMate/Clean Code.pdf'), findsOneWidget);
      expect(downloader.calls, hasLength(1));
    });

    testWidgets('a missing PDF disables the download and explains why', (tester) async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1', withPdf: false));
      await pump(tester, (library) => EbookDetailsScreen(library: library, ebookId: 'E1'));
      expect(
        find.text('The PDF for this e-book is not available yet. Please check again later.'),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('PDF not available'), findsOneWidget);
    });

    testWidgets('a failed download shows the reason and offers Open in browser', (tester) async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      downloader
        ..failWith = 'This device does not allow LibMate to save into Downloads.'
        ..canOpenInBrowser = true;
      await pump(tester, (library) => EbookDetailsScreen(library: library, ebookId: 'E1'));

      await tester.ensureVisible(find.text('Download PDF'));
      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Download complete'), findsNothing);
      expect(find.byKey(const ValueKey('ebook-download-result')), findsOneWidget);
      await tester.ensureVisible(find.text('Open in browser'));
      await tester.tap(find.text('Open in browser'));
      await tester.pumpAndSettle();
      expect(launcher.opened.single, 'https://storage.test/ebooks/E1/1.pdf');
    });

    testWidgets('a removed e-book shows a message instead of details', (tester) async {
      await pump(tester, (library) => EbookDetailsScreen(library: library, ebookId: 'missing'));
      expect(find.text('This e-book is no longer available.'), findsOneWidget);
    });

    testWidgets('search text from Find Books carries over', (tester) async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      await db.collection('ebooks').doc('E2').set(_ebookDoc(id: 'E2', title: 'Madolduwa', category: 'Fiction'));
      await pump(tester, (library) => EbooksScreen(library: library, initialQuery: 'madol'));
      expect(find.text('Madolduwa'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing);
    });
  });
}

/// Students never upload; this store must not be used.
class _NoFiles implements EbookFileStorage {
  @override
  Future<String> upload(String path, PdfFile pdf, {void Function(double progress)? onProgress}) =>
      throw StateError('students cannot upload');

  @override
  Future<void> delete(String path) => throw StateError('students cannot delete');
}
