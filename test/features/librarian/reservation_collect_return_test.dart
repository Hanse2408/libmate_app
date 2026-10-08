import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';

import '../library_sync/library_test_support.dart';
import 'librarian_test_helpers.dart';

/// Librarian Book Reservation Details: Ready for Pickup -> (Mark as
/// Collected) -> Collected -> (Mark as Returned) -> Returned, with a
/// confirmation each time, written to the one `reservations` document.
void main() {
  late FakeFirebaseFirestore db;
  late LibrarianFirestoreRepository librarian;

  setUp(() async {
    db = await seededFirestore();
    librarian = librarianRepo(db, FakeImageStorage());
  });
  // The Librarian shell disposes the repository it was given.

  /// A student's request for Clean Code; [approve] takes it to Ready for Pickup.
  Future<String> request(WidgetTester tester, {bool approve = true}) async {
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
      if (approve) {
        await librarian.approveReservation(id);
        await settle();
      }
    });
    return id;
  }

  Future<String> status(WidgetTester tester, String id) async {
    late String value;
    await tester.runAsync(() async {
      await settle();
      value = (await db.collection('reservations').doc(id).get()).data()!['status'] as String;
    });
    await tester.pumpAndSettle();
    return value;
  }

  Future<void> open(WidgetTester tester, String id) async {
    await pumpLibrarian(
      tester,
      LibrarianRoutes.reservationDetails(id),
      size: const Size(800, 1600),
      createRepository: () => librarian,
    );
    await tester.runAsync(settle);
    await tester.pumpAndSettle();
  }

  testWidgets('Requested: no Collected / Returned actions', (tester) async {
    final id = await request(tester, approve: false);
    await open(tester, id);
    expect(find.text('Approve Reservation'), findsOneWidget);
    expect(find.text('Mark as Collected'), findsNothing);
    expect(find.text('Mark as Returned'), findsNothing);
  });

  testWidgets('Ready for Pickup -> Collected -> Returned, each confirmed', (tester) async {
    final id = await request(tester);
    await open(tester, id);
    expect(find.text('Ready for Pickup'), findsWidgets);
    expect(find.text('Mark as Returned'), findsNothing); // not before Collected

    // Cancelling the confirmation changes nothing.
    await tapVisible(tester, find.text('Mark as Collected'));
    expect(find.text('Has the student collected "Clean Code"?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await status(tester, id), 'approved');

    await tapVisible(tester, find.text('Mark as Collected'));
    await tester.tap(find.text('Yes, Collected'));
    await tester.pump();
    await tester.runAsync(settle);
    await tester.pumpAndSettle();
    expect(await status(tester, id), 'collected');
    expect(find.text('Book Collected'), findsWidgets); // status banner (+ notification)
    expect(find.text('Mark as Collected'), findsNothing);
    expect(find.text('Mark as Returned'), findsOneWidget);

    await tapVisible(tester, find.text('Mark as Returned'));
    expect(find.text('Has the student returned "Clean Code"?'), findsOneWidget);
    await tester.tap(find.text('Yes, Returned'));
    await tester.pump();
    await tester.runAsync(settle);
    await tester.pumpAndSettle();
    expect(await status(tester, id), 'returned');
    expect(find.byKey(const ValueKey('reservation-returned-label')), findsOneWidget);
    expect(find.text('Mark as Collected'), findsNothing);
    expect(find.text('Mark as Returned'), findsNothing);
  });
}
