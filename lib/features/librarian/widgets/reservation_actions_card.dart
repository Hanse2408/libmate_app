import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import 'info_section_card.dart';
import 'reject_reason_dialog.dart';

/// "Actions" card with Approve / Reject, shown only for pending reservations
/// (decided reservations cannot be approved or rejected again).
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
    if (!reservation.isPending) return const SizedBox.shrink();

    const textStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w700);
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
          icon: const Icon(
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
