import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/librarian/models/librarian_notification.dart';
import 'package:libmate_app/features/librarian/providers/librarian_toast_controller.dart';
import 'package:libmate_app/features/librarian/theme/librarian_theme.dart';
import 'package:libmate_app/models/notification.dart';
import 'package:libmate_app/models/seat.dart';

import '../library_sync/library_test_support.dart';
import 'librarian_test_helpers.dart';

/// Real-time toast for new Librarian notifications, on the real Firestore
/// repository (fake database) and the shell used by every Librarian page.

final _toast = find.byKey(const ValueKey('librarian-toast'));

/// The controller's own timing, so these tests follow any change to how
/// long a banner stays (displayDuration) or slides (animationDuration).
final (Duration, Duration) _timing = () {
  final c = LibrarianToastController(notifications: const Stream.empty());
  final timing = (c.displayDuration, c.animationDuration);
  c.dispose();
  return timing;
}();
Duration get _display => _timing.$1;
Duration get _slide => _timing.$2;

/// A librarian notification as a student's action writes it (unread).
Map<String, dynamic> _librarianAlert(String title, String message, {String? reservationId, bool isRead = false}) {
  return LibrarianNotification(
    id: '',
    type: LibrarianNotificationType.newRequest,
    title: title,
    message: message,
    createdAt: DateTime.now(),
    reservationId: reservationId,
    isRead: isRead,
  ).toMap();
}

