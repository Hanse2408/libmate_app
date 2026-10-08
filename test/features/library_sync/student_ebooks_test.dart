import 'dart:async';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/core/services/ebook_service.dart';
import 'package:libmate_app/core/services/cloudinary_upload_service.dart';
import 'package:libmate_app/features/student/book_reservation/screens/find_books_screen.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/ebooks/providers/student_ebook_provider.dart';
import 'package:libmate_app/features/student/ebooks/screens/ebook_details_screen.dart';
import 'package:libmate_app/features/student/ebooks/screens/ebook_reader_screen.dart';
import 'package:libmate_app/features/student/ebooks/screens/ebooks_screen.dart';
import 'package:libmate_app/repositories/ebook_repository.dart';

import 'library_test_support.dart';

/// Pretends to save PDFs; can be held open or told to fail.
class _FakeDownloader implements EbookDownloader {
  final List<(String, String)> calls = [];
  Completer<void>? gate;
  String? failWith;
  bool canOpenInBrowser = false;

  @override
  Future<SavedPdf> download({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    calls.add((url, fileName));
    onProgress?.call(0.5);
    if (gate != null) await gate!.future;
    if (failWith != null) {
      throw EbookDownloadException(
        failWith!,
        canOpenInBrowser: canOpenInBrowser,
      );
    }
    onProgress?.call(1);
    return SavedPdf(fileName: fileName, location: 'Download/LibMate/$fileName');
  }
}

/// The start of a real PDF file (what Cloudinary returns for a PDF).
final _pdfBytes = Uint8List.fromList('%PDF-1.4\n%test\n'.codeUnits);

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

  /// URLs the reader fetched, and how the "file host" answers.
  final requested = <Uri>[];
  late http.Response Function(Uri url) host;
  setUp(() {
    requested.clear();
    host = (_) => http.Response.bytes(_pdfBytes, 200);
  });

