import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/core/services/ebook_service.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';
import 'package:libmate_app/features/librarian/providers/ebook_provider.dart';
import 'package:libmate_app/features/librarian/widgets/ebook_tile.dart';
import 'package:libmate_app/models/ebook.dart';
import 'package:libmate_app/repositories/ebook_repository.dart';

import '../library_sync/library_test_support.dart'
    show FakeImageStorage, pngUpload;
import 'librarian_test_helpers.dart';

/// A tiny but valid-looking PDF (starts with "%PDF").
PdfFile _pdf([String name = 'clean-code.pdf', int size = 2048]) {
  final bytes = Uint8List(size)
    ..setAll(0, [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]);
  final (pdf, error) = PdfFile.validate(bytes: bytes, fileName: name);
  expect(error, isNull);
  return pdf!;
}

EbookRecord _ebook({
  String id = '',
  String title = 'Clean Code',
  String isbn = '',
  EbookStatus status = EbookStatus.draft,
  String? coverAsset = 'assets/images/books/book1.jpg',
}) {
  return EbookRecord(
    id: id,
    title: title,
    author: 'Robert C. Martin',
    category: 'Software Engineering',
    language: 'English',
    isbn: isbn,
    description: 'A handbook.',
    publisher: 'Prentice Hall',
    publishedYear: 2008,
    pages: 464,
    coverAsset: coverAsset,
    status: status,
  );
}

class _FakeImagePicker extends ImagePickerService {
  const _FakeImagePicker(this.image);
  final ImageUpload image;

  @override
  Future<(ImageUpload?, String?)> pickImage() async => (image, null);
}

class _FakePicker extends PdfPickerService {
  _FakePicker(this.result);
  (PdfFile?, String?) result;

  @override
  Future<(PdfFile?, String?)> pickPdf() async => result;
}

class _FakeLauncher extends PdfLauncher {
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late FakePdfStorage files;
  late FakeImageStorage images;
  late EbookProvider provider;

  setUp(() {
    db = FakeFirebaseFirestore();
    files = FakePdfStorage();
    images = FakeImageStorage();
    provider = buildFakeEbookProvider(
      firestore: db,
      files: files,
      images: images,
    );
  });

  Future<Map<String, dynamic>> onlyEbookDoc() async =>
      (await db.collection('ebooks').get()).docs.single.data();

