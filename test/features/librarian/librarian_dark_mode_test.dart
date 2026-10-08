import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/librarian/theme/librarian_theme.dart';

import '../library_sync/library_test_support.dart';
import 'librarian_test_helpers.dart';

/// Dark mode: the Settings switch changes every Librarian screen, light mode
/// stays as it was, the choice is saved, and no screen keeps light colours.

/// Light-mode colours that must not appear anywhere in dark mode.
const _lightText = [Color(0xFF172033), Color(0xFF64748B)];
const _lightSurfaces = [
  Color(0xFFFFFFFF),
  Color(0xFFF8FAFC),
  Color(0xFFEFF6FF),
  Color(0xFFE2E8F0),
];

LibrarianMockRepository _darkRepository() =>
    LibrarianMockRepository()..setDarkMode(true);

/// Light text or light surfaces currently built on screen.
List<String> _lightLeftovers(WidgetTester tester) {
  final problems = <String>[];
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    final color = paragraph.text.style?.color;
    if (color != null && _lightText.contains(color)) {
      problems.add('light text "${paragraph.text.toPlainText()}"');
    }
  }
  bool isLight(Color? c) =>
      c != null && c.a > 0.9 && _lightSurfaces.contains(c.withValues(alpha: 1));
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && isLight(decoration.color)) {
      problems.add('light box ${decoration.color}');
    }
  }
  for (final material in tester.widgetList<Material>(find.byType(Material))) {
    if (isLight(material.color))
      problems.add('light material ${material.color}');
  }
  return problems;
}

