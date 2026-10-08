import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/borrowing_record.dart';
import '../models/librarian_settings.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/book_summary_card.dart';
import '../widgets/borrowing_actions.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_message_banner.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/reservation_detail_sections.dart';
import '../widgets/status_chip.dart';

/// Details of one loan: status banner, book, member, dates and actions.
class BorrowingDetailsScreen extends StatelessWidget {
  const BorrowingDetailsScreen({super.key, required this.loanId, this.backTo});

  final String loanId;

  /// Where the back button goes, e.g. Member Details. Null = previous page.
  final String? backTo;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final loan = repository.borrowingById(loanId);
        final onBack = backTo == null ? null : () => context.go(backTo!);

        if (loan == null) {
          return LibrarianPage(
            maxWidth: 760,
            children: [
              LibrarianPageHeader(title: 'Borrowing Details', onBack: onBack),
              const LibrarianEmptyState(icon: Icons.search_off, title: 'Loan not found'),
            ],
          );
        }

        final member = repository.memberById(loan.memberId);
        final renewBlocker = repository.renewBlocker(loan);

        return LibrarianPage(
          maxWidth: 760,
          children: [
            LibrarianPageHeader(
              title: 'Borrowing Details',
              subtitle: 'Borrowing / Books',
              trailing: StatusChip.borrowing(loan.status),
              onBack: onBack,
            ),
            ReservationReference(reservationId: loan.id, isReservation: false),
            _StatusBanner(loan: loan),
            BookSummaryCard(
              book: repository.bookById(loan.bookId),
              fallbackTitle: loan.bookTitle,
              fallbackIsbn: loan.isbn,
            ),
            StudentInfoCard(
              title: 'Member Information',
              name: loan.memberName,
              studentId: loan.memberId,
              email: member?.email ?? '-',
              onViewMember: member == null
                  ? null
                  : () => context.go(LibrarianRoutes.memberDetails(member.id)),
            ),
            InfoSectionCard(
              title: 'Loan Information',
              children: [
                InfoGrid(
                  items: [
                    InfoItem('Issue Date', LibrarianFormatters.date(loan.issuedAt)),
                    InfoItem('Due Date', LibrarianFormatters.date(loan.dueDate)),
                    if (loan.isReturned)
                      InfoItem('Return Date', LibrarianFormatters.date(loan.returnedAt!)),
                    InfoItem(
                      'Status',
                      loan.status.label,
                      valueColor: StatusChip.borrowingColor(loan.status),
                    ),
                    InfoItem('Renewals', '${loan.renewals} of ${LibrarianSettings.maxRenewals}'),
                    if (loan.daysOverdue > 0)
                      InfoItem(
                        'Days Overdue',
                        '${loan.daysOverdue}',
                        valueColor: LibrarianColors.unavailable,
                      ),
                  ],
                ),
              ],
            ),
            if (!loan.isReturned)
              InfoSectionCard(
                title: 'Actions',
                children: [
                  FilledButton(
                    onPressed: () => BorrowingActions.markReturned(context, loan),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Mark as Returned'),
                  ),
                  const SizedBox(height: LibrarianSpacing.md),
                  OutlinedButton(
                    onPressed: renewBlocker == null
                        ? () => BorrowingActions.renew(context, loan)
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Renew Loan'),
                  ),
                  if (renewBlocker != null)
                    Padding(
                      padding: const EdgeInsets.only(top: LibrarianSpacing.sm),
                      child: Text(
                        renewBlocker,
                        style: TextStyle(color: LibrarianColors.secondaryText),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.loan});

  final BorrowingRecord loan;

  @override
  Widget build(BuildContext context) {
    final due = LibrarianFormatters.date(loan.dueDate);
    final now = DateTime.now();
    final daysLeft = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    final (title, message, color, icon) = switch (loan.status) {
      BorrowingStatus.overdue => (
        'Overdue',
        'This book was due on $due and is ${loan.daysOverdue} '
            '${loan.daysOverdue == 1 ? 'day' : 'days'} overdue. Please contact the member.',
        LibrarianColors.unavailable,
        Icons.warning_amber_rounded,
      ),
      BorrowingStatus.dueToday => (
        'Due Today',
        'This book should be returned today ($due).',
        LibrarianColors.gold,
        Icons.schedule,
      ),
      BorrowingStatus.active => (
        'On Loan',
        'Due in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}, on $due.',
        LibrarianColors.available,
        Icons.check_circle_outline,
      ),
      BorrowingStatus.returned => (
        'Returned',
        'Returned on ${LibrarianFormatters.date(loan.returnedAt!)}.',
        LibrarianColors.primary,
        Icons.assignment_turned_in_outlined,
      ),
    };

    return LibrarianMessageBanner(title: title, message: message, color: color, icon: icon);
  }
}
