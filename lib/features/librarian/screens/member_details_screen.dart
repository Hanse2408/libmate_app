import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../data/librarian_mock_repository.dart';
import '../models/borrowing_record.dart';
import '../models/member_record.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/borrowing_card.dart';
import '../widgets/count_tile.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/reservation_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

/// Member Details: profile, contact, loans, reservations, history and the
/// account status action. Laid out like the Reservation Details screens.
class MemberDetailsScreen extends StatelessWidget {
  const MemberDetailsScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final member = repository.memberById(memberId);
        if (member == null) {
          return const LibrarianPage(
            maxWidth: 760,
            children: [
              LibrarianPageHeader(title: 'Member Details'),
              LibrarianEmptyState(icon: Icons.person_off_outlined, title: 'Member not found'),
            ],
          );
        }

        final loans = repository.borrowingsForMember(member.id);
        final overdue = loans.where((l) => l.status == BorrowingStatus.overdue).toList();
        final current = loans
            .where((l) => !l.isReturned && l.status != BorrowingStatus.overdue)
            .toList();
        final returned = loans.where((l) => l.isReturned).toList()
          ..sort((a, b) => b.returnedAt!.compareTo(a.returnedAt!));

        final reservations = repository.reservationsForMember(member.id);
        bool isCurrent(ReservationRecord r) =>
            r.isPending || r.status == ReservationStatus.approved;
        final currentReservations = reservations.where(isCurrent).toList();
        final pastReservations = reservations.where((r) => !isCurrent(r)).toList();

        // Back from a loan / reservation opened here returns to this member.
        final from = LibrarianRoutes.memberDetails(member.id);
        String withFrom(String path) =>
            Uri(path: path, queryParameters: {'from': from}).toString();

        Widget loanCard(BorrowingRecord loan) => Padding(
          padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
          child: BorrowingCard(
            loan: loan,
            onTap: () => context.go(withFrom(LibrarianRoutes.borrowingDetails(loan.id))),
          ),
        );
        Widget reservationCard(ReservationRecord r) => Padding(
          padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
          child: ReservationCard(
            reservation: r,
            onTap: () => context.go(withFrom(LibrarianRoutes.reservationDetails(r.id))),
          ),
        );

        return LibrarianPage(
          maxWidth: 760,
          children: [
            LibrarianPageHeader(
              title: 'Member Details',
              subtitle: 'Members / ${member.id}',
              trailing: StatusChip.member(member.status),
            ),
            _ProfileCard(member: member),
            InfoSectionCard(
              title: 'Contact Information',
              children: [
                InfoGrid(
                  items: [
                    InfoItem('Email', member.email, wide: true),
                    InfoItem('Phone', member.phone),
                    InfoItem(
                      'Borrow Limit',
                      '${current.length + overdue.length} of ${repository.settings.maxBorrowLimit} books',
                    ),
                    InfoItem(
                      'Member Since',
                      LibrarianFormatters.date(member.memberSince).split(' ').skip(1).join(' '),
                    ),
                  ],
                ),
              ],
            ),
            ResponsiveGrid(
              children: [
                CountTile(
                  label: 'Borrowed',
                  count: current.length + overdue.length,
                  color: LibrarianColors.primary,
                ),
                CountTile(
                  label: 'Reserved',
                  count: currentReservations.length,
                  color: LibrarianColors.gold,
                ),
                CountTile(
                  label: 'Overdue',
                  count: overdue.length,
                  color: LibrarianColors.unavailable,
                ),
              ],
            ),
            if (overdue.isNotEmpty) ...[
              const SectionHeader(title: 'Overdue Items'),
              ...overdue.map(loanCard),
            ],
            const SectionHeader(title: 'Current Borrowed Books'),
            if (current.isEmpty) const _NoneText('No books on loan.') else ...current.map(loanCard),
            const SectionHeader(title: 'Current Reservations'),
            if (currentReservations.isEmpty)
              const _NoneText('No pending or approved reservations.')
            else
              ...currentReservations.map(reservationCard),
            const SectionHeader(title: 'Borrowing History'),
            if (returned.isEmpty) const _NoneText('No returned books yet.') else ...returned.map(loanCard),
            const SectionHeader(title: 'Reservation History'),
            if (pastReservations.isEmpty)
              const _NoneText('No past reservations.')
            else
              ...pastReservations.map(reservationCard),
            const SizedBox(height: LibrarianSpacing.lg),
            _AccountStatusCard(member: member, repository: repository),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.member});

  final MemberRecord member;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: LibrarianColors.text,
              child: Text(
                LibrarianFormatters.initials(member.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: LibrarianSpacing.md + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: LibrarianColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Student ID: ${member.id}',
                    style: const TextStyle(color: LibrarianColors.secondaryText, fontSize: 16),
                  ),
                  Text(
                    member.programme,
                    style: const TextStyle(color: LibrarianColors.secondaryText),
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

class _NoneText extends StatelessWidget {
  const _NoneText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: LibrarianColors.secondaryText));
  }
}

/// Shows the account status with a Suspend / Reactivate action.
class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({required this.member, required this.repository});

  final MemberRecord member;
  final LibrarianMockRepository repository;

  Future<void> _changeStatus(BuildContext context) async {
    final suspend = member.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(suspend ? 'Suspend account?' : 'Reactivate account?'),
        content: Text(
          suspend
              ? '${member.name} will not be able to borrow or reserve until reactivated.'
              : '${member.name} will be able to borrow and reserve again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: suspend ? LibrarianColors.unavailable : null,
            ),
            child: Text(suspend ? 'Suspend' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await repository.updateMemberStatus(
      member.id,
      suspend ? MemberStatus.suspended : MemberStatus.active,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '${member.name} is now ${suspend ? 'suspended' : 'active'}.'
              : result.message!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: 'Account Status',
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Current status',
                style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
              ),
            ),
            StatusChip.member(member.status),
          ],
        ),
        const SizedBox(height: LibrarianSpacing.md),
        member.isActive
            ? OutlinedButton(
                onPressed: () => _changeStatus(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  foregroundColor: LibrarianColors.unavailable,
                  side: const BorderSide(color: LibrarianColors.unavailable, width: 1.5),
                ),
                child: const Text('Suspend Account'),
              )
            : FilledButton(
                onPressed: () => _changeStatus(context),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: const Text('Reactivate Account'),
              ),
      ],
    );
  }
}
