import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/librarian/models/member_record.dart';
import 'package:libmate_app/features/librarian/providers/librarian_dashboard_summary.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/models/book.dart';
import 'package:libmate_app/models/notification.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/seat.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'library_test_support.dart';

/// Librarian and Student repositories on one (fake) Firestore database:
/// what a librarian saves is what students see.
void main() {
  late FakeFirebaseFirestore db;
  late FakeImageStorage storage;
  late LibrarianFirestoreRepository librarian;
  late StudentLibraryRepository student;

  setUp(() async {
    db = await seededFirestore();
    storage = FakeImageStorage();
    librarian = librarianRepo(db, storage);
    student = studentRepo(db);
    await settle();
  });

  tearDown(() {
    librarian.dispose();
    student.dispose();
  });

  Future<BookRecord> addCleanCode({int copies = 3}) async {
    final result = await librarian.addBook(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '978-0132350884',
      category: 'Software Engineering',
      language: 'English',
      shelfLocation: 'se-01-a',
      totalCopies: copies,
      description: 'A handbook of agile software craftsmanship.',
    );
    expect(result.success, isTrue, reason: result.message);
    await settle();
    return librarian.books.single;
  }

  Future<SeatRecord> addSeat(String number) async {
    final result = await librarian.addSeat(
      seatNumber: number,
      zone: 'Row A',
      readingRoom: 'Reading Room A',
      type: SeatType.quietZone,
      hasPowerOutlet: true,
    );
    expect(result.success, isTrue, reason: result.message);
    await settle();
    return librarian.seats.firstWhere(
      (s) => s.seatNumber == number.toUpperCase(),
    );
  }

  group('Books', () {
    test(
      'a book added by the librarian is saved and shown to students',
      () async {
        expect(librarian.isLoading, isFalse);
        final book = await addCleanCode();

        expect(book.shelfLocation, 'SE-01-A');
        expect(book.availableCopies, 3);
        final saved = (await db.collection('books').doc(book.id).get()).data()!;
        expect(saved['title'], 'Clean Code');
        expect(saved['isbnKey'], '9780132350884');
        expect(saved['createdBy'], librarianUid);

        expect(student.books.map((b) => b.title), ['Clean Code']);
      },
    );

    test(
      'the saved book is still there after reopening (new repository)',
      () async {
        await addCleanCode();
        librarian.dispose();

        librarian = librarianRepo(db, storage);
        expect(librarian.isLoading, isTrue);
        await settle();
        expect(librarian.isLoading, isFalse);
        expect(librarian.books.single.title, 'Clean Code');
      },
    );

    test(
      'a duplicate ISBN is refused, also when the list is not loaded yet',
      () async {
        await addCleanCode();
        final fresh = librarianRepo(db, storage); // nothing loaded yet
        final result = await fresh.addBook(
          title: 'Clean Code (copy)',
          author: 'R. Martin',
          isbn: '9780132350884',
          category: 'SE',
          language: 'English',
          shelfLocation: 'X-1',
          totalCopies: 1,
        );
        fresh.dispose();

        expect(result.success, isFalse);
        expect(result.message, contains('ISBN already exists'));
        expect((await db.collection('books').get()).docs, hasLength(1));
      },
    );

    test('edits are saved and reflected on student screens', () async {
      final book = await addCleanCode();
      final result = await librarian.updateBook(
        id: book.id,
        title: 'Clean Code (2nd ed.)',
        author: book.author,
        isbn: book.isbn,
        category: book.category,
        language: book.language,
        shelfLocation: book.shelfLocation,
        totalCopies: 5,
      );
      expect(result.success, isTrue, reason: result.message);
      await settle();

      final seen = student.bookById(book.id)!;
      expect(seen.title, 'Clean Code (2nd ed.)');
      expect(seen.totalCopies, 5);
      expect(seen.availableCopies, 5);
    });

    test(
      'a book without active reservations or loans can be deleted',
      () async {
        final book = await addCleanCode();
        final result = await librarian.deleteBook(book.id);
        expect(result.success, isTrue, reason: result.message);
        await settle();

        expect(librarian.books, isEmpty);
        expect(student.books, isEmpty);
      },
    );

    test('a book with an active reservation cannot be deleted', () async {
      final book = await addCleanCode();
      await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      await settle();

      final result = await librarian.deleteBook(book.id);
      expect(result.success, isFalse);
      expect(result.message, contains('active reservation'));
      expect((await db.collection('books').doc(book.id).get()).exists, isTrue);
    });

    test(
      'the cover asset path is saved in coverAsset and shown to students',
      () async {
        const cover = 'assets/images/books/book_new_01.jpg';
        final result = await librarian.addBook(
          title: 'Refactoring',
          author: 'Martin Fowler',
          isbn: '9780134757599',
          category: 'Software Engineering',
          language: 'English',
          shelfLocation: 'se-02',
          totalCopies: 2,
          coverAsset: cover,
          publisher: 'Addison-Wesley',
          publishedYear: 2018,
          pages: 448,
        );
        expect(result.success, isTrue, reason: result.message);
        await settle();

        final book = librarian.books.single;
        expect(book.coverAsset, cover);
        expect(student.bookById(book.id)!.coverAsset, cover);
        expect(
          storage.files,
          isEmpty,
        ); // no media was uploaded by this operation

        final doc = (await db.collection('books').doc(book.id).get()).data()!;
        expect(doc['coverAsset'], cover);
        expect(doc.containsKey('coverImageUrl'), isFalse);
        // The fields the Student book service reads, with the types it expects.
        expect(doc['bookId'], book.id);
        expect(doc['publisher'], 'Addison-Wesley');
        expect(doc['publishedYear'], 2018);
        expect(doc['pages'], 448);
        expect(doc['available'], isTrue);
        expect(doc['location'], 'SE-02');
        expect(doc['description'], isA<String>());
      },
    );

    test(
      'a book without a cover saves an empty coverAsset and default details',
      () async {
        final book = await addCleanCode();
        expect(book.coverAsset, isNull);
        final doc = (await db.collection('books').doc(book.id).get()).data()!;
        expect(doc['coverAsset'], '');
        expect(doc['publisher'], '');
        expect(doc['publishedYear'], 0);
        expect(doc['pages'], 0);
      },
    );

    test('the cover can be changed and removed when editing', () async {
      final book = await addCleanCode();
      Future<void> setCover(String? cover) async {
        final result = await librarian.updateBook(
          id: book.id,
          title: book.title,
          author: book.author,
          isbn: book.isbn,
          category: book.category,
          language: book.language,
          shelfLocation: book.shelfLocation,
          totalCopies: book.totalCopies,
          coverAsset: cover,
        );
        expect(result.success, isTrue, reason: result.message);
        await settle();
      }

      await setCover('assets/images/books/book1.jpg'); // an existing cover
      expect(
        student.bookById(book.id)!.coverAsset,
        'assets/images/books/book1.jpg',
      );
      await setCover(null);
      expect(student.bookById(book.id)!.coverAsset, isNull);
      expect(
        (await db.collection('books').doc(book.id).get()).data()!['coverAsset'],
        '',
      );
    });

    test(
      'existing books with only coverAsset (e.g. book1.jpg) still load',
      () async {
        await db.collection('books').doc('B1').set({
          'bookId': 'B1',
          'title': 'Clean Code',
          'author': 'Robert C. Martin',
          'category': 'Programming',
          'description': 'A handbook.',
          'coverAsset': 'assets/images/books/book1.jpg',
          'publisher': 'Prentice Hall',
          'publishedYear': 2008,
          'pages': 464,
          'available': true,
          'location': 'Shelf A',
        });
        await settle();
        final book = librarian.bookById('B1')!;
        expect(book.coverAsset, 'assets/images/books/book1.jpg');
        expect(book.publishedYear, 2008);
        expect(book.pages, 464);
      },
    );
  });

  group('Seats', () {
    test('a seat added by the librarian appears for students', () async {
      final seat = await addSeat('a01');
      expect(seat.seatNumber, 'A01');
      expect(seat.status, SeatStatus.available);
      expect(student.seats.single.id, seat.id);
    });

    test('a duplicate seat number in the same room is refused', () async {
      await addSeat('A01');
      final result = await librarian.addSeat(
        seatNumber: 'a01',
        zone: 'Row A',
        readingRoom: 'reading room a',
        type: SeatType.groupStudy,
      );
      expect(result.success, isFalse);
      expect(result.message, contains('already exists'));
    });

    test('seat edits persist after reopening; no seat image is uploaded', () async {
      final seat = await addSeat('A01');
      final result = await librarian.updateSeat(
        id: seat.id,
        seatNumber: 'A02',
        zone: 'Row A',
        readingRoom: 'Reading Room A',
        type: SeatType.individualDesk,
        isNearWindow: true,
        note: 'By the window',
      );
      expect(result.success, isTrue, reason: result.message);
      librarian.dispose();

      librarian = librarianRepo(db, storage);
      await settle();
      final saved = librarian.seats.single;
      expect(saved.seatNumber, 'A02');
      expect(saved.isNearWindow, isTrue);
      expect(saved.note, 'By the window');
      expect(saved.imageUrl, isNull);
      expect(storage.files, isEmpty); // nothing sent to Cloudinary
    });

    test('editing an older seat leaves its saved image fields untouched', () async {
      final seat = await addSeat('A01');
      // A seat saved when seats still had photos.
      const url = 'https://res.cloudinary.com/test/image/upload/seat_images/old.png';
      await db.collection('seats').doc(seat.id).update({
        'imageUrl': url,
        'imagePublicId': 'seat_images/old',
      });
      await settle();

      final result = await librarian.updateSeat(
        id: seat.id,
        seatNumber: 'A01',
        zone: 'Row B',
        readingRoom: 'Reading Room A',
        type: SeatType.quietZone,
      );
      expect(result.success, isTrue, reason: result.message);
      await settle();
      final data = (await db.collection('seats').doc(seat.id).get()).data()!;
      expect(data['zone'], 'Row B');
      expect(data['imageUrl'], url);
      expect(data['imagePublicId'], 'seat_images/old');
      expect(storage.files, isEmpty);
    });

    test('a seat with an upcoming booking cannot be deleted', () async {
      final seat = await addSeat('A01');
      final booked = await student.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 10,
        endHour: 12,
      );
      expect(booked.success, isTrue, reason: booked.message);
      await settle();

      final result = await librarian.deleteSeat(seat.id);
      expect(result.success, isFalse);
      expect(result.message, contains('upcoming booking'));
    });

    test('a seat without bookings can be deleted', () async {
      final seat = await addSeat('A01');
      expect((await librarian.deleteSeat(seat.id)).success, isTrue);
      await settle();
      expect(student.seats, isEmpty);
    });
  });

  group('Seat bookings', () {
    test(
      'two students cannot book the same seat for overlapping times',
      () async {
        final seat = await addSeat('A01');
        final other = studentRepo(db, uid: otherStudentUid);
        await settle();

        final first = await student.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 10,
          endHour: 12,
        );
        expect(first.success, isTrue, reason: first.message);
        final overlapping = await other.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 11,
          endHour: 13,
        );
        expect(overlapping.success, isFalse);
        expect(overlapping.message, contains('just booked by someone else'));

        // A later, non-overlapping slot on the same seat is fine.
        final later = await other.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 12,
          endHour: 14,
        );
        expect(later.success, isTrue, reason: later.message);

        final slots = await db.collection('seatSlots').get();
        expect(slots.docs, hasLength(4)); // 10, 11 (first) + 12, 13 (later)
        other.dispose();
      },
    );

    test(
      'a seat booking is confirmed at once, with no librarian approval',
      () async {
        final seat = await addSeat('A01');
        final result = await student.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 10,
          endHour: 12,
        );
        expect(result.success, isTrue, reason: result.message);
        await settle();

        final doc = (await db.collection('reservations').get()).docs.single;
        expect(result.reservationId, doc.id); // the exact reservation created
        expect(doc.data()['type'], 'seat');
        expect(doc.data()['status'], 'approved');
        expect(
          student.myReservations.single.status,
          ReservationStatus.approved,
        );
        expect(librarian.reservations.single.itemId, seat.id);

        // One slot per booked hour, linked to the reservation.
        final slots = (await db.collection('seatSlots').get()).docs;
        expect(slots, hasLength(2));
        expect(slots.every((s) => s.data()['reservationId'] == doc.id), isTrue);

        // No "waiting for approval" notification for either side.
        expect(
          librarian.notifications.any(
            (n) => n.title == 'New Reservation Request',
          ),
          isFalse,
        );
        // Exactly one student confirmation, and no librarian request.
        expect(student.notifications, hasLength(1));
        final note = student.notifications.single;
        expect(note.type, StudentNotificationType.seatBookingConfirmed);
        expect(note.title, 'Seat Booking Confirmed');
        expect(note.recipientUid, studentUid);
        expect(note.reservationId, doc.id);
        expect(note.itemId, seat.id);
        expect(note.isRead, isFalse);
      },
    );

    test(
      'a booked seat shows as Reserved for the librarian at once, from Firestore',
      () async {
        final seat = await addSeat('A01');
        final free = await addSeat('A02');
        expect(librarian.seatMapStatus(seat), SeatStatus.available);

        final result = await student.bookSeat(
          seat: seat,
          date: tomorrow(),
          startHour: 10,
          endHour: 12,
        );
        expect(result.success, isTrue, reason: result.message);
        await settle();

        // No librarian action: the live `reservations` stream marks it.
        expect(librarian.seatMapStatus(librarian.seatById(seat.id)!), SeatStatus.reserved);
        expect(librarian.seatMapStatus(librarian.seatById(free.id)!), SeatStatus.available);
        final summary = LibrarianDashboardSummary.fromRepository(librarian);
        expect(summary.reservedSeats, 1);
        expect(summary.availableSeats, 1);
        // The seat document itself is untouched (students cannot write seats).
        expect((await db.collection('seats').doc(seat.id).get()).data()!['status'], 'available');

        // A fresh librarian session (refresh) sees the same thing.
        final reopened = librarianRepo(db, storage);
        await settle();
        expect(reopened.seatMapStatus(reopened.seatById(seat.id)!), SeatStatus.reserved);
        reopened.dispose();

        // Cancelling frees it again.
        await student.cancelReservation(student.myReservations.single.id);
        await settle();
        expect(librarian.seatMapStatus(librarian.seatById(seat.id)!), SeatStatus.available);
      },
    );

    test('Reserved follows the booking time; Maintenance keeps priority', () async {
      final seat = await addSeat('A01');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await db.collection('reservations').add({
        'type': 'seat',
        'itemId': seat.id,
        'itemTitle': 'Seat A01',
        'studentUid': studentUid,
        'studentName': 'Nethmi Perera',
        'status': 'approved',
        'date': Timestamp.fromDate(today),
        'timeSlot': '09:00 - 11:00',
        'requestedAt': Timestamp.fromDate(now),
      });
      await settle();
      final saved = librarian.seatById(seat.id)!;
      DateTime at(int hour) => today.add(Duration(hours: hour));

      expect(librarian.seatMapStatus(saved, now: at(10)), SeatStatus.reserved);
      expect(librarian.seatMapStatus(saved, now: at(11)), SeatStatus.available); // ended
      expect(
        librarian.seatMapStatus(saved, now: at(10).add(const Duration(days: 1))),
        SeatStatus.available, // yesterday's booking
      );
      expect(
        librarian.seatMapStatus(saved.copyWith(status: SeatStatus.maintenance), now: at(10)),
        SeatStatus.maintenance,
      );
    });

    test('book reservations still wait for librarian approval', () async {
      await librarian.addBook(
        title: 'Refactoring',
        author: 'Martin Fowler',
        isbn: '9780134757599',
        category: 'Software Engineering',
        language: 'English',
        shelfLocation: 'SE-1',
        totalCopies: 2,
      );
      await settle();
      final result = await student.reserveBook(
        book: student.books.single,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      expect(result.success, isTrue, reason: result.message);
      await settle();
      expect(librarian.reservations.single.status, ReservationStatus.pending);
      expect(librarian.books.single.availableCopies, 2); // not taken yet
    });

    test('a student cannot hold two seats at the same time', () async {
      final seat = await addSeat('A01');
      final second = await addSeat('A02');
      await student.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 10,
        endHour: 12,
      );
      await settle();

      final clash = await student.bookSeat(
        seat: second,
        date: tomorrow(),
        startHour: 11,
        endHour: 13,
      );
      expect(clash.success, isFalse);
      expect(clash.message, contains('already have a seat booked'));
      expect((await db.collection('reservations').get()).docs, hasLength(1));
    });
    test('cancelling a booking frees the seat for others', () async {
      final seat = await addSeat('A01');
      final other = studentRepo(db, uid: otherStudentUid);
      await student.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 10,
        endHour: 12,
      );
      await settle();

      final booking = student.myReservations.single;
      expect((await student.cancelReservation(booking.id)).success, isTrue);
      await settle();
      expect(student.myReservations.single.status, ReservationStatus.cancelled);
      expect((await db.collection('seatSlots').get()).docs, isEmpty);

      final retry = await other.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 10,
        endHour: 12,
      );
      expect(retry.success, isTrue, reason: retry.message);
      other.dispose();
    });

    test('a seat under maintenance cannot be booked', () async {
      final seat = await addSeat('A01');
      await librarian.updateSeatStatus(seat.id, SeatStatus.maintenance);
      await settle();
      final result = await student.bookSeat(
        seat: student.seatById(seat.id)!,
        date: tomorrow(),
        startHour: 10,
        endHour: 11,
      );
      expect(result.success, isFalse);
      expect(result.message, contains('maintenance'));
    });

    test('a booking longer than the library allows is refused', () async {
      final seat = await addSeat('A01');
      final result = await student.bookSeat(
        seat: seat,
        date: tomorrow(),
        startHour: 9,
        endHour: 13,
      );
      expect(result.success, isFalse);
      expect(result.message, contains('at most 2 hours'));
    });
  });

  group('Book reservations and loans', () {
    test('approval is saved, sets a copy aside and students see it', () async {
      final book = await addCleanCode(copies: 2);
      final reserved = await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Main Desk',
      );
      expect(reserved.success, isTrue, reason: reserved.message);
      await settle();

      final pending = librarian.reservations.single;
      expect(pending.status, ReservationStatus.pending);
      expect(pending.studentId, 'IT23004512');
      expect(pending.studentUid, studentUid);
      expect(librarian.notifications.first.title, 'New Reservation Request');

      expect((await librarian.approveReservation(pending.id)).success, isTrue);
      await settle();
      expect(student.myReservations.single.status, ReservationStatus.approved);
      expect(student.bookById(book.id)!.availableCopies, 1);
    });

    test('a student cannot reserve the same book twice', () async {
      final book = await addCleanCode();
      await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Desk',
      );
      await settle();
      final again = await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Desk',
      );
      expect(again.success, isFalse);
      expect(again.message, contains('already have an active reservation'));
    });

    test('a deleted book cannot be reserved', () async {
      final book = await addCleanCode();
      await librarian.deleteBook(book.id);
      final result = await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Desk',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('no longer in the catalogue'));
    });

    test('collecting creates a loan; returning puts the copy back', () async {
      final book = await addCleanCode(copies: 1);
      await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 7,
        pickupLocation: 'Desk',
      );
      await settle();
      final id = librarian.reservations.single.id;
      await librarian.approveReservation(id);
      await settle();
      expect(librarian.bookById(book.id)!.availableCopies, 0);
      // The `available` flag the Student service reads follows the copies.
      expect(
        (await db.collection('books').doc(book.id).get()).data()!['available'],
        isFalse,
      );

      expect((await librarian.markReservationCollected(id)).success, isTrue);
      await settle();
      final loan = librarian.borrowings.single;
      expect(loan.memberId, 'IT23004512');
      expect(loan.dueDate.difference(loan.issuedAt).inDays, 7);
      expect(student.myReservations.single.status, ReservationStatus.collected);

      expect((await librarian.markBorrowingReturned(loan.id)).success, isTrue);
      await settle();
      expect(librarian.borrowings.single.isReturned, isTrue);
      // Returning from Borrowing Management closes the reservation too.
      expect(student.myReservations.single.status, ReservationStatus.returned);
      expect(student.bookById(book.id)!.availableCopies, 1);
      expect(
        (await db.collection('books').doc(book.id).get()).data()!['available'],
        isTrue,
      );
    });

    group('collection and return (librarian only)', () {
      /// A book reservation taken to Ready for Pickup (approved).
      Future<String> readyForPickup() async {
        final book = await addCleanCode(copies: 1);
        await student.reserveBook(
          book: book,
          pickupDate: tomorrow(),
          loanPeriodDays: 14,
          pickupLocation: 'Main Desk',
        );
        await settle();
        final id = librarian.reservations.single.id;
        expect(librarian.reservations.single.status, ReservationStatus.pending);
        expect((await librarian.approveReservation(id)).success, isTrue);
        await settle();
        return id;
      }

      Future<Map<String, dynamic>> doc(String id) async =>
          (await db.collection('reservations').doc(id).get()).data()!;

      test('Ready for Pickup -> Collected -> Returned on one reservation', () async {
        final id = await readyForPickup();
        expect(student.myReservations.single.status, ReservationStatus.approved);

        expect((await librarian.markReservationCollected(id)).success, isTrue);
        await settle();
        var data = await doc(id);
        expect(data['status'], 'collected');
        expect(data['collectedAt'], isA<Timestamp>());
        // Student and librarian read the same document.
        expect(student.myReservations.single.status, ReservationStatus.collected);
        expect(student.myReservations.single.collectedAt, isNotNull);
        expect(librarian.reservationById(id)!.status, ReservationStatus.collected);
        expect(librarian.borrowings.single.isReturned, isFalse);

        expect((await librarian.markReservationReturned(id)).success, isTrue);
        await settle();
        data = await doc(id);
        expect(data['status'], 'returned');
        expect(data['returnedAt'], isA<Timestamp>());
        expect(student.myReservations.single.status, ReservationStatus.returned);
        expect(student.myReservations.single.returnedAt, isNotNull);
        expect(librarian.reservationById(id)!.status, ReservationStatus.returned);
        // The loan is closed and the copy is back on the shelf.
        expect(librarian.borrowings.single.isReturned, isTrue);
        expect(librarian.books.single.availableCopies, 1);
        // One reservation document, no second status field.
        expect((await db.collection('reservations').get()).docs, hasLength(1));
        expect(data.containsKey('studentStatus'), isFalse);
        expect(data.containsKey('librarianStatus'), isFalse);
      });

      test('invalid transitions are refused and change nothing', () async {
        final book = await addCleanCode(copies: 1);
        await student.reserveBook(
          book: book,
          pickupDate: tomorrow(),
          loanPeriodDays: 14,
          pickupLocation: 'Main Desk',
        );
        await settle();
        final id = librarian.reservations.single.id;

        // Requested -> Collected / Returned.
        var result = await librarian.markReservationCollected(id);
        expect(result.success, isFalse);
        expect(result.message, contains('Only approved reservations'));
        result = await librarian.markReservationReturned(id);
        expect(result.success, isFalse);
        expect(result.message, contains('Only collected books'));
        expect((await doc(id))['status'], 'pending');

        // Ready for Pickup -> Returned.
        await librarian.approveReservation(id);
        await settle();
        result = await librarian.markReservationReturned(id);
        expect(result.success, isFalse);
        expect(result.message, contains('Only collected books'));
        expect((await doc(id))['status'], 'approved');

        // Returned -> Collected / Returned.
        await librarian.markReservationCollected(id);
        await settle();
        await librarian.markReservationReturned(id);
        await settle();
        result = await librarian.markReservationCollected(id);
        expect(result.success, isFalse);
        result = await librarian.markReservationReturned(id);
        expect(result.success, isFalse);
        expect(result.message, contains('already been returned'));
        expect((await doc(id))['status'], 'returned');
        expect(librarian.books.single.availableCopies, 1); // counted once
      });

      test('a missing reservation is reported, not thrown', () async {
        final result = await librarian.markReservationReturned('missing');
        expect(result.success, isFalse);
        expect(result.message, 'Reservation not found.');
      });

      test('older collected reservations (`completed`) read as Collected', () async {
        final id = await readyForPickup();
        await librarian.markReservationCollected(id);
        await settle();
        // As saved before the Collected status existed.
        await db.collection('reservations').doc(id).update({'status': 'completed'});
        await settle();
        expect(student.myReservations.single.status, ReservationStatus.collected);
        expect((await librarian.markReservationReturned(id)).success, isTrue);
        await settle();
        expect(student.myReservations.single.status, ReservationStatus.returned);
      });

      test('students cannot mark a book collected or returned', () async {
        final id = await readyForPickup();
        // The only student action on an approved book is refused.
        final cancel = await student.cancelReservation(id);
        expect(cancel.success, isFalse);
        expect((await doc(id))['status'], 'approved');
      });
    });

    test('a suspended member cannot reserve', () async {
      final book = await addCleanCode();
      final member = librarian.memberById('IT23004512')!;
      expect(member.uid, studentUid);
      expect(
        (await librarian.updateMemberStatus(
          member.id,
          MemberStatus.suspended,
        )).success,
        isTrue,
      );

      final result = await student.reserveBook(
        book: book,
        pickupDate: tomorrow(),
        loanPeriodDays: 14,
        pickupLocation: 'Desk',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('suspended'));
      // Only the status changed, never the role.
      final user = (await db.collection('users').doc(studentUid).get()).data()!;
      expect(user['role'], 'student');
      expect(user['accountStatus'], 'suspended');
    });
  });

  group('Firebase errors', () {
    test('a refused write is reported, not shown as success', () async {
      final seat = await addSeat('A01');
      whenCalling(Invocation.method(#update, null))
          .on(db.collection('seats').doc(seat.id))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );

      final result = await librarian.updateSeatStatus(
        seat.id,
        SeatStatus.maintenance,
      );
      await settle();

      expect(result.success, isFalse);
      expect(result.message, contains('do not have permission'));
      expect(librarian.seatById(seat.id)!.status, SeatStatus.available);
    });
  });
}
