import 'package:flutter/material.dart';

import '../models/borrowing_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import 'book_cover.dart';
import 'librarian_accent_card.dart';
import 'status_chip.dart';

/// One loan in Borrowing Management, styled like the reservation cards:
/// book, member, loan ID / ISBN, dates and status, plus quick actions.
class BorrowingCard extends StatelessWidget {
  const BorrowingCard({
    super.key,
    required this.loan,
    required this.onTap,
    this.onReturn,
    this.onRenew,
  });

  final BorrowingRecord loan;
  final VoidCallback onTap;

  /// Null hides the button (e.g. for returned loans).
  final VoidCallback? onReturn;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = loan.status;
    final dates = loan.isReturned
        ? 'Issued ${LibrarianFormatters.date(loan.issuedAt)} · Returned ${LibrarianFormatters.date(loan.returnedAt!)}'
        : 'Issued ${LibrarianFormatters.date(loan.issuedAt)} · Due ${LibrarianFormatters.date(loan.dueDate)}';

    return LibrarianAccentCard(
      accentColor: StatusChip.borrowingColor(status),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(title: loan.bookTitle, width: 44, height: 60),
              const SizedBox(width: LibrarianSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loan.memberName} · ${loan.memberId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: LibrarianColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loan.id} · ISBN ${loan.isbn}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LibrarianSpacing.sm),
              StatusChip.borrowing(status),
            ],
          ),
          const SizedBox(height: LibrarianSpacing.sm),
          Text(
            loan.daysOverdue > 0
                ? '$dates · ${loan.daysOverdue} ${loan.daysOverdue == 1 ? 'day' : 'days'} overdue'
                : dates,
            style: textTheme.bodySmall?.copyWith(
              color: loan.daysOverdue > 0 ? LibrarianColors.unavailable : null,
            ),
          ),
          if (onReturn != null || onRenew != null)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: LibrarianSpacing.xs,
                children: [
                  if (onRenew != null)
                    TextButton.icon(
                      onPressed: onRenew,
                      icon: const Icon(Icons.autorenew, size: 18),
                      label: const Text('Renew'),
                    ),
                  if (onReturn != null)
                    TextButton.icon(
                      onPressed: onReturn,
                      icon: const Icon(Icons.assignment_return_outlined, size: 18),
                      label: const Text('Mark Returned'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
