import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/book_record.dart';
import '../models/reservation_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/book_summary_card.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/reservation_actions_card.dart';
import '../widgets/reservation_detail_sections.dart';
import '../widgets/reservation_status_banner.dart';
import '../widgets/status_chip.dart';

/// Book Reservation Details (Figma): book summary, reservation info,
/// student info, notes and the Approve / Reject actions.
class BookReservationDetailsScreen extends StatelessWidget {
  const BookReservationDetailsScreen({
    super.key,
    required this.reservation,
    required this.book,
    this.blocker,
    this.onBack,
  });

  final ReservationRecord reservation;

  /// Null if the book was removed from the catalogue.
  final BookRecord? book;
  final String? blocker;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final pickup = [
      LibrarianFormatters.date(reservation.date),
      if (reservation.timeSlot != null)
        LibrarianFormatters.startTime(reservation.timeSlot!),
    ].join(' · ');

    return LibrarianPage(
      maxWidth: 760,
      children: [
        LibrarianPageHeader(
          title: 'Book Reservation Details',
          subtitle: 'Reservation / Books',
          trailing: StatusChip.forReservation(reservation),
          onBack: onBack,
        ),
        ReservationReference(reservationId: reservation.id),
        ReservationStatusBanner(reservation: reservation, blocker: blocker),
        BookSummaryCard(
          book: book,
          fallbackTitle: reservation.itemName,
          // The cover of the book this reservation is for.
          coverAsset: book?.coverAsset,
        ),
        InfoSectionCard(
          title: 'Reservation Info',
          children: [
            InfoGrid(
              items: [
                const InfoItem('Type', 'Book Reservation'),
                InfoItem(
                  'Status',
                  StatusChip.reservationLabel(reservation),
                  valueColor: StatusChip.reservationColor(reservation.status),
                ),
                InfoItem('Reserved On', LibrarianFormatters.date(reservation.requestedAt)),
                InfoItem('Pickup By', pickup),
                if (reservation.collectedAt != null)
                  InfoItem('Collected On', LibrarianFormatters.date(reservation.collectedAt!)),
                if (reservation.returnedAt != null)
                  InfoItem('Returned On', LibrarianFormatters.date(reservation.returnedAt!)),
                if (book != null)
                  InfoItem(
                    'Copies Available',
                    '${book!.availableCopies} of ${book!.totalCopies}',
                    valueColor: book!.isAvailable ? null : LibrarianColors.unavailable,
                  ),
              ],
            ),
          ],
        ),
        StudentInfoCard.fromReservation(
          reservation,
          onViewMember: () =>
              context.go(LibrarianRoutes.memberDetails(reservation.studentId)),
        ),
        AdditionalInfoCard(note: reservation.note),
        ReservationActionsCard(reservation: reservation),
      ],
    );
  }
}
