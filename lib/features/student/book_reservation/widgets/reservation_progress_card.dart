import 'package:flutter/material.dart';
import '../../../../models/reservation.dart';
import '../../../../models/reservation_loan_progress.dart';

/// A real status tracker, rather than a time estimate or completion percentage.
class ReservationProgressCard extends StatelessWidget {
  const ReservationProgressCard({super.key, required this.reservation, this.loan});
  final ReservationRecord reservation;
  final ReservationLoanProgress? loan;

  int get _stage {
    if (loan?.returnedAt != null) return 3;
    if (loan != null || reservation.status == ReservationStatus.completed) return 2;
    if (reservation.status == ReservationStatus.approved) return 1;
    return 0;
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rejected = reservation.status == ReservationStatus.rejected;
    final stopped = rejected || reservation.status == ReservationStatus.cancelled;
    final stage = _stage;
    const labels = ['Requested', 'Ready for\nPickup', 'Collected', 'Returned'];
    const icons = [Icons.send_rounded, Icons.inventory_2_rounded,
      Icons.auto_stories_rounded, Icons.assignment_turned_in_rounded];
    final messages = [
      'Your request is with the librarian.',
      'Your book is ready! Collect at your pickup location.',
      'Enjoy your book! Waiting for its return.',
      'Book returned${loan?.returnedAt == null ? '' : ' on ${_date(loan!.returnedAt!)}'}. Reading journey complete.',
    ];
    final statusColor = rejected ? const Color(0xFFDC4C4C) : colors.onSurfaceVariant;
    return Container(
      key: const ValueKey('reservation-progress-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.route_rounded, color: Color(0xFFF2B84B), size: 20),
          const SizedBox(width: 9),
          Expanded(child: Text('Your book journey', style: TextStyle(
            color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        if (stopped) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(rejected ? Icons.cancel_outlined : Icons.event_busy_rounded, color: statusColor),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rejected ? 'Reservation rejected' : 'Reservation cancelled',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(rejected
                ? (reservation.rejectionReason?.trim().isNotEmpty == true
                  ? reservation.rejectionReason! : 'The librarian did not approve this request.')
                : 'This request has ended. You can make a new reservation when you are ready.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5, fontSize: 13)),
            ])),
          ]),
        ] else ...[
          Semantics(label: 'Reservation progress: ${labels[stage].replaceAll('\n', ' ')}. Step ${stage + 1} of 4.',
            child: Column(children: [
              Row(children: [
                for (int i = 0; i < 4; i++) ...[
                  if (i > 0) Expanded(child: Container(height: 3,
                    color: i <= stage ? colors.primary : colors.onSurface.withValues(alpha: .1))),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: i <= stage ? colors.primary : colors.onSurface.withValues(alpha: .06),
                      border: Border.all(color: i == stage ? const Color(0xFFF2B84B) : Colors.transparent, width: 2),
                      boxShadow: i == stage ? [BoxShadow(color: colors.primary.withValues(alpha: .2), blurRadius: 10)] : null),
                    child: Icon(i < stage ? Icons.check_rounded : icons[i], size: 14,
                      color: i <= stage ? colors.onPrimary : colors.onSurfaceVariant),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (int i = 0; i < 4; i++) Expanded(child: Text(labels[i], textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, height: 1.25,
                    fontWeight: i == stage ? FontWeight.w800 : FontWeight.w500,
                    color: i <= stage ? colors.primary : colors.onSurfaceVariant))),
              ]),
            ])),
          const SizedBox(height: 8),
          Text(messages[stage], key: const ValueKey('reservation-progress-message'),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, height: 1.35)),
        ],
      ]),
    );
  }
}