  StudentEbookProvider newProvider() => StudentEbookProvider(
    EbookRepository(
      service: EbookService(firestore: db, files: _NoFiles()),
      downloader: downloader,
      pdfLoader: EbookPdfLoader(
        client: MockClient((request) async {
          requested.add(request.url);
          return host(request.url);
        }),
      ),
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
    test(
      'category filters combine with search and recover after deletion',
      () async {
        await db
            .collection('ebooks')
            .doc('E1')
            .set(_ebookDoc(id: 'E1', category: 'Computing'));
        await db
            .collection('ebooks')
            .doc('E2')
            .set(
              _ebookDoc(id: 'E2', title: 'History Book', category: 'History'),
            );
        final provider = newProvider();
        addTearDown(provider.dispose);
        await settle();
        expect(provider.categories, ['Computing', 'History']);
        provider.selectCategory('History');
        expect(provider.visibleEbooks.single.id, 'E2');
        provider.search('Clean');
        expect(provider.visibleEbooks, isEmpty);
        provider.selectCategory(null);
        expect(provider.visibleEbooks.single.id, 'E1');
        provider.search('');
        provider.selectCategory('History');
        await db.collection('ebooks').doc('E2').delete();
        await settle();
        expect(provider.selectedCategory, isNull);
        expect(provider.visibleEbooks.single.id, 'E1');
      },
    );
    test('no e-books yet: empty list, no error', () async {
      final provider = newProvider();
      await settle();
      expect(provider.isLoading, isFalse);
      expect(provider.loadError, isNull);
      expect(provider.ebooks, isEmpty);
      provider.dispose();
    });

    test(
      'maps published e-books from `ebooks`; drafts are not shown',
      () async {
        await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
        await db
            .collection('ebooks')
            .doc('E2')
            .set(_ebookDoc(id: 'E2', title: 'Draft Book', status: 'draft'));
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
      },
    );

    test('an e-book the librarian publishes appears live', () async {
      final provider = newProvider();
      await settle();
      expect(provider.ebooks, isEmpty);

      await db
          .collection('ebooks')
          .doc('E1')
          .set(_ebookDoc(id: 'E1', status: 'draft'));
      await settle();
      expect(provider.ebooks, isEmpty); // still a draft
      await db.collection('ebooks').doc('E1').update({'status': 'published'});
      await settle();
      expect(provider.ebooks.single.id, 'E1');
      provider.dispose();
    });

    test('search by title, author or category', () async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      await db
          .collection('ebooks')
          .doc('E2')
          .set(
            _ebookDoc(
              id: 'E2',
              title: 'Madolduwa',
              author: 'Martin Wickramasinghe',
              category: 'Fiction',
            ),
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

    test(
      'Read Online uses the saved Cloudinary pdfUrl, nothing else',
      () async {
        await db.collection('ebooks').doc('E1').set({
          ..._ebookDoc(id: 'E1'),
          'pdfUrl': 'https://res.cloudinary.com/demo/image/upload/v1/libmate/ebooks/clean.pdf',
        });
        await db
            .collection('ebooks')
            .doc('E2')
            .set(_ebookDoc(id: 'E2', withPdf: false));
        await db.collection('ebooks').doc('E3').set({
          ..._ebookDoc(id: 'E3'),
          'pdfUrl': 'ebooks/E3/1.pdf',
        });
        final provider = newProvider();
        await settle();

        expect(
          provider.readOnlineUri(provider.ebookById('E1')!).toString(),
          'https://res.cloudinary.com/demo/image/upload/v1/libmate/ebooks/clean.pdf',
        );
        expect(
          provider.readOnlineUri(provider.ebookById('E2')!),
          isNull,
        ); // no PDF
        expect(
          provider.readOnlineUri(provider.ebookById('E3')!),
          isNull,
        ); // not a web link
        expect(downloader.calls, isEmpty); // reading never downloads a file
        provider.dispose();
      },
    );

    group('PDF loader', () {
      final url = Uri.parse(
        'https://res.cloudinary.com/demo/image/upload/v1/clean.pdf',
      );
      EbookPdfLoader loader(http.Response response) =>
          EbookPdfLoader(client: MockClient((_) async => response));

      test('returns the PDF bytes, with progress', () async {
        final progress = <int>[];
        final bytes = await loader(
          http.Response.bytes(
            _pdfBytes,
            200,
            headers: {'content-length': '${_pdfBytes.length}'},
          ),
        ).load(url, onProgress: (received, _) => progress.add(received));
        expect(bytes, _pdfBytes);
        expect(progress.last, _pdfBytes.length);
      });

      test('Cloudinary refusing PDF delivery is reported as such', () async {
        final error = await loader(
          http.Response(
            '{}',
            401,
            headers: {'x-cld-error': 'deny or ACL failure'},
          ),
        ).load(url).then<Object?>((_) => null, onError: (Object e) => e);
        expect(error, isA<EbookReadException>());
        expect((error! as EbookReadException).statusCode, 401);
        expect(error.toString(), contains('PDF delivery must be allowed'));
      });

      test('a missing file and a non-PDF answer are reported', () async {
        Future<String> failure(http.Response r) =>
            loader(r)
                .load(url)
                .then((_) => '', onError: (Object e) => e.toString());
        expect(
          await failure(http.Response('', 404)),
          contains('not found (HTTP 404)'),
        );
        expect(
          await failure(http.Response('<html>', 200)),
          contains('did not return a PDF'),
        );
      });
    });
  });

  group('screens', () {
    late List<String> rendered;
    final realViewer = EbookReaderScreen.pdfViewBuilder;

    setUp(() {
      rendered = [];
      // Stands in for the PDF engine (pdfrx) and reports the page count.
      EbookReaderScreen.pdfViewBuilder =
          (context, bytes, sourceName, callbacks) {
            expect(bytes, _pdfBytes);
            rendered.add(sourceName);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => callbacks.onReady(464),
            );
            return const Center(child: Text('PDF pages'));
          };
    });

    tearDown(() => EbookReaderScreen.pdfViewBuilder = realViewer);

    /// Lets the PDF request (real async) finish, then redraws.
    Future<void> loadPdf(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }

    Future<StudentLibraryRepository> pump(
      WidgetTester tester,
      Widget Function(StudentLibraryRepository) screen, {
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final library = newLibrary();
      addTearDown(library.dispose);
      await tester.pumpWidget(MaterialApp(theme: theme, home: screen(library)));
      await tester.pumpAndSettle();
      return library;
    }

    testWidgets(
      'Find Books has an eBooks category that opens the empty E-books page',
      (tester) async {
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
              of: find.byWidgetPredicate(
                (w) => w is ListView && w.scrollDirection == Axis.horizontal,
              ),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('eBooks'),
          150,
          scrollable: chipBar,
        );
        await tester.tap(find.text('eBooks'));
        await tester.pumpAndSettle();
        expect(find.text('E-books'), findsOneWidget);
        expect(find.text('Your library, wherever you are.'), findsOneWidget);
        expect(find.text('No e-books available yet'), findsOneWidget);
        expect(
          find.text('E-books added by the library will appear here.'),
          findsOneWidget,
        );

        // Back on Find Books, the physical list is unchanged.
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Refactoring'), findsWidgets);
      },
    );

    testWidgets('list -> details -> Read Online opens the PDF in the app', (
      tester,
    ) async {
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
      // No manual download in the Student flow.
      expect(find.text('Download PDF'), findsNothing);
      expect(find.text('Open in browser'), findsNothing);

      await tester.ensureVisible(find.text('Read Online'));
      await tester.tap(find.text('Read Online'));
      await tester.pumpAndSettle();
      await loadPdf(tester);
      expect(find.text('PDF pages'), findsOneWidget);
      expect(find.text('Page 1 of 464'), findsOneWidget);
      expect(find.byTooltip('Zoom in'), findsOneWidget);
      expect(find.byTooltip('Zoom out'), findsOneWidget);
      // The existing (stored) PDF link is what is read; nothing is saved.
      expect(
        requested.single.toString(),
        'https://storage.test/ebooks/E1/1.pdf',
      );
      expect(rendered.toSet().single, 'https://storage.test/ebooks/E1/1.pdf');
      expect(downloader.calls, isEmpty);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('E-book Details'), findsOneWidget);
    });

    testWidgets('a missing PDF disables Read Online and explains why', (
      tester,
    ) async {
      await db
          .collection('ebooks')
          .doc('E1')
          .set(_ebookDoc(id: 'E1', withPdf: false));
      await pump(
        tester,
        (library) => EbookDetailsScreen(library: library, ebookId: 'E1'),
      );
      expect(
        find.text(
          'The PDF for this e-book is not available yet. Please check again later.',
        ),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('PDF not available'), findsOneWidget);
      expect(find.text('Read Online'), findsNothing);
    });

    testWidgets('a PDF that cannot load shows an error and Try again', (
      tester,
    ) async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      // What Cloudinary answers when the account does not allow PDF delivery.
      host = (_) => http.Response(
        '{"error":{"message":"deny or ACL failure"}}',
        401,
        headers: {'x-cld-error': 'deny or ACL failure'},
      );
      await pump(
        tester,
        (library) => EbookReaderScreen(library: library, ebookId: 'E1'),
      );
      await loadPdf(tester);
      expect(
        find.textContaining('refused to deliver this PDF (HTTP 401)'),
        findsOneWidget,
      );
      expect(find.text('PDF pages'), findsNothing);
      expect(find.byTooltip('Zoom in'), findsNothing);

      host = (_) => http.Response.bytes(_pdfBytes, 200);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await loadPdf(tester);
      expect(find.text('PDF pages'), findsOneWidget);
      expect(requested, hasLength(2));
      expect(requested.last, requested.first); // the same link, loaded again
    });

    testWidgets('loading state shows progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EbookReaderLoading(progress: 0.4)),
        ),
      );
      expect(find.text('Opening the e-book… 40%'), findsOneWidget);
    });

    for (final (name, screen) in [
      ('list', (StudentLibraryRepository l) => EbooksScreen(library: l)),
      (
        'details',
        (StudentLibraryRepository l) =>
            EbookDetailsScreen(library: l, ebookId: 'E1'),
      ),
      (
        'reader',
        (StudentLibraryRepository l) =>
            EbookReaderScreen(library: l, ebookId: 'E1'),
      ),
    ]) {
      testWidgets('the $name screen follows the selected dark theme', (
        tester,
      ) async {
        await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
        await pump(tester, screen, theme: AppTheme.dark);
        final dark = AppTheme.dark;
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, dark.scaffoldBackgroundColor);
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness, Brightness.dark);
        expect(Theme.of(context).colorScheme.surface, dark.colorScheme.surface);
      });
    }

    testWidgets('the reader of a removed e-book says so', (tester) async {
      await pump(
        tester,
        (library) => EbookReaderScreen(library: library, ebookId: 'missing'),
      );
      expect(find.text('This e-book is no longer available.'), findsOneWidget);
      expect(requested, isEmpty);
    });

    testWidgets('a removed e-book shows a message instead of details', (
      tester,
    ) async {
      await pump(
        tester,
        (library) => EbookDetailsScreen(library: library, ebookId: 'missing'),
      );
      expect(find.text('This e-book is no longer available.'), findsOneWidget);
    });

    testWidgets('search text from Find Books carries over', (tester) async {
      await db.collection('ebooks').doc('E1').set(_ebookDoc(id: 'E1'));
      await db
          .collection('ebooks')
          .doc('E2')
          .set(_ebookDoc(id: 'E2', title: 'Madolduwa', category: 'Fiction'));
      await pump(
        tester,
        (library) => EbooksScreen(library: library, initialQuery: 'madol'),
      );
      expect(find.text('Madolduwa'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing);
    });
  });
}

/// Students never upload; this store must not be used.
class _NoFiles implements EbookFileStorage {
  @override
  Future<CloudMediaAsset> upload(
    PdfFile pdf, {
    void Function(double progress)? onProgress,
  }) => throw StateError('students cannot upload');
}
