import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../data/manager_mock_data.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerReservationsScreen extends StatefulWidget {
  const ManagerReservationsScreen({super.key});

  @override
  State<ManagerReservationsScreen> createState() =>
      _ManagerReservationsScreenState();
}

class _ManagerReservationsScreenState extends State<ManagerReservationsScreen> {
  String _query = '';
  int _selectedFilter = 0;
  static const _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Cancelled',
    'Conflict',
  ];

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    final results = repository.reservations.where((reservation) {
      final statusMatch =
          _selectedFilter == 0 ||
          reservation.status.name == _filters[_selectedFilter].toLowerCase();
      final query = _query.toLowerCase();
      final searchMatch =
          query.isEmpty ||
          reservation.id.toLowerCase().contains(query) ||
          reservation.book.toLowerCase().contains(query) ||
          reservation.student.toLowerCase().contains(query);
      return statusMatch && searchMatch;
    }).toList();
    return ManagerScaffold(
      title: 'Reservation Monitoring',
      currentIndex: 1,
      body: ManagerPagePadding(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Read-only view · reservation operations are handled by the librarian',
                style: TextStyle(fontSize: 10, color: AppColors.navy),
              ),
            ),
            const SizedBox(height: 9),
            SearchField(
              hint: 'Search by reservation, student or resource',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            FilterChipsRow(
              labels: _filters,
              selectedIndex: _selectedFilter,
              onChanged: (index) => setState(() => _selectedFilter = index),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No reservations found',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) => ReservationListCard(
                        reservation: results[index],
                        onTap: () => context.push(
                          AppRoutes.managerReservationDetails,
                          extra: results[index],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagerReservationDetailsScreen extends StatelessWidget {
  const ManagerReservationDetailsScreen({super.key, required this.reservation});

  final ManagerReservation reservation;

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Reservation Details',
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      text: _titleCase(reservation.status.name),
                      type: reservation.status.name,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reservation.id,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    const _DetailHeading('Book Information'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _BookIcon(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reservation.book,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                'ISBN: 978-283328',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _DetailHeading('Student Information'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
                          child: Icon(
                            Icons.person,
                            size: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.student,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              reservation.studentId,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _DetailHeading('Reservation Details'),
                    const SizedBox(height: 7),
                    _DetailRow(
                      label: 'Date',
                      value: reservation.date,
                      icon: Icons.calendar_today_outlined,
                    ),
                    _DetailRow(
                      label: 'Time',
                      value: reservation.time,
                      icon: Icons.access_time,
                    ),
                    _DetailRow(
                      label: 'Seat',
                      value: '${reservation.seat} (Reading Room)',
                      icon: Icons.event_seat_outlined,
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: _titleCase(reservation.status.name),
                      icon: Icons.info_outline,
                      valueColor:
                          reservation.status ==
                              ManagerReservationStatus.conflict
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (reservation.status == ManagerReservationStatus.conflict) ...[
              SecondaryButton(
                label: 'Resolve Conflict',
                onPressed: () => context.push(AppRoutes.managerConflict),
              ),
              const SizedBox(height: 7),
            ],
            SecondaryButton(label: 'Cancel', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }
}

class ManagerConflictScreen extends StatefulWidget {
  const ManagerConflictScreen({super.key});

  @override
  State<ManagerConflictScreen> createState() => _ManagerConflictScreenState();
}

class _ManagerConflictScreenState extends State<ManagerConflictScreen> {
  String _action = 'Reassign Seat';

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Conflict Monitoring',
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Monitoring record only. Normal booking conflicts are prevented during student booking.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            const _DetailHeading('Conflict Details'),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(13),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Conflict ID',
                      value: 'C001',
                      icon: Icons.tag_outlined,
                    ),
                    _DetailRow(
                      label: 'Resource',
                      value: 'Seat B12',
                      icon: Icons.event_seat_outlined,
                    ),
                    _DetailRow(
                      label: 'Date',
                      value: '02 Oct 2026',
                      icon: Icons.calendar_today_outlined,
                    ),
                    _DetailRow(
                      label: 'Time',
                      value: '10:00 AM - 12:00 PM',
                      icon: Icons.access_time,
                    ),
                    _DetailRow(
                      label: 'Affected Reservation',
                      value: 'RES-1023',
                      icon: Icons.event_note_outlined,
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: 'Pending review',
                      icon: Icons.info_outline,
                      valueColor: AppColors.gold,
                    ),
                    _DetailRow(
                      label: 'Detected',
                      value: '02 Oct 2026',
                      icon: Icons.history,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Conflict ID',
                      value: 'C001',
                      icon: Icons.tag_outlined,
                    ),
                    _DetailRow(
                      label: 'Resource',
                      value: 'Seat B12',
                      icon: Icons.event_seat_outlined,
                    ),
                    _DetailRow(
                      label: 'Date',
                      value: '02 Oct 2026',
                      icon: Icons.calendar_today_outlined,
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: 'Pending review',
                      icon: Icons.info_outline,
                      valueColor: AppColors.gold,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _BookingSummary(
              heading: 'Booking 1 (Existing)',
              id: 'RES-0987',
              name: 'Neranjala Gunarathne',
              time: '10:00 AM - 12:00 PM',
              status: 'Confirmed',
            ),
            const SizedBox(height: 9),
            const _BookingSummary(
              heading: 'Booking 2 (Current)',
              id: 'RES-1023',
              name: 'Hanse Perera',
              time: '11:00 AM - 01:00 PM',
              status: 'Pending',
              showWarning: true,
            ),
            const SizedBox(height: 14),
            const _DetailHeading('Conflict Reason'),
            const SizedBox(height: 5),
            Text(
              'Overlapping time slot for the same seat (B12).',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 14),
            const _DetailHeading('Existing Resolution Workflow'),
            const SizedBox(height: 4),
            Text(
              'Monitoring is the Manager\'s primary role. Existing resolution actions are retained as a secondary workflow.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: _action,
              onChanged: (value) {
                if (value != null) setState(() => _action = value);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'Reassign Seat',
                    title: Text(
                      'Reassign Seat',
                      style: TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: 'Cancel Reservation',
                    title: Text(
                      'Cancel Reservation',
                      style: TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                if (_action == 'Reassign Seat') {
                  context.push(AppRoutes.managerReassignSeat);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reservation cancelled (demo)'),
                    ),
                  );
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ManagerReassignSeatScreen extends StatefulWidget {
  const ManagerReassignSeatScreen({super.key});

  @override
  State<ManagerReassignSeatScreen> createState() =>
      _ManagerReassignSeatScreenState();
}

class _ManagerReassignSeatScreenState extends State<ManagerReassignSeatScreen> {
  String _selectedSeat = 'A08';
  static const _reservedSeats = {'A02', 'A05', 'A09', 'B03', 'B10', 'B15'};

  @override
  Widget build(BuildContext context) {
    final seats = [
      for (final letter in ['A', 'B'])
        for (var number = 1; number <= 15; number++)
          '$letter${number.toString().padLeft(2, '0')}',
    ];
    return ManagerScaffold(
      title: 'Select New Seat',
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Current Seat',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    Text('B12', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    const StatusBadge(text: 'Conflicted', type: 'conflict'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const _DetailHeading('Available Seats'),
            const SizedBox(height: 8),
            const _SeatLegend(),
            const SizedBox(height: 11),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: seats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 7,
                mainAxisSpacing: 8,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                final seat = seats[index];
                final state = seat == 'B12'
                    ? ManagerSeatState.conflict
                    : _reservedSeats.contains(seat)
                    ? ManagerSeatState.reserved
                    : seat == _selectedSeat
                    ? ManagerSeatState.selected
                    : ManagerSeatState.available;
                return SeatChip(
                  label: seat,
                  state: state,
                  onTap:
                      state == ManagerSeatState.available ||
                          state == ManagerSeatState.selected
                      ? () => setState(() => _selectedSeat = seat)
                      : null,
                );
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Confirm Reassignment',
              onPressed: () =>
                  context.push(AppRoutes.managerResolved, extra: _selectedSeat),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagerResolvedScreen extends StatelessWidget {
  const ManagerResolvedScreen({super.key, required this.newSeat});

  final String newSeat;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        body: ManagerPagePadding(
          includeTopSafeArea: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.success,
                child: Icon(Icons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 15),
              Text(
                'Conflict Resolved',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const _ResolvedRow(
                        label: 'Reservation:',
                        value: 'RES-1023',
                      ),
                      const Divider(height: 17),
                      const _ResolvedRow(label: 'Old Seat:', value: 'B12'),
                      const Divider(height: 17),
                      _ResolvedRow(label: 'New Seat:', value: newSeat),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Student has been notified with the updated details.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Back to Reservations',
                onPressed: () => context.go(AppRoutes.managerReservations),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryText),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _BookIcon extends StatelessWidget {
  const _BookIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 42,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary),
  );
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.heading,
    required this.id,
    required this.name,
    required this.time,
    required this.status,
    this.showWarning = false,
  });

  final String heading;
  final String id;
  final String name;
  final String time;
  final String status;
  final bool showWarning;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (showWarning) ...[
            const Icon(Icons.error_outline, color: AppColors.error, size: 16),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 10),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          StatusBadge(text: status, type: status.toLowerCase()),
        ],
      ),
    ),
  );
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    children: const [
      _LegendDot(color: AppColors.success, label: 'Available'),
      _LegendDot(color: AppColors.primary, label: 'Reserved'),
      _LegendDot(color: AppColors.error, label: 'Conflict'),
    ],
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(radius: 4, backgroundColor: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
      ),
    ],
  );
}

class _ResolvedRow extends StatelessWidget {
  const _ResolvedRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

String _titleCase(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}';
