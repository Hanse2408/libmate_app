import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../../../core/widgets/libmate_logo.dart';
import '../models/borrowing_record.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_dashboard_summary.dart';
import '../providers/reservation_filter.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/attention_card.dart';
import '../widgets/librarian_avatar_menu.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page_body.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/occupancy_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/reservation_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

/// Librarian home: today's numbers, alerts, today's reservations,
/// reading-room occupancy and shortcuts.
class LibrarianDashboardScreen extends StatelessWidget {
  const LibrarianDashboardScreen({super.key});

  /// From this width the dashboard uses two columns (web / tablet).
  static const double _wideLayoutWidth = 720;

  static final String _pendingReservations = LibrarianRoutes.reservationsFiltered(
    status: ReservationStatus.pending,
  );

  /// How many of today's reservations are previewed on the dashboard.
  static const int _todayPreviewCount = 3;

  @override
  Widget build(BuildContext context) {
    final scope = LibrarianScope.of(context);

    // Rebuild whenever mock data or the signed-in profile changes.
    return ListenableBuilder(
      listenable: Listenable.merge([scope.repository, scope.authProvider]),
      builder: (context, _) {
        final summary = LibrarianDashboardSummary.fromRepository(
          scope.repository,
        );
        final profile = scope.authProvider.profile;
        final name = (profile?.name.isNotEmpty ?? false)
            ? profile!.name
            : 'Librarian';

        return Scaffold(
          appBar: _DashboardAppBar(
            name: name,
            email: profile?.email ?? '',
            unreadCount: summary.unreadNotifications,
            onSignOut: scope.authProvider.signOut,
          ),
          body: LibrarianPageBody(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= _wideLayoutWidth;
                return ListView(
                  padding: const EdgeInsets.all(LibrarianSpacing.md + 4),
                  children: [
                    const _Greeting(),
                    const SizedBox(height: LibrarianSpacing.md),
                    _StatCards(summary: summary),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _leftColumn(context, summary)),
                          const SizedBox(width: LibrarianSpacing.lg),
                          Expanded(child: _rightColumn(context, summary)),
                        ],
                      )
                    else ...[
                      _leftColumn(context, summary),
                      _rightColumn(context, summary),
                    ],
                    const SizedBox(height: LibrarianSpacing.md),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _leftColumn(BuildContext context, LibrarianDashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Attention Required',
          actionLabel: 'See all',
          onAction: () => context.go(LibrarianRoutes.notifications),
        ),
        ..._attentionCards(context, summary),
        SectionHeader(
          title: "Today's Reservations",
          actionLabel: 'View all',
          onAction: () => context.go(LibrarianRoutes.reservations),
        ),
        if (summary.todaysReservations.isEmpty)
          const LibrarianEmptyState(
            icon: Icons.event_available_outlined,
            title: 'No reservations today',
          )
        else
          for (final reservation
              in summary.todaysReservations.take(_todayPreviewCount))
            Padding(
              padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
              child: ReservationCard(
                reservation: reservation,
                showDate: false,
                onTap: () => context.go(
                  Uri(
                    path: LibrarianRoutes.reservationDetails(reservation.id),
                    queryParameters: {'from': LibrarianRoutes.dashboard},
                  ).toString(),
                ),
              ),
            ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context, LibrarianDashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Reading Room Occupancy'),
        OccupancyCard(
          occupancyRate: summary.occupancyRate,
          available: summary.availableSeats,
          reserved: summary.reservedSeats,
          occupied: summary.occupiedSeats,
          maintenance: summary.maintenanceSeats,
          onTap: () => context.go(LibrarianRoutes.seats),
        ),
        const SectionHeader(title: 'Quick Actions'),
        Wrap(
          spacing: LibrarianSpacing.sm + 4,
          runSpacing: LibrarianSpacing.sm + 4,
          children: [
            QuickActionTile(
              icon: Icons.event_available_outlined,
              label: 'Manage Reservations',
              onTap: () => context.go(LibrarianRoutes.reservations),
            ),
            QuickActionTile(
              icon: Icons.add_box_outlined,
              label: 'Add New Book',
              onTap: () => context.go(LibrarianRoutes.addBook),
            ),
            QuickActionTile(
              icon: Icons.add_box_outlined,
              label: 'Add New Seat',
              onTap: () => context.go(LibrarianRoutes.addSeat),
            ),
            QuickActionTile(
              icon: Icons.swap_horiz,
              label: 'Borrowing',
              onTap: () => context.go(LibrarianRoutes.borrowings),
            ),
            QuickActionTile(
              icon: Icons.people_outline,
              label: 'Members',
              onTap: () => context.go(LibrarianRoutes.members),
            ),
            QuickActionTile(
              icon: Icons.bar_chart,
              label: 'Reports',
              onTap: () => context.go(LibrarianRoutes.reports),
            ),
          ],
        ),
      ],
    );
  }

  /// Alerts are only shown when there is something to act on.
  List<Widget> _attentionCards(
    BuildContext context,
    LibrarianDashboardSummary summary,
  ) {
    final cards = <Widget>[
      if (summary.pendingCount > 0)
        AttentionCard(
          icon: Icons.person_outline,
          color: LibrarianColors.unavailable,
          message: summary.pendingCount == 1
              ? '1 reservation request is waiting for approval.'
              : '${summary.pendingCount} reservation requests are waiting for approval.',
          actionLabel: 'Review',
          onTap: () => context.go(_pendingReservations),
        ),
      if (summary.conflictCount > 0)
        AttentionCard(
          icon: Icons.warning_amber_rounded,
          color: LibrarianColors.gold,
          message: summary.conflictCount == 1
              ? '1 booking conflict detected.'
              : '${summary.conflictCount} booking conflicts detected.',
          actionLabel: 'View',
          onTap: () => context.go(_pendingReservations),
        ),
      if (summary.overdueLoans > 0)
        AttentionCard(
          icon: Icons.assignment_late_outlined,
          color: LibrarianColors.unavailable,
          message: summary.overdueLoans == 1
              ? '1 borrowed book is overdue.'
              : '${summary.overdueLoans} borrowed books are overdue.',
          actionLabel: 'View',
          onTap: () => context.go(
            LibrarianRoutes.borrowingsFiltered(BorrowingStatus.overdue),
          ),
        ),
      if (summary.outOfStockBooks > 0)
        AttentionCard(
          icon: Icons.menu_book_outlined,
          color: LibrarianColors.gold,
          message: summary.outOfStockBooks == 1
              ? '1 book has no copies available.'
              : '${summary.outOfStockBooks} books have no copies available.',
          actionLabel: 'View',
          onTap: () => context.go(LibrarianRoutes.books),
        ),
    ];

    if (cards.isEmpty) {
      return const [
        LibrarianEmptyState(
          icon: Icons.check_circle_outline,
          title: 'All caught up',
          message: 'Nothing needs your attention right now.',
        ),
      ];
    }
    return [
      for (final card in cards)
        Padding(
          padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
          child: card,
        ),
    ];
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar({
    required this.name,
    required this.email,
    required this.unreadCount,
    required this.onSignOut,
  });

  final String name;
  final String email;
  final int unreadCount;
  final VoidCallback onSignOut;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      backgroundColor: LibrarianColors.card,
      shape: Border(bottom: BorderSide(color: LibrarianColors.border)),
      titleSpacing: LibrarianSpacing.md + 4,
      title: Row(
        children: [
          // The LibMate app logo (same asset and widget as the login header).
          const LibMateLogo(size: 44),
          const SizedBox(width: LibrarianSpacing.sm + 4),
          Flexible(
            child: Text(
              'LibMate',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: LibrarianColors.text,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        NotificationBellButton(
          unreadCount: unreadCount,
          onPressed: () => context.go(LibrarianRoutes.notifications),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.go(LibrarianRoutes.settings),
          icon: Icon(
            Icons.settings_outlined,
            size: 28,
            color: LibrarianColors.text,
          ),
        ),
        const SizedBox(width: LibrarianSpacing.sm),
        LibrarianAvatarMenu(
          name: name,
          email: email,
          onSignOut: onSignOut,
          // Secondary navigation for sections not in the bottom bar.
          links: [
            (Icons.swap_horiz, 'Borrowing', () => context.go(LibrarianRoutes.borrowings)),
            (Icons.people_outline, 'Members', () => context.go(LibrarianRoutes.members)),
            (Icons.bar_chart, 'Reports', () => context.go(LibrarianRoutes.reports)),
            (Icons.settings_outlined, 'Settings', () => context.go(LibrarianRoutes.settings)),
          ],
        ),
        const SizedBox(width: LibrarianSpacing.md + 4),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final greeting = LibrarianFormatters.greeting(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, librarian',
          style: TextStyle(
            color: LibrarianColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.xs),
        Text(
          "Here's what's happening in the library today.",
          style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 16),
        ),
      ],
    );
  }
}

/// "Today" and "Pending" cards side by side, kept the same height.
class _StatCards extends StatelessWidget {
  const _StatCards({required this.summary});

  final LibrarianDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final change = summary.todayChange;
    final (changeText, changeIcon, changeColor) = change > 0
        ? ('$change from yesterday', Icons.arrow_upward, LibrarianColors.available)
        : change < 0
        ? ('${-change} from yesterday', Icons.arrow_downward, LibrarianColors.unavailable)
        : ('Same as yesterday', null, LibrarianColors.secondaryText);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              label: 'Today',
              value: '${summary.todayCount}',
              icon: Icons.calendar_today_outlined,
              subtitle: changeText,
              subtitleIcon: changeIcon,
              subtitleColor: changeColor,
              onTap: () => context.go(
                LibrarianRoutes.reservationsFiltered(
                  date: ReservationDateFilter.today,
                ),
              ),
            ),
          ),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: StatCard(
              label: 'Pending',
              value: summary.pendingCount.toString().padLeft(2, '0'),
              icon: Icons.warning_amber_rounded,
              subtitle: summary.pendingCount > 0
                  ? 'Requires attention'
                  : 'All caught up',
              highlighted: true,
              onTap: () => context.go(
                LibrarianDashboardScreen._pendingReservations,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
