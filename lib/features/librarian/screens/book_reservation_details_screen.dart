import 'package:flutter/material.dart';

import '../models/book_record.dart';
import '../models/reservation_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/book_cover.dart';
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
          trailing: StatusChip.reservation(reservation.status),
          onBack: onBack,
        ),
        ReservationReference(reservationId: reservation.id),
        ReservationStatusBanner(reservation: reservation, blocker: blocker),
        _BookSummaryCard(book: book, fallbackTitle: reservation.itemName),
        InfoSectionCard(
          title: 'Reservation Info',
          children: [
            InfoGrid(
              items: [
                const InfoItem('Type', 'Book Reservation'),
                InfoItem(
                  'Status',
                  reservation.status.label,
                  valueColor: StatusChip.reservationColor(reservation.status),
                ),
                InfoItem('Reserved On', LibrarianFormatters.date(reservation.requestedAt)),
                InfoItem('Pickup By', pickup),
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
        StudentInfoCard(reservation: reservation),
        AdditionalInfoCard(note: reservation.note),
        ReservationActionsCard(reservation: reservation),
      ],
    );
  }
}

class _BookSummaryCard extends StatelessWidget {
  const _BookSummaryCard({required this.book, required this.fallbackTitle});

  final BookRecord? book;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final title = book?.title ?? fallbackTitle;

    return InfoSectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(title: title, width: 92, height: 124),
            const SizedBox(width: LibrarianSpacing.md + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LibrarianColors.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (book != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      book!.author,
                      style: const TextStyle(
                        color: LibrarianColors.secondaryText,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: LibrarianSpacing.sm + 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: LibrarianColors.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        book!.category,
                        style: const TextStyle(
                          color: LibrarianColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: LibrarianSpacing.sm + 4),
                    Text(
                      'ISBN: ${book!.isbn}',
                      style: const TextStyle(color: LibrarianColors.secondaryText),
                    ),
                  ] else
                    const Text(
                      'This book is no longer in the catalogue.',
                      style: TextStyle(color: LibrarianColors.unavailable),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
