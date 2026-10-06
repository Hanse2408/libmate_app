import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import 'info_section_card.dart';
import 'reject_reason_dialog.dart';

/// "Actions" card with Approve / Reject, shown only for pending reservations
/// (decided reservations cannot be approved or rejected again). Approved book
/// reservations instead offer "Mark as Collected", which creates the loan.
///
/// The repository decides whether the action is allowed. On success the
/// librarian is taken to the Booking Confirmation screen; if approval is
/// refused (no copies / seat unavailable) a dialog explains why and the
/// reservation stays pending.
class ReservationActionsCard extends StatelessWidget {
  const ReservationActionsCard({super.key, required this.reservation});

  final ReservationRecord reservation;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w700);
    if (reservation.status == ReservationStatus.approved &&
        reservation.type == ReservationType.book) {
      return InfoSectionCard(
        title: 'Actions',
        children: [
          FilledButton.icon(
            onPressed: () => _collect(context),
            icon: const Icon(Icons.outbox_outlined),
            label: const Text('Mark as Collected'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              textStyle: textStyle,
            ),
          ),
          const SizedBox(height: LibrarianSpacing.sm),
          Text(
            'Use this when the student picks up the book. A loan is created '
            'in Borrowing Management with the due date.',
            style: TextStyle(color: LibrarianColors.secondaryText),
          ),
        ],
      );
    }
    if (!reservation.isPending) return const SizedBox.shrink();

    return InfoSectionCard(
      title: 'Actions',
      children: [
        FilledButton(
          onPressed: () => _approve(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            textStyle: textStyle,
          ),
          child: const Text('Approve Reservation'),
        ),
        const SizedBox(height: LibrarianSpacing.md),
        FilledButton(
          onPressed: () => _reject(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            backgroundColor: Color.lerp(
              LibrarianColors.unavailable,
              LibrarianColors.text,
              0.12,
            ),
            textStyle: textStyle,
          ),
          child: const Text('Reject Reservation'),
        ),
      ],
    );
  }

  Future<void> _collect(BuildContext context) async {
    final repository = LibrarianScope.read(context).repository;
    final result = await repository.markReservationCollected(reservation.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '"${reservation.itemName}" is now on loan to ${reservation.studentName}.'
                : result.message!,
          ),
        ),
      );
  }

  Future<void> _approve(BuildContext context) async {
    final repository = LibrarianScope.read(context).repository;
    final result = await repository.approveReservation(reservation.id);
    if (!context.mounted) return;

    if (result.success) {
      context.go(LibrarianRoutes.reservationConfirmation(reservation.id));
    } else {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: LibrarianColors.unavailable,
            size: 36,
          ),
          title: const Text('Cannot approve yet'),
          content: Text(result.message!),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final repository = LibrarianScope.read(context).repository;
    final reason = await showRejectReasonDialog(context, reservation);
    if (reason == null || !context.mounted) return;

    final result = await repository.rejectReservation(reservation.id, reason);
    if (!context.mounted) return;

    if (result.success) {
      context.go(LibrarianRoutes.reservationConfirmation(reservation.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }
}
