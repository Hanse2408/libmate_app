import 'package:flutter/material.dart';

import '../models/borrowing_record.dart';
import '../models/reservation_record.dart';
import '../models/seat_record.dart';
import '../providers/librarian_report.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/activity_bar_chart.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_tab_chip.dart';
import '../widgets/report_bar_list.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chip.dart';

/// Reports & Analytics: summary cards plus Book Usage, Reservation Activity,
/// Reading Room and Borrowing sections for the chosen week or month.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final report = LibrarianReport.fromRepository(repository, _period);
        final periodWord = _period == ReportPeriod.weekly ? 'this week' : 'last 4 weeks';

        final sections = [
          _section('Book Usage', [
            const _SubTitle('Most borrowed books'),
            ReportBarList(entries: report.mostBorrowed),
            const SizedBox(height: LibrarianSpacing.md),
            const _SubTitle('Most reserved books'),
            ReportBarList(entries: report.mostReserved, color: LibrarianColors.gold),
          ]),
          _section('Reservation Activity', [
            _SubTitle(_period == ReportPeriod.weekly ? 'Requests per day' : 'Requests per week'),
            ActivityBarChart(entries: report.activity),
            const SizedBox(height: LibrarianSpacing.md),
            const _SubTitle('Pending vs Approved vs Rejected'),
            ReportBarList(
              entries: report.reservationStatus,
              colors: [for (final s in ReservationStatus.values) StatusChip.reservationColor(s)],
            ),
          ]),
          _section('Reading Room', [
            _SubTitle('Seat occupancy · ${(report.occupancyRate * 100).round()}% in use'),
            ReportBarList(
              entries: report.seatStatus,
              colors: [for (final s in SeatStatus.values) StatusChip.seatColor(s)],
            ),
            const SizedBox(height: LibrarianSpacing.md),
            const _SubTitle('Popular booking periods'),
            ReportBarList(entries: report.bookingPeriods, color: LibrarianColors.emphasis),
          ]),
          _section('Borrowing', [
            ReportBarList(
              entries: [
                (label: 'Active loans', count: report.activeLoans),
                (label: 'Due today', count: report.dueTodayLoans),
                (label: 'Overdue books', count: report.overdueLoans),
                (label: 'Returned $periodWord', count: report.returnedInPeriod),
              ],
              colors: [for (final s in BorrowingStatus.values) StatusChip.borrowingColor(s)],
            ),
          ]),
        ];

        return LibrarianPage(
          maxWidth: 1100,
          children: [
            const LibrarianPageHeader(
              title: 'Reports & Analytics',
              subtitle: 'An overview of library usage.',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LibrarianTabChipBar(
                  chips: [
                    for (final period in ReportPeriod.values)
                      LibrarianTabChip(
                        label: period.label,
                        selected: _period == period,
                        onTap: () => setState(() => _period = period),
                      ),
                  ],
                ),
                const SizedBox(height: LibrarianSpacing.sm + 4),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 18, color: LibrarianColors.secondaryText),
                    const SizedBox(width: LibrarianSpacing.xs),
                    Expanded(
                      child: Text(
                        report.rangeLabel,
                        style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            ResponsiveGrid(
              minItemWidth: 140,
              children: [
                StatCard(
                  label: 'Total Books',
                  value: '${report.totalCopies}',
                  icon: Icons.menu_book_outlined,
                  subtitle: '${report.totalTitles} titles',
                ),
                StatCard(
                  label: 'Active Loans',
                  value: '${report.loansOut}',
                  icon: Icons.swap_horiz,
                  subtitle: '${report.overdueLoans} overdue',
                  subtitleColor: report.overdueLoans > 0 ? LibrarianColors.unavailable : null,
                ),
                StatCard(
                  label: 'Reservations',
                  value: '${report.reservationsInPeriod}',
                  icon: Icons.event_available_outlined,
                  subtitle: periodWord,
                ),
                StatCard(
                  label: 'Occupancy',
                  value: '${(report.occupancyRate * 100).round()}%',
                  icon: Icons.chair_outlined,
                  subtitle: 'seats in use now',
                  highlighted: true,
                ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            ResponsiveGrid(minItemWidth: 420, children: sections),
          ],
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) =>
      InfoSectionCard(title: title, children: children);
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LibrarianSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          color: LibrarianColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