void main() {
  late FakeFirebaseFirestore db;
  late LibrarianFirestoreRepository repository;

  setUp(() async {
    db = await seededFirestore();
  });

  tearDown(() => LibrarianColors.palette = LibrarianPalette.light);

  Future<GoRouter> open(WidgetTester tester, String route, {bool dark = false}) async {
    final router = await pumpLibrarian(
      tester,
      route,
      size: const Size(420, 900),
      createRepository: () {
        repository = librarianRepo(db, FakeImageStorage());
        if (dark) repository.setDarkMode(true);
        return repository;
      },
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> arrive(WidgetTester tester, Map<String, dynamic> doc) async {
    await db.collection('notifications').add(doc);
    await tester.pump(); // snapshot delivered
    await tester.pump(const Duration(milliseconds: 300)); // slide-in
  }

  testWidgets('a new notification shows a top toast for its display time, then it goes', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    expect(_toast, findsNothing);

    await arrive(tester, _librarianAlert('New Reservation Request', 'Nethmi requested "Clean Code".'));
    expect(_toast, findsOneWidget);
    expect(find.text('New Reservation Request'), findsWidgets);
    expect(find.text('Nethmi requested "Clean Code".'), findsWidgets);
    // At the top of the screen, not a SnackBar at the bottom.
    expect(tester.getTopLeft(_toast).dy, lessThan(120));
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(_display - const Duration(milliseconds: 500));
    expect(_toast, findsOneWidget); // still there before its time is up
    await tester.pump(const Duration(milliseconds: 600)); // time up: slides out
    await tester.pumpAndSettle();
    expect(_toast, findsNothing);
  });

  testWidgets('notifications that already existed do not pop up', (tester) async {
    await db.collection('notifications').add(_librarianAlert('Old Request', 'From yesterday'));
    await open(tester, LibrarianRoutes.dashboard);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_toast, findsNothing);
  });

  testWidgets('student notifications do not pop up; librarian ones (even read) do', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    await arrive(
      tester,
      StudentNotification.create(
        recipientUid: studentUid,
        type: StudentNotificationType.reservationApproved,
        title: 'Reservation Approved',
        message: 'For the student only',
      ),
    );
    expect(_toast, findsNothing);

    // Saved as read (a librarian's own action): still a banner, still read.
    await arrive(tester, _librarianAlert('New Book Added', '"Clean Code" was added.', isRead: true));
    expect(find.descendant(of: _toast, matching: find.text('New Book Added')), findsOneWidget);
    expect(repository.notifications.single.isRead, isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('works on every Librarian page; navigation does not repeat it', (tester) async {
    final router = await open(tester, LibrarianRoutes.books);
    await arrive(tester, _librarianAlert('Seat Booking', 'Kasun booked Seat A01.'));
    expect(_toast, findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(_toast, findsNothing);

    // Changing screens or rebuilding does not show it again...
    for (final route in [LibrarianRoutes.seats, LibrarianRoutes.reservations, LibrarianRoutes.settings]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(_toast, findsNothing, reason: route);
    }
    // ...but a new one appears on any page.
    await arrive(tester, _librarianAlert('Reservation Cancelled', 'Nethmi cancelled Seat A01.'));
    expect(_toast, findsOneWidget);
    expect(find.text('Reservation Cancelled'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('several notifications are shown one after another', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    await db.collection('notifications').add(_librarianAlert('Request A', 'First'));
    await db.collection('notifications').add(_librarianAlert('Request B', 'Second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(_toast, findsOneWidget); // never stacked
    expect(find.descendant(of: _toast, matching: find.text('Request A')), findsOneWidget);

    await tester.pump(_display); // A ends
    await tester.pump(_slide); // A slid out
    await tester.pump(const Duration(milliseconds: 400)); // B slides in
    expect(_toast, findsOneWidget);
    expect(find.descendant(of: _toast, matching: find.text('Request B')), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(_toast, findsNothing);
  });

  testWidgets('the notification stays in the Notifications screen, unread', (tester) async {
    final router = await open(tester, LibrarianRoutes.dashboard);
    await arrive(tester, _librarianAlert('New Reservation Request', 'Nethmi requested "Clean Code".'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    router.go(LibrarianRoutes.notifications);
    await tester.pumpAndSettle();
    expect(find.text('New Reservation Request'), findsOneWidget);
    expect(repository.notifications.single.isRead, isFalse);
    expect((await db.collection('notifications').get()).docs, hasLength(1)); // not deleted
  });

  testWidgets('tapping the toast opens the reservation and marks it read', (tester) async {
    final router = await open(tester, LibrarianRoutes.dashboard);
    await arrive(tester, _librarianAlert('New Reservation Request', 'Tap me', reservationId: 'RSV-1'));
    await tester.tap(_toast);
    await tester.pumpAndSettle();
    expect(router.currentPath, LibrarianRoutes.reservationDetails('RSV-1'));
    expect(repository.notifications.single.isRead, isTrue);
  });

  testWidgets('dark mode toast uses the dark surface', (tester) async {
    await open(tester, LibrarianRoutes.dashboard, dark: true);
    await arrive(tester, _librarianAlert('New Reservation Request', 'In dark mode'));
    final card = tester.widget<Material>(_toast);
    expect(card.color, LibrarianPalette.dark.card);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('after logout (shell removed) nothing is shown and nothing leaks', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    await tester.pumpWidget(const SizedBox()); // signed out: Librarian area gone
    await db.collection('notifications').add(_librarianAlert('Late', 'After logout'));
    await tester.pump(const Duration(seconds: 3));
    expect(_toast, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appears on every Librarian page', (tester) async {
    final router = await open(tester, LibrarianRoutes.dashboard);
    final pages = [
      LibrarianRoutes.dashboard,
      LibrarianRoutes.reservations,
      LibrarianRoutes.books,
      LibrarianRoutes.addBook,
      LibrarianRoutes.seats,
      LibrarianRoutes.addSeat,
      LibrarianRoutes.notifications,
      LibrarianRoutes.settings,
    ];
    for (final page in pages) {
      router.go(page);
      await tester.pumpAndSettle();
      await arrive(tester, _librarianAlert('Alert on $page', 'Message'));
      expect(find.descendant(of: _toast, matching: find.text('Alert on $page')), findsOneWidget, reason: page);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(_toast, findsNothing, reason: page);
    }
  });

  testWidgets('swipe up dismisses at once; it never returns; the next one follows', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    await db.collection('notifications').add(_librarianAlert('Request A', 'First'));
    await db.collection('notifications').add(_librarianAlert('Request B', 'Second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.descendant(of: _toast, matching: find.text('Request A')), findsOneWidget);

    await tester.fling(_toast, const Offset(0, -300), 1500);
    await tester.pump(); // dismissed
    await tester.pump(const Duration(milliseconds: 400)); // B slides in
    expect(find.text('Request A'), findsNothing);
    expect(find.descendant(of: _toast, matching: find.text('Request B')), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(_toast, findsNothing);
    expect(find.text('Request A'), findsNothing); // A did not come back
    expect(repository.notifications, hasLength(2)); // both still in Notifications
  });

  testWidgets('the close button dismisses it', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    await arrive(tester, _librarianAlert('Request', 'Close me'));
    await tester.tap(find.byTooltip('Dismiss notification'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_toast, findsNothing);
    expect(repository.notifications.single.isRead, isFalse); // closing does not mark it read
  });

  testWidgets('holding the banner keeps it; letting go lets it close', (tester) async {
    await open(tester, LibrarianRoutes.dashboard);
    await arrive(tester, _librarianAlert('Request', 'Hold me'));

    final gesture = await tester.startGesture(tester.getCenter(_toast));
    // A small drag (past the touch slop, short of the dismiss distance).
    await gesture.moveBy(const Offset(0, -10));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -15));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(_toast, findsOneWidget); // still there after 2 s while held

    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(_toast, findsNothing);
  });

  group('every Librarian notification creator shows the banner', () {
    /// Runs [action] (a real repository call) and returns the banner titles
    /// shown, in order, while the banners play out.
    Future<List<String>> bannersFor(WidgetTester tester, Future<void> Function() action) async {
      final titles = <String>[];
      String? last;
      await tester.runAsync(() async {
        await action();
        await settle(); // let Firestore deliver the last snapshot too
      });
      // Long enough for several ~2.5 s banners in a row.
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        final shown = find.descendant(of: _toast, matching: find.byType(Text));
        if (shown.evaluate().length > 2) {
          // [0] is "LibMate · now", then the title and the message.
          final title = tester.widget<Text>(shown.at(1)).data!;
          final banner = '$title|${tester.widget<Text>(shown.at(2)).data}';
          if (banner != last) titles.add(title);
          last = banner;
        }
      }
      return titles;
    }

    testWidgets('librarian: Add Seat and Add Book', (tester) async {
      await open(tester, LibrarianRoutes.seats);
      final titles = await bannersFor(tester, () async {
        await repository.addSeat(
          seatNumber: 'D09',
          zone: 'Row D',
          readingRoom: 'Reading Room A',
          type: SeatType.quietZone,
        );
        await repository.addBook(
          title: 'Clean Code',
          author: 'Robert C. Martin',
          isbn: '9780132350884',
          category: 'SE',
          language: 'English',
          shelfLocation: 'SE-1',
          totalCopies: 1,
        );
      });
      expect(titles, ['New Seat Added', 'New Book Added']);
    });

    testWidgets('student: book request and seat booking', (tester) async {
      await open(tester, LibrarianRoutes.settings);
      final student = studentRepo(db);
      addTearDown(student.dispose);
      final titles = await bannersFor(tester, () async {
        await repository.addSeat(seatNumber: 'A01', zone: 'Row A', readingRoom: 'Reading Room A', type: SeatType.quietZone);
        await repository.addBook(
          title: 'Clean Code',
          author: 'Robert C. Martin',
          isbn: '9780132350884',
          category: 'SE',
          language: 'English',
          shelfLocation: 'SE-1',
          totalCopies: 2,
        );
        await settle();
        await student.reserveBook(
          book: student.bookById(repository.books.single.id)!,
          pickupDate: tomorrow(),
          loanPeriodDays: 14,
          pickupLocation: 'Desk',
        );
        await student.bookSeat(seat: student.seats.single, date: tomorrow(), startHour: 10, endHour: 12);
      });
      expect(titles, ['New Seat Added', 'New Book Added', 'New Reservation Request', 'New Reservation Request']);
    });

    testWidgets('approve, collect, renew and return', (tester) async {
      await open(tester, LibrarianRoutes.reservations);
      final student = studentRepo(db);
      addTearDown(student.dispose);
      await tester.runAsync(() async {
        await repository.addBook(
          title: 'Clean Code',
          author: 'Robert C. Martin',
          isbn: '9780132350884',
          category: 'SE',
          language: 'English',
          shelfLocation: 'SE-1',
          totalCopies: 2,
        );
        await settle();
        await student.reserveBook(
          book: student.bookById(repository.books.single.id)!,
          pickupDate: tomorrow(),
          loanPeriodDays: 14,
          pickupLocation: 'Desk',
        );
        await settle();
      });
      await tester.pumpAndSettle(const Duration(seconds: 10)); // earlier banners done
      final titles = await bannersFor(tester, () async {
        final id = repository.reservations.single.id;
        await repository.approveReservation(id);
        await settle();
        await repository.markReservationCollected(id);
        await settle();
        await repository.renewBorrowing(repository.borrowings.single.id);
        await settle();
        await repository.markBorrowingReturned(repository.borrowings.single.id);
      });
      expect(titles, ['Reservation Approved', 'Book Collected', 'Loan Renewed', 'Book Returned']);
    });

    testWidgets('reject and cancel', (tester) async {
      await open(tester, LibrarianRoutes.dashboard);
      final student = studentRepo(db);
      addTearDown(student.dispose);
      await tester.runAsync(() async {
        await repository.addSeat(seatNumber: 'A01', zone: 'Row A', readingRoom: 'Reading Room A', type: SeatType.quietZone);
        await settle();
        await student.bookSeat(seat: student.seats.single, date: tomorrow(), startHour: 10, endHour: 12);
        await student.bookSeat(seat: student.seats.single, date: tomorrow(), startHour: 14, endHour: 15);
        await settle();
      });
      await tester.pumpAndSettle(const Duration(seconds: 10));
      final titles = await bannersFor(tester, () async {
        final pending = repository.reservations;
        await repository.rejectReservation(pending.first.id, 'Room closed');
        await settle();
        final cancelled = await student.cancelReservation(pending.last.id);
        expect(cancelled.success, isTrue, reason: cancelled.message);
      });
      expect(titles, ['Reservation Rejected', 'Reservation Cancelled']);
    });

    testWidgets('demo data mode shows the banner too', (tester) async {
      final router = await pumpLibrarian(tester, LibrarianRoutes.seats, size: const Size(420, 900));
      expect(router.currentPath, LibrarianRoutes.seats);
      final demo = repositoryOf(tester);
      await demo.addSeat(seatNumber: 'Z99', zone: 'Row Z', readingRoom: 'Reading Room A', type: SeatType.quietZone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.descendant(of: _toast, matching: find.text('New Seat Added')), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('controller', () {
    LibrarianNotification note(String id) => LibrarianNotification(
      id: id,
      type: LibrarianNotificationType.newRequest,
      title: 'T$id',
      message: 'M$id',
      createdAt: DateTime.now(),
    );

    // testWidgets gives a fake clock: pump(duration) moves time forward.
    testWidgets('queues, never repeats an id, and stops after dispose', (tester) async {
      final stream = StreamController<LibrarianNotification>();
      final c = LibrarianToastController(notifications: stream.stream, isAppVisible: () => true);
      stream
        ..add(note('a'))
        ..add(note('b'))
        ..add(note('a')); // duplicate
      await tester.pump();
      expect(c.current!.id, 'a');
      expect(c.queued, 1);

      await tester.pump(_display);
      await tester.pump(_slide);
      expect(c.current!.id, 'b');
      await tester.pump(_display);
      await tester.pump(_slide);
      expect(c.current, isNull); // the duplicate "a" was not shown again

      c.dispose();
      expect(stream.hasListener, isFalse); // subscription cancelled
    });

    testWidgets('a visible but unfocused window (inactive) still shows banners', (tester) async {
      final stream = StreamController<LibrarianNotification>();
      final c = LibrarianToastController(notifications: stream.stream);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      stream.add(note('a'));
      await tester.pump();
      expect(c.current!.id, 'a');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      stream.add(note('b'));
      await tester.pump();
      expect(c.queued, 0); // hidden app: not queued for later

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      c.dispose();
    });

    testWidgets('nothing is shown while the app is in the background', (tester) async {
      final stream = StreamController<LibrarianNotification>();
      final c = LibrarianToastController(notifications: stream.stream, isAppVisible: () => false);
      stream.add(note('a'));
      await tester.pump();
      expect(c.current, isNull);
      c.dispose();
    });
  });
}
