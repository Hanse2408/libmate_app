import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../data/librarian_repository.dart';
import '../models/seat_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_message_banner.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/count_tile.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/seat_details_panel.dart';
import '../widgets/seat_map_card.dart';
import '../widgets/status_chip.dart';

/// Seat Management (Figma): today's date, Add New Seat, seat counts, the
/// seat map per reading room and details of the selected seat.
class SeatManagementScreen extends StatefulWidget {
  const SeatManagementScreen({super.key, this.message});

  /// Success message to show on arrival, e.g. after adding a seat.
  final String? message;

  @override
  State<SeatManagementScreen> createState() => _SeatManagementScreenState();
}

class _SeatManagementScreenState extends State<SeatManagementScreen> {
  String? _selectedSeatId;
  late String? _message = widget.message;

  @override
  void didUpdateWidget(SeatManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Returning from the add form reuses this page, so pick up the new message.
    if (widget.message != null && widget.message != oldWidget.message) {
      _message = widget.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final seats = repository.seats;
        int count(SeatStatus status) => seats.where((s) => s.status == status).length;
        final rooms = seats.map((s) => s.readingRoom).toSet().toList()..sort();
        final selected = _selectedSeatId == null
            ? null
            : repository.seatById(_selectedSeatId!);

        final maps = [
          for (final room in rooms)
            SeatMapCard(
              readingRoom: room,
              seats: seats.where((s) => s.readingRoom == room).toList(),
              selectedSeatId: _selectedSeatId,
              onSeatSelected: (seat) => setState(() => _selectedSeatId = seat.id),
            ),
        ];
        final details = selected == null
            ? const InfoSectionCard(
                children: [
                  Text(
                    'Select a seat on the map to see its details and update its status.',
                    style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 16),
                  ),
                ],
              )
            : SeatDetailsPanel(
                seat: selected,
                reservation: repository.activeReservationForSeat(selected.id),
                onUpdateStatus: () => _changeStatus(repository, selected),
                onEdit: () => context.go(LibrarianRoutes.editSeat(selected.id)),
              );

        return LibrarianPage(
          maxWidth: 1100,
          children: [
            const LibrarianPageHeader(
              title: 'Seat Management',
              subtitle: 'Monitor and manage reading-room occupancy.',
            ),
            const _DateAndAddRow(),
            const SizedBox(height: LibrarianSpacing.lg),
            if (_message != null)
              LibrarianMessageBanner(
                message: _message!,
                onClose: () => setState(() => _message = null),
              ),
            ResponsiveGrid(
              children: [
                for (final status in [
                  SeatStatus.available,
                  SeatStatus.reserved,
                  SeatStatus.occupied,
                ])
                  CountTile(
                    label: status.label,
                    count: count(status),
                    color: StatusChip.seatColor(status),
                  ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            if (repository.isLoading && seats.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (repository.loadError != null && seats.isEmpty)
              LibrarianEmptyState(
                icon: Icons.cloud_off,
                title: 'Seats could not be loaded',
                message: repository.loadError!,
              )
            else if (seats.isEmpty)
              const LibrarianEmptyState(
                icon: Icons.chair_outlined,
                title: 'No seats yet',
                message: 'Use "Add New Seat" to register reading-room seats.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(children: [...maps, details]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Column(children: maps)),
                      const SizedBox(width: LibrarianSpacing.lg),
                      Expanded(flex: 2, child: details),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  /// Bottom sheet to change a seat's status. "Reserved" is not offered
  /// because seats become reserved by approving a reservation.
  Future<void> _changeStatus(
    LibrarianRepository repository,
    SeatRecord seat,
  ) async {
    final newStatus = await showModalBottomSheet<SeatStatus>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LibrarianSpacing.lg),
              child: Text(
                'Update Seat ${seat.seatNumber}',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            for (final status in [
              SeatStatus.available,
              SeatStatus.occupied,
              SeatStatus.maintenance,
            ])
              ListTile(
                leading: CircleAvatar(
                  radius: 8,
                  backgroundColor: StatusChip.seatColor(status),
                ),
                title: Text(status.label),
                trailing: status == seat.status ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(status),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                LibrarianSpacing.lg,
                LibrarianSpacing.xs,
                LibrarianSpacing.lg,
                LibrarianSpacing.md,
              ),
              child: Text(
                'Seats become "Reserved" when you approve a seat reservation.',
                style: TextStyle(color: LibrarianColors.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );

    if (newStatus == null || newStatus == seat.status) return;
    final result = await repository.updateSeatStatus(seat.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Seat ${seat.seatNumber} is now ${newStatus.label}.'
                : result.message!,
          ),
        ),
      );
  }
}

/// Today's date (display only) next to the "+ Add New Seat" button.
class _DateAndAddRow extends StatelessWidget {
  const _DateAndAddRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: LibrarianSpacing.md),
            decoration: BoxDecoration(
              color: LibrarianColors.navy.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: LibrarianSpacing.sm),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      LibrarianFormatters.weekdayDate(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: LibrarianSpacing.md),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.go(LibrarianRoutes.addSeat),
            icon: const Icon(Icons.add),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Add New Seat'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
