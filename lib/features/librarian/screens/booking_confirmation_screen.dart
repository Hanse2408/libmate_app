import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/status_chip.dart';

/// Shown after a reservation is approved or rejected. Works for both book
/// and seat reservations and reads the real status from the repository,
/// rebuilding when it changes.
///
/// Approval / rejection runs as a Firestore transaction; its result reaches
/// the repository's live list a moment after the transaction completes.
/// [decision] (passed by Approve / Reject) lets the screen show "Updating…"
/// for that moment instead of "No decision yet".
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.reservationId,
    this.decision,
  });

  final String reservationId;

  /// The decision the librarian just saved, if they came from Approve /
  /// Reject (the stored status is still what is shown).
  final ReservationStatus? decision;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;
    final reservation = repository.reservationById(reservationId);
    void backToReservations() => context.go(LibrarianRoutes.reservations);

    final header = LibrarianPageHeader(
      title: 'Booking Confirmation',
      onBack: backToReservations,
    );

    // Just decided, but the live list has not caught up yet.
    final waitingForUpdate =
        decision != null && (reservation == null || reservation.isPending);
    if (waitingForUpdate) {
      return LibrarianPage(
        maxWidth: 760,
        children: [
          header,
          const SizedBox(height: LibrarianSpacing.lg * 2),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: LibrarianSpacing.md),
          Text(
            'Updating reservation…',
            key: const ValueKey('confirmation-updating'),
            textAlign: TextAlign.center,
            style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
          ),
        ],
      );
    }

    if (reservation != null &&
        reservation.status == ReservationStatus.cancelled) {
      return LibrarianPage(
        maxWidth: 760,
        children: [
          header,
          const LibrarianEmptyState(
            icon: Icons.event_busy,
            title: 'Reservation cancelled',
            message: 'The student cancelled this reservation.',
          ),
          Center(
            child: TextButton(
              onPressed: () =>
                  context.go(LibrarianRoutes.reservationDetails(reservationId)),
              child: const Text('Open reservation'),
            ),
          ),
        ],
      );
    }

    if (reservation == null || reservation.isPending) {
      return LibrarianPage(
        maxWidth: 760,
        children: [
          header,
          const LibrarianEmptyState(
            icon: Icons.hourglass_empty,
            title: 'No decision yet',
            message: 'This reservation has not been approved or rejected.',
          ),
          if (reservation != null)
            Center(
              child: TextButton(
                onPressed: () =>
                    context.go(LibrarianRoutes.reservationDetails(reservationId)),
                child: const Text('Open reservation'),
              ),
            ),
        ],
      );
    }

    // Approved, and the later book steps (Collected / Returned), show the
    // approval; only a rejected reservation shows the rejection.
    final approved = reservation.status != ReservationStatus.rejected;
    final isBook = reservation.type == ReservationType.book;

    return LibrarianPage(
      maxWidth: 760,
      children: [
        header,
        _ResultIcon(approved: approved),
        const SizedBox(height: LibrarianSpacing.lg),
        Text(
          approved ? 'Reservation Approved!' : 'Reservation Rejected',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LibrarianColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.sm),
        Text(
          _subtitle(reservation, approved: approved, isBook: isBook),
          textAlign: TextAlign.center,
          style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
        ),
        const SizedBox(height: LibrarianSpacing.lg),
        InfoSectionCard(
          title: approved ? 'Approval Summary' : 'Rejection Summary',
          borderColor: (approved ? LibrarianColors.gold : LibrarianColors.unavailable)
              .withValues(alpha: 0.6),
          children: [
            const Divider(height: 1),
            const SizedBox(height: LibrarianSpacing.sm),
            for (final (icon, label, value) in _summaryRows(
              reservation,
              approved,
              repository.settings.loanPeriodDays,
            ))
              _SummaryRow(
                icon: icon,
                label: label,
                value: value,
                highlight: label == 'Reference No',
              ),
          ],
        ),
        _InfoNote(
          text: approved
              ? (isBook
                    ? 'The student will receive a notification to collect the book from the front desk.'
                    : 'The student will receive a notification with their seat and time slot.')
              : 'The student will be notified that the request was rejected, with the reason.',
        ),
        const SizedBox(height: LibrarianSpacing.lg),
        FilledButton(
          onPressed: backToReservations,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 60),
            textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          child: const Text('Back to Reservations'),
        ),
        const SizedBox(height: LibrarianSpacing.md),
        OutlinedButton(
          onPressed: () => context.go(LibrarianRoutes.dashboard),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 60),
            foregroundColor: LibrarianColors.text,
            side: BorderSide(
              color: LibrarianColors.gold.withValues(alpha: 0.6),
              width: 1.5,
            ),
            textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
          ),
          child: const Text('Back to Home'),
        ),
        const SizedBox(height: LibrarianSpacing.sm),
        TextButton(
          onPressed: () =>
              context.go(LibrarianRoutes.reservationDetails(reservationId)),
          child: const Text('View Reservation'),
        ),
      ],
    );
  }

  static String _subtitle(
    ReservationRecord r, {
    required bool approved,
    required bool isBook,
  }) {
    if (!approved) return 'The request was rejected and the student will be informed.';
    if (r.isCollected) return 'The student has collected the book.';
    if (r.isReturned) return 'The student has returned the book.';
    return isBook
        ? 'The student has been notified and can pick up the book on the selected date.'
        : 'The student has been notified and can use the seat at the booked time.';
  }

  static List<(IconData, String, String)> _summaryRows(
    ReservationRecord r,
    bool approved,
    int loanDays,
  ) {
    final date = LibrarianFormatters.date(r.date);
    return [
      if (r.type == ReservationType.book) ...[
        (Icons.menu_book_outlined, 'Book Title', r.itemName),
        (Icons.calendar_today_outlined, 'Pickup By', date),
        if (approved)
          (Icons.schedule, 'Period', '$loanDays Days'),
      ] else ...[
        (Icons.chair_outlined, 'Seat', r.itemName),
        (Icons.calendar_today_outlined, 'Date', date),
        if (r.timeSlot != null)
          (Icons.schedule, 'Time Slot', LibrarianFormatters.timeRange(r.timeSlot!)),
      ],
      (Icons.person_outline, 'Student', r.studentName),
      // Ready for Pickup / Collected / Returned for books.
      if (approved && r.type == ReservationType.book)
        (Icons.flag_outlined, 'Status', StatusChip.reservationLabel(r)),
      if (!approved) (Icons.block, 'Reason', r.rejectionReason ?? '-'),
      (Icons.receipt_long_outlined, 'Reference No', r.displayReference),
    ];
  }
}

