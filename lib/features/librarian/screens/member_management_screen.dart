import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../providers/librarian_scope.dart';
import '../providers/member_filter.dart';
import '../theme/librarian_theme.dart';
import '../widgets/count_tile.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/filter_pill.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_search_field.dart';
import '../widgets/member_card.dart';

/// Member Management: member counts, search, status filter and member list.
class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  String _query = '';
  MemberFilterOption _option = MemberFilterOption.all;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final members = repository.members;
        final results = MemberFilter(query: _query, option: _option).apply(repository);
        final activeCount = members.where((m) => m.isActive).length;
        final overdueCount = members.where((m) => repository.overdueLoanCount(m.id) > 0).length;

        return LibrarianPage(
          children: [
            const LibrarianPageHeader(
              title: 'Member Management',
              subtitle: 'View library members, their loans and reservations.',
            ),
            ResponsiveGrid(
              minItemWidth: 100,
              children: [
                CountTile(
                  label: 'Total Members',
                  count: members.length,
                  color: LibrarianColors.primary,
                  onTap: () => setState(() => _option = MemberFilterOption.all),
                ),
                CountTile(
                  label: 'Active',
                  count: activeCount,
                  color: LibrarianColors.available,
                  onTap: () => setState(() => _option = MemberFilterOption.active),
                ),
                CountTile(
                  label: 'With Overdue',
                  count: overdueCount,
                  color: LibrarianColors.unavailable,
                  onTap: () => setState(() => _option = MemberFilterOption.overdue),
                ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            LibrarianSearchField(
              hint: 'Search name, student ID or email',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: LibrarianSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterPill(
                label: 'Status',
                options: [for (final o in MemberFilterOption.values) o.label],
                selectedIndex: _option.index,
                onSelected: (i) => setState(() => _option = MemberFilterOption.values[i]),
              ),
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            Text(
              '${results.length.toString().padLeft(2, '0')} '
              '${results.length == 1 ? 'member' : 'members'} found',
              style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
            ),
            const SizedBox(height: LibrarianSpacing.sm + 4),
            if (results.isEmpty)
              LibrarianEmptyState(
                icon: Icons.person_search_outlined,
                title: _query.trim().isEmpty
                    ? 'No members match this filter'
                    : 'No results for "${_query.trim()}"',
              )
            else
              for (final member in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
                  child: MemberCard(
                    member: member,
                    loanCount: repository.currentLoanCount(member.id),
                    reservationCount: repository.activeReservationCount(member.id),
                    overdueCount: repository.overdueLoanCount(member.id),
                    onTap: () => context.go(LibrarianRoutes.memberDetails(member.id)),
                  ),
                ),
          ],
        );
      },
    );
  }
}
