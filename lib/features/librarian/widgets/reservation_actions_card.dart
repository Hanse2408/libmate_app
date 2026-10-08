import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/action_result.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import 'info_section_card.dart';
import 'reject_reason_dialog.dart';

/// "Actions" card for a reservation, following the book journey
/// Requested -> Ready for Pickup -> Collected -> Returned:
/// * pending: Approve / Reject (decided reservations cannot be decided again);
/// * approved book (Ready for Pickup): "Mark as Collected", which creates the
///   loan;
/// * collected book: "Mark as Returned", which closes the loan;
/// * returned book: shows "Returned" with no further action.
///
/// Collected / Returned are confirmed first and the button is disabled while
/// the update runs. The repository decides whether the action is allowed. On
/// approval the librarian is taken to the Booking Confirmation screen; if
/// approval is refused (no copies / seat unavailable) a dialog explains why
/// and the reservation stays pending.
class ReservationActionsCard extends StatefulWidget {
  const ReservationActionsCard({super.key, required this.reservation});

  final ReservationRecord reservation;

  @override
  State<ReservationActionsCard> createState() => _ReservationActionsCardState();
}

class _ReservationActionsCardState extends State<ReservationActionsCard> {
  /// A Collected / Returned update is running (prevents a double tap).
  bool _busy = false;

  ReservationRecord get reservation => widget.reservation;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w700);
    final isBook = reservation.type == ReservationType.book;
    if (isBook && reservation.status == ReservationStatus.approved) {
      return _stepCard(
        label: 'Mark as Collected',
        icon: Icons.outbox_outlined,
        help: 'Use this when the student picks up the book. A loan is created '
            'in Borrowing Management with the due date.',
        onPressed: _collect,
        textStyle: textStyle,
      );
    }
    if (isBook && reservation.isCollected) {
      return _stepCard(
        label: 'Mark as Returned',
        icon: Icons.assignment_return_outlined,
        help: 'Use this when the student brings the book back. The loan is '
            'closed and the copy is available again.',
        onPressed: _return,
        textStyle: textStyle,
      );
    }
    if (isBook && reservation.isReturned) {
      return InfoSectionCard(
        title: 'Actions',
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: LibrarianColors.secondaryText),
              const SizedBox(width: LibrarianSpacing.sm),
              Text(
                'Returned',
                key: const ValueKey('reservation-returned-label'),
                style: TextStyle(
                  color: LibrarianColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: LibrarianSpacing.sm),
          Text(
            'The book is back in the library. No further action is needed.',
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

  Widget _stepCard({
    required String label,
    required IconData icon,
    required String help,
    required Future<void> Function() onPressed,
    required TextStyle textStyle,
  }) {
    return InfoSectionCard(
      title: 'Actions',
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : onPressed,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            textStyle: textStyle,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.sm),
        Text(help, style: TextStyle(color: LibrarianColors.secondaryText)),
      ],
    );
  }

  /// Yes / No confirmation before a Collected / Returned update.
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Runs a status update once, with the button disabled meanwhile, and
  /// reports the result (or the reason it was refused / failed).
  Future<void> _runStep(
    Future<ActionResult> Function() action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(result.success ? successMessage : result.message!)),
      );
  }

  Future<void> _collect() async {
    final ok = await _confirm(
      title: 'Mark as Collected?',
      message: 'Has the student collected "${reservation.itemName}"?',
      confirmLabel: 'Yes, Collected',
    );
    if (!ok || !mounted) return;
    final repository = LibrarianScope.read(context).repository;
    await _runStep(
      () => repository.markReservationCollected(reservation.id),
      '"${reservation.itemName}" is now on loan to ${reservation.studentName}.',
    );
  }

  Future<void> _return() async {
    final ok = await _confirm(
      title: 'Mark as Returned?',
      message: 'Has the student returned "${reservation.itemName}"?',
      confirmLabel: 'Yes, Returned',
    );
    if (!ok || !mounted) return;
    final repository = LibrarianScope.read(context).repository;
    await _runStep(
      () => repository.markReservationReturned(reservation.id),
      '"${reservation.itemName}" was returned by ${reservation.studentName}.',
    );
  }

  Future<void> _approve(BuildContext context) async {
    final repository = LibrarianScope.read(context).repository;
    final result = await repository.approveReservation(reservation.id);
    if (!context.mounted) return;

    if (result.success) {
      context.go(
        LibrarianRoutes.reservationConfirmation(reservation.id),
        extra: ReservationStatus.approved,
      );
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
      context.go(
        LibrarianRoutes.reservationConfirmation(reservation.id),
        extra: ReservationStatus.rejected,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }
}
