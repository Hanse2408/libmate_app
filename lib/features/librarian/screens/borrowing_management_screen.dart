import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/borrowing_record.dart';
import '../providers/borrowing_filter.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/borrowing_actions.dart';
import '../widgets/borrowing_card.dart';
import '../widgets/count_tile.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_search_field.dart';
import '../widgets/librarian_tab_chip.dart';
import '../widgets/status_chip.dart';

/// Borrowing (circulation) management: loan counts, search, status tabs and
/// the list of loans with Renew / Mark Returned actions.
class BorrowingManagementScreen extends StatefulWidget {
  const BorrowingManagementScreen({super.key, this.initialStatus});

  /// Opens on a tab, e.g. Overdue from the Dashboard alert.
  final BorrowingStatus? initialStatus;

  @override
  State<BorrowingManagementScreen> createState() => _BorrowingManagementScreenState();
}

class _BorrowingManagementScreenState extends State<BorrowingManagementScreen> {
  String _query = '';
  late BorrowingStatus? _status = widget.initialStatus;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final loans = repository.borrowings;
        final counts = BorrowingFilter.countByStatus(loans);
        final results = BorrowingFilter(query: _query, status: _status).apply(loans);

        return LibrarianPage(
          children: [
            const LibrarianPageHeader(
              title: 'Borrowing Management',
              subtitle: 'Track loans, returns, renewals and overdue books.',
            ),
            ResponsiveGrid(
              minItemWidth: 140,
              children: [
                for (final status in BorrowingStatus.values)
                  CountTile(
                    label: status == BorrowingStatus.active ? 'Active Loans' : status.label,
                    count: counts[status]!,
                    color: StatusChip.borrowingColor(status),
                    onTap: () => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            LibrarianSearchField(
              hint: 'Search member, ID, book or ISBN',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: LibrarianSpacing.md),
            LibrarianTabChipBar(
              chips: [
                LibrarianTabChip(
                  label: 'All',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                for (final status in BorrowingStatus.values)
                  LibrarianTabChip(
                    label: status.label,
                    selected: _status == status,
                    onTap: () => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            Text(
              '${results.length.toString().padLeft(2, '0')} '
              '${results.length == 1 ? 'loan' : 'loans'} found',
              style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
            ),
            const SizedBox(height: LibrarianSpacing.sm + 4),
            if (results.isEmpty)
              LibrarianEmptyState(
                icon: _query.trim().isEmpty ? Icons.library_books_outlined : Icons.search_off,
                title: _query.trim().isEmpty
                    ? 'No loans in this list'
                    : 'No results for "${_query.trim()}"',
                message: _query.trim().isEmpty
                    ? null
                    : 'Try a member name, student ID, loan ID, book title or ISBN.',
              )
            else
              for (final loan in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
                  child: BorrowingCard(
                    loan: loan,
                    onTap: () => context.go(LibrarianRoutes.borrowingDetails(loan.id)),
                    onReturn: loan.isReturned
                        ? null
                        : () => BorrowingActions.markReturned(context, loan),
                    onRenew: repository.renewBlocker(loan) == null
                        ? () => BorrowingActions.renew(context, loan)
                        : null,
                  ),
                ),
          ],
        );
      },
    );
  }
}