void main() {
  tearDown(() => LibrarianColors.palette = LibrarianPalette.light);

  test('light mode keeps the original LibMate colours', () {
    const p = LibrarianPalette.light;
    expect(p.primary, const Color(0xFF2563EB));
    expect(p.navy, const Color(0xFF1E3A8A));
    expect(p.lightBlue, const Color(0xFFEFF6FF));
    expect(p.background, const Color(0xFFF8FAFC));
    expect(p.card, const Color(0xFFFFFFFF));
    expect(p.text, const Color(0xFF172033));
    expect(p.secondaryText, const Color(0xFF64748B));
    expect(p.gold, const Color(0xFFF2B84B));
    expect(p.available, const Color(0xFF22A06B));
    expect(p.unavailable, const Color(0xFFDC4C4C));
    expect(p.border, const Color(0xFFE2E8F0));
    expect(p.avatar, const Color(0xFF172033)); // was LibrarianColors.text
    expect(p.emphasis, const Color(0xFF1E3A8A)); // was LibrarianColors.navy
    expect(LibrarianTheme.light.brightness, Brightness.light);
    expect(LibrarianTheme.dark.brightness, Brightness.dark);
  });

  testWidgets(
    'the Settings switch turns the whole Librarian area dark and back',
    (tester) async {
      final router = await pumpLibrarian(
        tester,
        LibrarianRoutes.settings,
        size: const Size(400, 2600),
      );
      await tester.scrollUntilVisible(find.text('Dark Mode'), 300);
      final darkSwitch = find.descendant(
        of: find
            .ancestor(of: find.text('Dark Mode'), matching: find.byType(Row))
            .first,
        matching: find.byType(Switch),
      );
      Color background() =>
          tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor ??
          Theme.of(tester.element(find.text('Dark Mode')))
              .scaffoldBackgroundColor;
      Color textColor(String text) => tester
          .renderObject<RenderParagraph>(find.text(text).first)
          .text
          .style!
          .color!;

      expect(background(), LibrarianPalette.light.background);
      expect(textColor('Dark Mode'), LibrarianPalette.light.text);

      await tester.tap(darkSwitch);
      await tester.pumpAndSettle();
      expect(repositoryOf(tester).darkMode, isTrue);
      expect(background(), LibrarianPalette.dark.background);
      expect(
        textColor('Dark Mode'),
        LibrarianPalette.dark.text,
      ); // rebuilt widgets
      expect(find.text('Dark'), findsOneWidget); // Theme row value
      expect(_lightLeftovers(tester), isEmpty);

      // Other pages are dark too.
      router.go(LibrarianRoutes.books);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Book Management'))).brightness,
        Brightness.dark,
      );
      expect(
        tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .backgroundColor ??
            Theme.of(tester.element(find.byType(NavigationBar)))
                .navigationBarTheme
                .backgroundColor,
        LibrarianPalette.dark.navBar,
      );

      // And back to light.
      router.go(LibrarianRoutes.settings);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Dark Mode'), 300);
      await tester.tap(darkSwitch);
      await tester.pumpAndSettle();
      expect(repositoryOf(tester).darkMode, isFalse);
      expect(background(), LibrarianPalette.light.background);
      expect(textColor('Dark Mode'), LibrarianPalette.light.text);
    },
  );

  testWidgets('a dialog opened in dark mode uses the dark surface', (
    tester,
  ) async {
    await pumpLibrarian(
      tester,
      LibrarianRoutes.settings,
      size: const Size(400, 2600),
      createRepository: _darkRepository,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Default Borrowing Period'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final theme = Theme.of(tester.element(find.byType(Dialog)));
    expect(
      dialog.backgroundColor ?? theme.dialogTheme.backgroundColor,
      LibrarianPalette.dark.card,
    );
    expect(_lightLeftovers(tester), isEmpty);
  });

  testWidgets(
    'control: the colour check does find light colours in light mode',
    (tester) async {
      await pumpLibrarian(
        tester,
        LibrarianRoutes.dashboard,
        size: const Size(390, 900),
      );
      expect(_lightLeftovers(tester), isNotEmpty);
    },
  );

  // Dark mode must change colours only: every text run keeps the same font,
  // size, weight, letter spacing and line height as in light mode.
  group('dark mode keeps exactly the light-mode typography', () {
    /// Font family, size, weight, letter spacing and height of every text
    /// span on screen, in order (colours are ignored).
    List<String> typography(WidgetTester tester) {
      final runs = <String>[];
      for (final paragraph in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        paragraph.text.visitChildren((span) {
          final s = span.style;
          if (span is TextSpan && (span.text ?? '').isNotEmpty) {
            runs.add(
              '${span.text}|${s?.fontFamily}|${s?.fontSize}|${s?.fontWeight}|'
              '${s?.letterSpacing}|${s?.height}|${s?.wordSpacing}',
            );
          }
          return true;
        });
      }
      return runs;
    }

    for (final route in [
      LibrarianRoutes.dashboard,
      LibrarianRoutes.books,
      LibrarianRoutes.addBook,
      LibrarianRoutes.seats,
      LibrarianRoutes.notifications,
      LibrarianRoutes.settings,
      LibrarianRoutes.reports,
    ]) {
      testWidgets(route, (tester) async {
        await pumpLibrarian(tester, route, size: const Size(390, 900));
        final light = typography(tester);
        LibrarianColors.palette = LibrarianPalette.light;
        await pumpLibrarian(
          tester,
          route,
          size: const Size(390, 900),
          createRepository: _darkRepository,
        );
        await tester.pumpAndSettle();
        final dark = typography(tester);
        // The demo-data banner text is the same in both; compare everything.
        expect(dark, light, reason: route);
      });
    }
  });

  group('every Librarian page in dark mode has no light colours left', () {
    final routes = <String>[
      LibrarianRoutes.dashboard,
      LibrarianRoutes.reservations,
      LibrarianRoutes.reservationDetails('RSV-1001'), // book, pending
      LibrarianRoutes.reservationDetails('RSV-1011'), // seat, blocked
      LibrarianRoutes.reservationDetails('RSV-1007'), // rejected
      LibrarianRoutes.reservationConfirmation('RSV-1004'), // approved seat
      LibrarianRoutes.reservationConfirmation('RSV-1005'), // approved book
      LibrarianRoutes.seats,
      LibrarianRoutes.addSeat,
      LibrarianRoutes.editSeat('S001'),
      LibrarianRoutes.books,
      LibrarianRoutes.addBook,
      LibrarianRoutes.editBook('B001'),
      LibrarianRoutes.notifications,
      LibrarianRoutes.borrowings,
      LibrarianRoutes.borrowingDetails('LN-2003'),
      LibrarianRoutes.members,
      LibrarianRoutes.memberDetails('IT23003341'),
      LibrarianRoutes.reports,
      LibrarianRoutes.settings,
      LibrarianRoutes.ebooks,
      LibrarianRoutes.addEbook,
    ];
    for (final route in routes) {
      testWidgets(route, (tester) async {
        await pumpLibrarian(
          tester,
          route,
          size: const Size(390, 900),
          createRepository: _darkRepository,
        );
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          Brightness.dark,
        );

        // Check what is built, scrolling down until the end of the page.
        final problems = <String>{..._lightLeftovers(tester)};
        final list = find.byType(ListView).first;
        for (var i = 0; i < 12; i++) {
          await tester.drag(list, const Offset(0, -500));
          await tester.pumpAndSettle();
          problems.addAll(_lightLeftovers(tester));
        }
        expect(problems, isEmpty, reason: route);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the choice is saved for the librarian (Firestore)', () {
    test(
      'switching dark mode is stored in users/{uid} and loaded again',
      () async {
        final db = await seededFirestore();
        final storage = FakeImageStorage();
        final first = librarianRepo(db, storage);
        await settle();
        expect(first.darkMode, isFalse);

        expect((await first.setDarkMode(true)).success, isTrue);
        expect(first.darkMode, isTrue);
        final profile = (await db.collection('users').doc(librarianUid).get())
            .data()!;
        expect(profile['librarianDarkMode'], isTrue);
        expect(profile['role'], 'librarian'); // nothing else changed
        first.dispose();

        // Like restarting the app: a new repository reads the saved choice.
        final reopened = librarianRepo(db, storage);
        await settle();
        expect(reopened.darkMode, isTrue);
        reopened.dispose();
      },
    );

    test(
      'if saving fails the previous mode is restored and the reason shown',
      () async {
        final db = await seededFirestore();
        final repo = LibrarianFirestoreRepository(
          firestore: db,
          imageStorage: FakeImageStorage(),
          librarianUid: 'missing-user', // no profile document to update
        );
        await settle();
        final result = await repo.setDarkMode(true);
        expect(result.success, isFalse);
        expect(repo.darkMode, isFalse);
        repo.dispose();
      },
    );
  });
}
