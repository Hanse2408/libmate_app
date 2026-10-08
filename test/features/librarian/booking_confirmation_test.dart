import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/models/reservation.dart';

import '../library_sync/library_test_support.dart';
import 'librarian_test_helpers.dart';

/// Booking Confirmation shows the reservation's stored status and follows
/// it live (Firestore-backed repository, as in the app).
void main() {
  late FakeFirebaseFirestore db;
  late LibrarianFirestoreRepository librarian;

  setUp(() async {
    db = await seededFirestore();
    librarian = librarianRepo(db, FakeImageStorage());
  });
  // The Librarian shell disposes the repository it was given.

  /// A student's pending request for Clean Code.
  Future<String> request(WidgetTester tester) async {
    late String id;
    await tester.runAsync(() async {
      await librarian.addBook(
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '9780132350884',
        category: 'Software Engineering',
        language: 'English',
        shelfLocation: 'SE-1',
        totalCopies: 1,
      );
      await settle();
      final student = studentRepo(db);
      await settle();
      final result = await student.reserveBook(
        book: student.books.single,
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

  /// Runs a repository action for real, then lets the live list update.
  Future<void> act(WidgetTester tester, Future<void> Function() action) async {
    await tester.runAsync(() async {
      await action();
      await settle();
    });
    await tester.pumpAndSettle();
  }

  Future<GoRouter> open(WidgetTester tester, String id, {ReservationStatus? decision}) async {
    final router = await pumpLibrarian(
      tester,
      LibrarianRoutes.dashboard,
      size: const Size(800, 1600),
      createRepository: () => librarian,
    );
    await tester.runAsync(settle);
    router.go(LibrarianRoutes.reservationConfirmation(id), extra: decision);
    // The "Updating" spinner never settles.
    decision == null
        ? await tester.pumpAndSettle()
        : await tester.pump(const Duration(milliseconds: 500));
    return router;
  }

  testWidgets('Requested: "No decision yet"', (tester) async {
    final id = await request(tester);
    await open(tester, id);
    expect(find.text('No decision yet'), findsOneWidget);
    expect(find.text('Reservation Approved!'), findsNothing);
  });

  testWidgets('Approved: approval with Ready for Pickup', (tester) async {
    final id = await request(tester);
    await act(tester, () => librarian.approveReservation(id));
    await open(tester, id);
    expect(find.text('Reservation Approved!'), findsOneWidget);
    expect(find.text('Approval Summary'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);
  });

  testWidgets('Rejected: rejection with the reason', (tester) async {
    final id = await request(tester);
    await act(tester, () => librarian.rejectReservation(id, 'No copies left'));
    await open(tester, id);
    expect(find.text('Reservation Rejected'), findsOneWidget);
    expect(find.text('No copies left'), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);
  });

  testWidgets('Collected and Returned never show pending (or rejected)', (tester) async {
    final id = await request(tester);
    await act(tester, () => librarian.approveReservation(id));
    await act(tester, () => librarian.markReservationCollected(id));
    await open(tester, id);
    expect(find.text('Reservation Approved!'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('The student has collected the book.'), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);
    expect(find.text('Reservation Rejected'), findsNothing);

    await act(tester, () => librarian.markReservationReturned(id));
    expect(find.text('Returned'), findsOneWidget);
    expect(find.text('The student has returned the book.'), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);
  });

  testWidgets('the screen follows the status live: Requested -> Approved', (tester) async {
    final id = await request(tester);
    await open(tester, id);
    expect(find.text('No decision yet'), findsOneWidget);

    await act(tester, () => librarian.approveReservation(id));
    expect(find.text('Reservation Approved!'), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);
  });

  testWidgets('just approved, list not updated yet: "Updating", then Approved', (tester) async {
    final id = await request(tester);
    // Opened by Approve before the live list has the new status.
    await open(tester, id, decision: ReservationStatus.approved);
    expect(find.byKey(const ValueKey('confirmation-updating')), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);

    await act(tester, () => librarian.approveReservation(id));
    expect(find.text('Reservation Approved!'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirmation-updating')), findsNothing);
  });

  testWidgets('Approve button ends on the approved confirmation', (tester) async {
    final id = await request(tester);
    final router = await open(tester, id);
    router.go(LibrarianRoutes.reservationDetails(id));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Approve Reservation'));
    await tester.runAsync(settle);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, LibrarianRoutes.reservationConfirmation(id));
    expect(find.text('Reservation Approved!'), findsOneWidget);
    expect(find.text('No decision yet'), findsNothing);
  });
}