  group('PDF validation', () {
    test('accepts a PDF and refuses other files', () {
      expect(_pdf().sizeBytes, 2048);
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 1]);
      expect(
        PdfFile.validate(bytes: pdfBytes, fileName: 'notes.docx').$2,
        contains('PDF file'),
      );
      expect(
        PdfFile.validate(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          fileName: 'fake.pdf',
        ).$2,
        contains('not a valid PDF'),
      );
      expect(
        PdfFile.validate(bytes: Uint8List(0), fileName: 'empty.pdf').$2,
        contains('empty'),
      );
      final tooBig = Uint8List(PdfFile.maxBytes + 1)
        ..setAll(0, [0x25, 0x50, 0x44, 0x46]);
      expect(
        PdfFile.validate(bytes: tooBig, fileName: 'big.pdf').$2,
        contains('25 MB'),
      );
    });
  });

  group('repository / provider', () {
    test(
      'a draft is saved in `ebooks` without a PDF; `books` is untouched',
      () async {
        final result = await provider.save(ebook: _ebook(), isNew: true);
        expect(result.success, isTrue, reason: result.message);

        final doc = await onlyEbookDoc();
        expect(doc['title'], 'Clean Code');
        expect(doc['status'], 'draft');
        expect(doc['coverAsset'], 'assets/images/books/book1.jpg');
        expect(doc['bookId'], isNotEmpty);
        expect(doc['publishedYear'], 2008);
        expect(doc['pages'], 464);
        expect(doc['location'], EbookRecord.defaultLocation);
        expect(doc['pdfUrl'], isNull);
        expect(doc['createdBy'], 'librarian-1');
        expect((await db.collection('books').get()).docs, isEmpty);
      },
    );

    test('publishing needs a PDF', () async {
      final result = await provider.save(
        ebook: _ebook(status: EbookStatus.published),
        isNew: true,
      );
      expect(result.success, isFalse);
      expect(result.message, contains('Upload the PDF'));
      expect((await db.collection('ebooks').get()).docs, isEmpty);
    });

    test(
      'publishing uploads the PDF and stores Cloudinary metadata only',
      () async {
        final result = await provider.save(
          ebook: _ebook(status: EbookStatus.published),
          isNew: true,
          newPdf: _pdf(),
        );
        expect(result.success, isTrue, reason: result.message);

        final doc = await onlyEbookDoc();
        final publicId = doc['pdfPublicId'] as String;
        expect(publicId, startsWith('ebooks/test-'));
        expect(
          doc['pdfUrl'],
          'https://res.cloudinary.com/test/image/upload/$publicId.pdf',
        );
        expect(doc['pdfPath'], isNull);
        expect(doc['pdfResourceType'], 'image');
        expect(doc['pdfFormat'], 'pdf');
        expect(doc['pdfFileName'], 'clean-code.pdf');
        expect(doc['pdfSizeBytes'], 2048);
        expect(
          doc.values.whereType<Uint8List>(),
          isEmpty,
        ); // no file bytes in Firestore
        expect(files.files.keys, [publicId]);
        await pumpEventQueue();
        expect(provider.publishedCount, 1);
      },
    );

    test('a duplicate ISBN is refused', () async {
      await provider.save(ebook: _ebook(isbn: '978-0132350884'), isNew: true);
      final again = await provider.save(
        ebook: _ebook(title: 'Copy', isbn: '9780132350884'),
        isNew: true,
      );
      expect(again.success, isFalse);
      expect(again.message, contains('ISBN'));
    });

    test('replacing the PDF updates Firestore without deleting the old Cloudinary asset', () async {
      await provider.save(
        ebook: _ebook(status: EbookStatus.published),
        isNew: true,
        newPdf: _pdf(),
      );
      await pumpEventQueue();
      final saved = provider.ebooks.single;
      final oldPublicId = saved.pdfPublicId!;

      final edited = EbookRecord(
        id: saved.id,
        title: 'Clean Code (2nd ed.)',
        author: saved.author,
        category: saved.category,
        language: saved.language,
        pages: 500,
        coverAsset: 'assets/images/books/book2.jpg',
        pdfUrl: saved.pdfUrl,
        pdfPath: saved.pdfPath,
        pdfPublicId: saved.pdfPublicId,
        pdfResourceType: saved.pdfResourceType,
        pdfFormat: saved.pdfFormat,
        pdfFileName: saved.pdfFileName,
        pdfSizeBytes: saved.pdfSizeBytes,
        status: EbookStatus.published,
      );
      final result = await provider.save(
        ebook: edited,
        isNew: false,
        newPdf: _pdf('v2.pdf'),
      );
      expect(result.success, isTrue, reason: result.message);

      final docs = (await db.collection('ebooks').get()).docs;
      expect(docs, hasLength(1)); // no duplicate
      final doc = docs.single.data();
      expect(doc['title'], 'Clean Code (2nd ed.)');
      expect(doc['pages'], 500);
      expect(doc['coverAsset'], 'assets/images/books/book2.jpg');
      expect(doc['pdfFileName'], 'v2.pdf');
      expect(doc['pdfPublicId'], isNot(oldPublicId));
      expect(doc['pdfPath'], isNull);
      expect(files.files.keys, containsAll([oldPublicId, doc['pdfPublicId']]));
    });

    test('a failed upload saves nothing', () async {
      files.failWith = 'Cloudinary rejected this file type.';
      final result = await provider.save(
        ebook: _ebook(status: EbookStatus.published),
        isNew: true,
        newPdf: _pdf(),
      );
      expect(result.success, isFalse);
      expect(result.message, contains('Cloudinary'));
      expect((await db.collection('ebooks').get()).docs, isEmpty);
    });

    test('if the Firestore write fails the uploaded Cloudinary asset is left unreferenced', () async {
      final ghost = _ebook(id: 'gone', status: EbookStatus.published);
      final repo = EbookRepository(
        service: EbookService(firestore: db, files: files),
      );
      final result = await repo.save(
        ebook: ghost,
        isNew: false,
        newPdf: _pdf(),
      );
      expect(result.success, isFalse);
      expect(files.files, hasLength(1));
      expect((await db.collection('ebooks').get()).docs, isEmpty);
    });

    test('delete removes the Firestore reference without attempting Cloudinary deletion', () async {
      await provider.save(
        ebook: _ebook(status: EbookStatus.published),
        isNew: true,
        newPdf: _pdf(),
      );
      await pumpEventQueue();
      final ebook = provider.ebooks.single;
      final publicId = ebook.pdfPublicId!;

      final result = await provider.delete(ebook);
      expect(result.success, isTrue, reason: result.message);
      expect((await db.collection('ebooks').get()).docs, isEmpty);
      expect(files.files.containsKey(publicId), isTrue);
    });

    test('search by title, author or ISBN', () async {
      await provider.save(ebook: _ebook(isbn: '9780132350884'), isNew: true);
      await provider.save(
        ebook: _ebook(title: 'Madol Doova', isbn: '9789550000000'),
        isNew: true,
      );
      await pumpEventQueue();
      provider.search('madol');
      expect(provider.visibleEbooks.single.title, 'Madol Doova');
      provider.search('978-0132350884');
      expect(provider.visibleEbooks.single.title, 'Clean Code');
      provider.search('');
      expect(provider.visibleEbooks, hasLength(2));
    });
  });

  group('cover upload', () {
    test('cover and PDF are uploaded independently and both stored', () async {
      final result = await provider.save(
        ebook: _ebook(coverAsset: null),
        isNew: true,
        newPdf: _pdf(),
        newCover: pngUpload(),
      );
      expect(result.success, isTrue, reason: result.message);
      final doc = (await db.collection('ebooks').get()).docs.single.data();
      expect(doc['coverAsset'], startsWith('https://res.cloudinary.com/'));
      expect(doc['coverPublicId'], images.files.keys.single);
      expect(doc['pdfPublicId'], files.files.keys.single);
    });

    test('editing the cover only keeps the PDF', () async {
      await provider.save(
        ebook: _ebook(coverAsset: null),
        isNew: true,
        newPdf: _pdf(),
        newCover: pngUpload(),
      );
      final before = (await db.collection('ebooks').get()).docs.single;
      final saved = provider.ebooks.single;
      await provider.save(
        ebook: saved,
        isNew: false,
        newCover: pngUpload('second.png'),
      );
      final after = (await db.collection('ebooks').get()).docs.single.data();
      expect(after['pdfPublicId'], before['pdfPublicId']);
      expect(after['pdfUrl'], before['pdfUrl']);
      expect(after['coverPublicId'], isNot(before['coverPublicId']));
      expect(files.files, hasLength(1)); // PDF not re-uploaded
      expect(images.files, hasLength(2));
    });

    test('editing the PDF only keeps the cover', () async {
      await provider.save(
        ebook: _ebook(coverAsset: null),
        isNew: true,
        newPdf: _pdf(),
        newCover: pngUpload(),
      );
      final before = (await db.collection('ebooks').get()).docs.single;
      await provider.save(
        ebook: provider.ebooks.single,
        isNew: false,
        newPdf: _pdf('new.pdf'),
      );
      final after = (await db.collection('ebooks').get()).docs.single.data();
      expect(after['coverAsset'], before['coverAsset']);
      expect(after['coverPublicId'], before['coverPublicId']);
      expect(after['pdfPublicId'], isNot(before['pdfPublicId']));
      expect(images.files, hasLength(1)); // cover not re-uploaded
    });

    test('an old asset cover is kept when no new cover is chosen', () async {
      await provider.save(ebook: _ebook(), isNew: true, newPdf: _pdf());
      final doc = (await db.collection('ebooks').get()).docs.single.data();
      expect(doc['coverAsset'], 'assets/images/books/book1.jpg');
      expect(images.files, isEmpty);
    });
  });

  group('screens', () {
    late _FakePicker picker;
    late _FakeLauncher launcher;

    setUp(() {
      picker = _FakePicker((_pdf(), null));
      launcher = _FakeLauncher();
      PdfPickerService.instance = picker;
      PdfLauncher.instance = launcher;
      ImagePickerService.instance = _FakeImagePicker(pngUpload());
    });

    tearDown(() {
      PdfPickerService.instance = const PdfPickerService();
      PdfLauncher.instance = const PdfLauncher();
      ImagePickerService.instance = const ImagePickerService();
    });

    Finder field(String label) => find.descendant(
      of: find
          .ancestor(of: find.text(label), matching: find.byType(Column))
          .first,
      matching: find.byType(TextFormField),
    );

    Future<void> type(WidgetTester tester, String label, String text) async {
      await scrollTo(tester, field(label));
      await tester.enterText(field(label), text);
      await tester.pump();
    }

    Future<void> choose(
      WidgetTester tester,
      String dropdownLabel,
      String option,
    ) async {
      final dropdown = find.descendant(
        of: find
            .ancestor(
              of: find.text(dropdownLabel),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(DropdownButtonFormField<String>),
      );
      await scrollTo(tester, dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    Future<void> open(WidgetTester tester, String route) async {
      await pumpLibrarian(
        tester,
        route,
        size: const Size(420, 1000),
        createEbooks: () => provider,
      );
    }

    testWidgets('Book Management links to E-book Management', (tester) async {
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.books,
        createEbooks: () => provider,
      );
      await tapVisible(tester, find.text('E-book Management'));
      expect(router.currentPath, LibrarianRoutes.ebooks);
      expect(find.text('Manage e-books'), findsOneWidget);
      expect(find.text('No e-books yet'), findsOneWidget);
      expect(find.text('0 published'), findsOneWidget);
    });

    testWidgets('publishing with missing details shows every problem', (
      tester,
    ) async {
      await open(tester, LibrarianRoutes.addEbook);
      await tapVisible(tester, find.text('Publish e-book'));
      expect(find.text('Book title is required'), findsOneWidget);
      expect(find.text('Author is required'), findsOneWidget);
      expect(find.text('Category is required'), findsOneWidget);
      expect(
        find.text('Choose a cover image before publishing.'),
        findsOneWidget,
      );
      expect(find.text('Upload the PDF before publishing.'), findsOneWidget);

      await type(tester, 'PUBLISHED YEAR', '99');
      expect(find.text('Enter a valid year, e.g. 2008'), findsOneWidget);
      expect((await db.collection('ebooks').get()).docs, isEmpty);
    });

    testWidgets('a wrong file in the PDF picker is explained', (tester) async {
      picker.result = (null, 'This file is not a valid PDF.');
      await open(tester, LibrarianRoutes.addEbook);
      await tapVisible(tester, find.text('3. Upload PDF *'));
      expect(find.text('This file is not a valid PDF.'), findsOneWidget);
    });

    testWidgets(
      'Add New E-book opens the add page; publishing returns to the list',
      (tester) async {
        final router = await pumpLibrarian(
          tester,
          LibrarianRoutes.ebooks,
          size: const Size(420, 1000),
          createEbooks: () => provider,
        );
        expect(
          find.text('Add new e-book'),
          findsNothing,
        ); // no form on the list page
        await tapVisible(tester, find.text('Add New E-book'));
        expect(router.currentPath, LibrarianRoutes.addEbook);
        expect(find.text('Add New E-book'), findsOneWidget); // page title

        await tapVisible(tester, find.text('Choose Cover'));
        expect(find.text('Change Cover'), findsOneWidget);
        await type(tester, 'BOOK TITLE *', 'Clean Code');
        await type(tester, 'AUTHOR *', 'Robert C. Martin');
        await choose(tester, 'CATEGORY *', 'Software Engineering');
        await type(tester, 'PAGES', '464');
        await tapVisible(tester, find.text('3. Upload PDF *'));
        expect(find.text('clean-code.pdf · 2 KB'), findsOneWidget);
        await tapVisible(tester, find.text('Publish e-book'));

        expect(router.currentPath, LibrarianRoutes.ebooks);
        expect(find.text('"Clean Code" was published.'), findsOneWidget);
        expect(find.byType(EbookTile), findsOneWidget);
        expect(find.text('Published · PDF'), findsOneWidget);
        expect(find.text('1 published'), findsOneWidget);
        final doc = await onlyEbookDoc();
        expect(doc['coverAsset'], startsWith('https://res.cloudinary.com/'));
        expect(doc['coverPublicId'], images.files.keys.single);
        expect(doc['pdfPublicId'], startsWith('ebooks/test-'));
        expect(doc['pages'], 464);
      },
    );

    testWidgets('edit: values are pre-filled, saving returns to the list', (
      tester,
    ) async {
      await provider.save(
        ebook: _ebook(status: EbookStatus.published),
        isNew: true,
        newPdf: _pdf(),
      );
      await tester.pumpAndSettle();
      final id = provider.ebooks.single.id;

      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.editEbook(id),
        size: const Size(420, 1000),
        createEbooks: () => provider,
      );
      expect(find.text('Edit e-book'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(field('BOOK TITLE *')).controller!.text,
        'Clean Code',
      );
      expect(find.text('3. PDF uploaded *'), findsOneWidget);
      expect(find.text('clean-code.pdf · 2 KB'), findsOneWidget);

      await type(tester, 'BOOK TITLE *', 'Clean Code (2nd ed.)');
      await tapVisible(tester, find.text('Publish e-book'));
      expect(router.currentPath, LibrarianRoutes.ebooks);
      expect(
        find.text('"Clean Code (2nd ed.)" was updated and published.'),
        findsOneWidget,
      );
      expect((await db.collection('ebooks').get()).docs, hasLength(1));
      expect((await onlyEbookDoc())['title'], 'Clean Code (2nd ed.)');
    });

    testWidgets('delete asks first and removes the e-book', (tester) async {
      await provider.save(ebook: _ebook(), isNew: true);
      await open(tester, LibrarianRoutes.ebooks);
      await tapVisible(tester, find.widgetWithText(TextButton, 'Delete'));
      expect(find.text('Delete this e-book?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('"Clean Code" was deleted.'), findsOneWidget);
      expect(find.byType(EbookTile), findsNothing);
      expect((await db.collection('ebooks').get()).docs, isEmpty);
    });

    testWidgets('PDF Quick Action opens the PDF', (tester) async {
      await provider.save(
        ebook: _ebook(status: EbookStatus.published),
        isNew: true,
        newPdf: _pdf(),
      );
      await open(tester, LibrarianRoutes.ebooks);
      await tapVisible(tester, find.byTooltip('PDF quick actions'));
      expect(find.text('PDF Quick Actions'), findsOneWidget);
      expect(find.text('clean-code.pdf · 2 KB'), findsOneWidget);
      await tester.tap(find.text('Open PDF'));
      await tester.pumpAndSettle();
      expect(launcher.opened.single, provider.ebooks.single.pdfUrl);
    });

    testWidgets(
      'PDF Quick Action on a draft without PDF explains and uploads one',
      (tester) async {
        await provider.save(ebook: _ebook(), isNew: true);
        await open(tester, LibrarianRoutes.ebooks);
        await tapVisible(tester, find.byTooltip('PDF quick actions'));
        expect(
          find.text('No PDF has been uploaded for this e-book yet.'),
          findsOneWidget,
        );
        expect(find.text('Open PDF'), findsNothing);

        await tester.tap(find.text('Upload PDF'));
        await tester.pumpAndSettle();
        expect(find.text('PDF uploaded: clean-code.pdf.'), findsOneWidget);
        expect((await onlyEbookDoc())['pdfFileName'], 'clean-code.pdf');
      },
    );
  });
}