/// Green tick with a few confetti dots (approved) or a red cross (rejected).
class _ResultIcon extends StatelessWidget {
  const _ResultIcon({required this.approved});

  final bool approved;

  @override
  Widget build(BuildContext context) {
    Widget dot(double left, double top, Color color, double size) => Positioned(
      left: left,
      top: top,
      child: CircleAvatar(radius: size / 2, backgroundColor: color),
    );

    return Center(
      child: SizedBox(
        width: 220,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (approved) ...[
              // Confetti uses the agreed palette at different strengths.
              dot(20, 70, LibrarianColors.gold, 22),
              dot(60, 135, LibrarianColors.unavailable.withValues(alpha: 0.5), 12),
              dot(140, 0, LibrarianColors.gold.withValues(alpha: 0.7), 22),
              dot(190, 60, LibrarianColors.unavailable.withValues(alpha: 0.6), 22),
              dot(165, 150, LibrarianColors.primary, 20),
              dot(45, 10, LibrarianColors.primary.withValues(alpha: 0.4), 16),
            ],
            CircleAvatar(
              radius: 72,
              backgroundColor: approved
                  ? LibrarianColors.available
                  : LibrarianColors.unavailable,
              child: Icon(
                approved ? Icons.check_rounded : Icons.close_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LibrarianSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LibrarianColors.text),
          const SizedBox(width: LibrarianSpacing.md),
          Text(
            label,
            style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
          ),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight ? LibrarianColors.primary : LibrarianColors.text,
                fontSize: 17,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LibrarianSpacing.md + 4),
      decoration: BoxDecoration(
        color: LibrarianColors.lightBlue,
        borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
        border: Border.all(color: LibrarianColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: LibrarianColors.primary),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Text(text, style: TextStyle(color: LibrarianColors.text)),
          ),
        ],
      ),
    );
  }
}
