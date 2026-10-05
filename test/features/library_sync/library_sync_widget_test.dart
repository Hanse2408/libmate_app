import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/app/routes/app_routes.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/librarian/widgets/book_cover_asset_field.dart';
import 'package:libmate_app/features/librarian/widgets/book_list_tile.dart';
import 'package:libmate_app/features/student/book_reservation/screens/book_details_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/find_books_screen.dart';
import 'package:libmate_app/features/student/book_reservation/screens/my_reservations_screen.dart';
import 'package:libmate_app/features/student/seat_booking/screens/seat_booking_screen.dart';
import 'package:libmate_app/features/student/seat_booking/widgets/booking_details_card.dart';
import 'package:libmate_app/models/reservation.dart' as shared;
import 'package:libmate_app/models/seat.dart';
import 'package:libmate_app/models/user.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

import '../librarian/librarian_test_helpers.dart';
import 'library_test_support.dart';

/// The text field under the given uppercase form label.
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await scrollTo(tester, find.text(label));
  await scrollTo(tester, _field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

final _realCoverList = BookCoverAssets.list;

/// Images showing the bundled asset [path].
Finder _assetImage(String path) => find.byWidgetPredicate(
  (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == path,
);

/// Network images showing [url] (the saved Firebase Storage download URL).
Finder _networkImage(String url) => find.byWidgetPredicate(
  (w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url == url,
);

/// Returns a picked image instead of opening the device gallery.
class _FakePicker extends ImagePickerService {
  const _FakePicker(this.image);
  final ImageUpload image;

  @override
  Future<(ImageUpload?, String?)> pickImage() async => (image, null);
}

/// Opens a Student screen on its own (the screens are pushed with Navigator
/// in the app). 440px wide: the existing Student bottom nav is 9px too wide
/// at 400px with the test font (every glyph is a full square), not on devices.
Future<void> _pumpStudent(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

/// Picks tomorrow in the Book a Seat date picker.
Future<void> _pickTomorrow(WidgetTester tester) async {
  final today = DateTime.now();
  final day = tomorrow();
  await tester.tap(find.text(formatBookingDate(DateTime(today.year, today.month, today.day))));
  await tester.pumpAndSettle();
  if (day.month != today.month) {
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('${day.day}'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Picks [hour] (e.g. '08:00') as the start time.
Future<void> _pickStart(WidgetTester tester, String hour) async {
  await tester.tap(find.text('Start Time'));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(ListTile), matching: find.text(hour)));
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore db;
  late FakeImageStorage storage;

  setUp(() async {
    db = await seededFirestore();
    storage = FakeImageStorage();
    ImagePickerService.instance = _FakePicker(pngUpload());
  });

  tearDown(() => ImagePickerService.instance = const ImagePickerService());

  Future<void> fillBookForm(WidgetTester tester) async {
    await _type(tester, 'BOOK TITLE', 'Refactoring');
    await _type(tester, 'AUTHOR', 'Martin Fowler');
    await _type(tester, 'ISBN', '9780134757599');
    await _type(tester, 'CATEGORY', 'Software Engineering');
    await _type(tester, 'TOTAL COPIES', '3');
    await _type(tester, 'SHELF-LOCATION', 'SE-02-A');
  }

  testWidgets('a cover chosen from assets/images/books/ is saved and shown to students', (
    tester,
  ) async {
    const cover = 'assets/images/books/book_new_01.jpg';
    BookCoverAssets.list = () async => ['assets/images/books/book1.jpg', cover];
    addTearDown(() => BookCoverAssets.list = _realCoverList);
    final router = await pumpLibrarian(
      tester,
      LibrarianRoutes.addBook,
      size: const Size(400, 1400),
      createRepository: () => librarianRepo(db, storage),
    );

    await fillBookForm(tester);
    await tapVisible(tester, find.text('Choose Cover'));
    await tester.tap(find.text('book_new_01.jpg'));
    await tester.pumpAndSettle();
    expect(find.text(cover), findsOneWidget); // preview shows the chosen file
    expect(_assetImage(cover), findsWidgets);
    await tapVisible(tester, find.text('Save Book'));

    // Librarian: saved with the asset path, nothing uploaded to Storage.
    expect(router.currentPath, LibrarianRoutes.books);
    expect(find.text('"Refactoring" added to the catalogue.'), findsOneWidget);
    final saved = (await db.collection('books').get()).docs.single.data();
    expect(saved['coverAsset'], cover);
    expect(saved.containsKey('coverImageUrl'), isFalse);
    expect(storage.files, isEmpty);
    expect(
      find.descendant(of: find.byType(BookListTile), matching: _assetImage(cover)),
      findsOneWidget,
    );

    // Student: the same book with the same cover in Find Books.
    final student = studentRepo(db);
    addTearDown(student.dispose);
    await _pumpStudent(tester, FindBooksScreen(library: student));
    expect(find.text('Refactoring'), findsWidgets);
    expect(_assetImage(cover), findsOneWidget);
  });

  testWidgets('librarian edits are shown live on the Student book details', (tester) async {
    final librarian = librarianRepo(db, storage);
    addTearDown(librarian.dispose);
    await librarian.addBook(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'SE-01',
      totalCopies: 2,
    );
    await tester.pumpAndSettle();
    final book = librarian.books.single;

    final student = studentRepo(db);
    addTearDown(student.dispose);
    await _pumpStudent(tester, BookDetailsScreen(library: student, bookId: book.id));
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('2 of 2 available'), findsOneWidget);

    await librarian.updateBook(
      id: book.id,
      title: 'Clean Code (2nd ed.)',
      author: book.author,
      isbn: book.isbn,
      category: book.category,
      language: book.language,
      shelfLocation: book.shelfLocation,
      totalCopies: 4,
    );
    await tester.pumpAndSettle();
    expect(find.text('Clean Code (2nd ed.)'), findsOneWidget);
    expect(find.text('4 of 4 available'), findsOneWidget);

    // A deleted book is no longer offered for reservation.
    await librarian.deleteBook(book.id);
    await tester.pumpAndSettle();
    expect(find.text('This book is no longer in the catalogue.'), findsOneWidget);
    expect(find.text('Reserve Book'), findsNothing);
  });

  testWidgets('the librarian deletes a book from the Edit Book form', (tester) async {
    final setup = librarianRepo(db, storage);
    await setup.addBook(
      title: 'Old Book',
      author: 'Someone',
      isbn: '9780134757599',
      category: 'Misc',
      language: 'English',
      shelfLocation: 'X-1',
      totalCopies: 1,
    );
    await tester.pumpAndSettle();
    final id = setup.books.single.id;
    setup.dispose();

    final router = await pumpLibrarian(
      tester,
      LibrarianRoutes.editBook(id),
      size: const Size(400, 1400),
      createRepository: () => librarianRepo(db, storage),
    );
    await tapVisible(tester, find.text('Delete Book'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(router.currentPath, LibrarianRoutes.books);
    expect(find.text('"Old Book" was deleted.'), findsOneWidget);
    expect((await db.collection('books').get()).docs, isEmpty);
  });

  testWidgets('a seat added with a photo can be booked by a student', (tester) async {
    final router = await pumpLibrarian(
      tester,
      LibrarianRoutes.addSeat,
      size: const Size(400, 1600),
      createRepository: () => librarianRepo(db, storage),
    );
    await _type(tester, 'SEAT NUMBER', 'D09');
    await _type(tester, 'ROW / ZONE', 'Row D');
    await tapVisible(tester, find.text('Quiet Zone'));
    await tapVisible(tester, find.text('Choose Image'));
    await tapVisible(tester, find.text('Save Seat'));
    expect(router.currentPath, LibrarianRoutes.seats);
    expect(find.text('Seat D09 added to Reading Room A.'), findsOneWidget);
    final seatDoc = (await db.collection('seats').get()).docs.single;
    final photoUrl = seatDoc.data()['imageUrl'] as String;
    expect(photoUrl, startsWith('https://storage.test/seat_images/${seatDoc.id}/'));

    // Student: the new seat is on the booking screen with its photo.
    final student = studentRepo(db);
    addTearDown(student.dispose);
    await _pumpStudent(tester, SeatBookingScreen(library: student));
    await _pickTomorrow(tester);
    final bookButton = find.widgetWithText(ElevatedButton, 'Book Seat');
    expect(tester.widget<ElevatedButton>(bookButton).onPressed, isNull); // no seat chosen yet
    await tester.tap(find.byKey(ValueKey('seat-${seatDoc.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Seat D09'), findsOneWidget);
    expect(_networkImage(photoUrl), findsOneWidget);

    await tester.tap(bookButton);
    await tester.pumpAndSettle();
    expect(find.text('Seat booked successfully.'), findsOneWidget);
    expect(find.textContaining('pending'), findsNothing);
    final booking = (await db.collection('reservations').get()).docs.single.data();
    expect(booking['type'], 'seat');
    expect(booking['status'], 'approved'); // confirmed at once, no librarian step
    expect(booking['itemId'], seatDoc.id);
    expect(booking['studentUid'], studentUid);
  });

  testWidgets('a seat-hour taken by another student is shown as booked', (tester) async {
    final librarian = librarianRepo(db, storage);
    addTearDown(librarian.dispose);
    await librarian.addSeat(
      seatNumber: 'A01',
      zone: 'Row A',
      readingRoom: 'Reading Room A',
      type: SeatType.quietZone,
    );
    await tester.pumpAndSettle();
    final seat = librarian.seats.single;
    final other = studentRepo(db, uid: otherStudentUid);
    addTearDown(other.dispose);
    await tester.pumpAndSettle();
    final day = tomorrow();
    final first = await other.bookSeat(seat: seat, date: day, startHour: 8, endHour: 10);
    expect(first.success, isTrue, reason: first.message);

    final student = studentRepo(db);
    addTearDown(student.dispose);
    await _pumpStudent(tester, SeatBookingScreen(library: student));
    await _pickTomorrow(tester);
    await _pickStart(tester, '08:00');
    await tester.tap(find.byKey(ValueKey('seat-${seat.id}')));
    await tester.pumpAndSettle();

    // A reserved seat cannot be chosen; tapping it explains why.
    expect(find.text('Seat A01 is already booked at this time.'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Book Seat'));
    expect(button.onPressed, isNull);
  });

  testWidgets('a student is kept out of Librarian pages', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = _FakeAuthRepository();
    final authProvider = AuthProvider(
      authRepository: auth,
      userRepository: _StudentProfiles(),
    );
    final router = AppRouter(
      authProvider,
      createStudentLibrary: () => studentRepo(db),
    ).router;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    auth.signInStudent();
    await tester.pumpAndSettle();
    String path() => router.routerDelegate.currentConfiguration.uri.path;
    expect(path(), AppRoutes.studentHome);
    expect(find.text('Nethmi!'), findsOneWidget); // real profile name

    for (final page in [
      LibrarianRoutes.addBook,
      LibrarianRoutes.addSeat,
      LibrarianRoutes.books,
      LibrarianRoutes.reservations,
    ]) {
      router.go(page);
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.studentHome, reason: page);
    }
  });

  testWidgets('My Reservations shows the librarian decision live', (tester) async {
    final librarian = librarianRepo(db, storage);
    addTearDown(librarian.dispose);
    await librarian.addBook(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'SE',
      language: 'English',
      shelfLocation: 'SE-01',
      totalCopies: 1,
    );
    await tester.pumpAndSettle();
    final student = studentRepo(db);
    addTearDown(student.dispose);
    await tester.pumpAndSettle();
    await student.reserveBook(
      book: student.books.single,
      pickupDate: tomorrow(),
      loanPeriodDays: 14,
      pickupLocation: 'Main Desk',
    );
    await tester.pumpAndSettle();

    await _pumpStudent(tester, MyReservationsScreen(library: student));
    expect(find.text('Pending'), findsOneWidget);

    final id = librarian.reservations.single.id;
    await librarian.approveReservation(id);
    await tester.pumpAndSettle();
    expect(find.text('Ready for Pickup'), findsOneWidget);
    expect(librarian.reservations.single.status, shared.ReservationStatus.approved);
  });
}

class _FakeUser implements User {
  @override
  String get uid => studentUid;

  @override
  String? get email => 'nethmi@student.test';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<User?>.broadcast();
  User? _current;

  void signInStudent() {
    _current = _FakeUser();
    _controller.add(_current);
  }

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User?> signIn({required String email, required String password}) async => null;

  @override
  Future<User?> signUp({required String email, required String password}) async => null;

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}

class _StudentProfiles implements UserRepository {
  @override
  Future<void> createUserProfile(AppUser user) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async => const AppUser(
    uid: studentUid,
    name: 'Nethmi Perera',
    studentId: 'IT23004512',
    email: 'nethmi@student.test',
    role: UserRole.student,
  );
}
