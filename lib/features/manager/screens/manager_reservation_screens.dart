import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../models/reservation.dart';
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
    'Approved',
    'Collected',
    'Returned',
    'Rejected',
    'Cancelled',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    if (repository.reservationsError != null ||
        repository.reservationsLoading) {
      return ManagerScaffold(
        title: 'Reservation Monitoring',
        currentIndex: 1,
        body: Center(
          child: repository.reservationsError != null
              ? Text(repository.reservationsError!)
              : const CircularProgressIndicator(),
        ),
      );
    }
    final results = repository.reservations.where((reservation) {
      final statusMatch =
          _selectedFilter == 0 ||
          reservation.statusLabel == _filters[_selectedFilter] ||
          (_filters[_selectedFilter] == 'Approved' &&
              reservation.status == ManagerReservationStatus.confirmed);
      final query = _query.toLowerCase();
      final searchMatch =
          query.isEmpty ||
          [
            reservation.id,
            reservation.book,
            reservation.student,
            reservation.studentId,
            reservation.itemId,
            reservation.typeLabel,
          ].any((value) => value.toLowerCase().contains(query));
      return statusMatch && searchMatch;
    }).toList();
    return ManagerScaffold(
      title: 'Reservation Monitoring',
      currentIndex: 1,
      body: ManagerPagePadding(
        child: Column(
          children: [
            const Text(
              'Read-only reservation monitoring',
              style: TextStyle(fontSize: 10),
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
                  ? const Center(child: Text('No reservations found'))
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) => ReservationListCard(
                        reservation: results[index],
                        onTap: () => context.push(
                          AppRoutes.managerReservationDetails,
                          extra: results[index].id,
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
  const ManagerReservationDetailsScreen({
    super.key,
    this.reservation,
    this.reservationId,
  });

  final ManagerReservation? reservation;
  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    final record = repository.findReservationById(
      reservationId ?? reservation?.id ?? '',
    );
    final message =
        repository.reservationsError ??
        (repository.reservationsLoading
            ? null
            : record == null
            ? 'Reservation not found'
            : null);
    if (message != null || repository.reservationsLoading) {
      return ManagerScaffold(
        title: 'Reservation Details',
        body: Center(
          child: message == null
              ? const CircularProgressIndicator()
              : Text(message),
        ),
      );
    }
    final item = record!;
    final isSeat = item.type == ReservationType.seat;
    String value(String? text) =>
        text == null || text.trim().isEmpty ? 'Not available' : text;
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
                    StatusBadge(text: item.statusLabel, type: item.status.name),
                    const SizedBox(height: 8),
                    Text(
                      item.id,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isSeat
                          ? 'Seat Information'
                          : item.type == ReservationType.book
                          ? 'Book Information'
                          : 'Reservation Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _DetailRow(
                      label: isSeat ? 'Seat' : 'Item',
                      value: value(item.book),
                    ),
                    _DetailRow(label: 'Item ID', value: value(item.itemId)),
                    _DetailRow(label: 'Type', value: item.typeLabel),
                    const SizedBox(height: 14),
                    Text(
                      'Student Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _DetailRow(label: 'Name', value: value(item.student)),
                    _DetailRow(
                      label: 'Student ID',
                      value: value(item.studentId),
                    ),
                    if (item.studentEmail.isNotEmpty)
                      _DetailRow(label: 'Email', value: item.studentEmail),
                    const SizedBox(height: 14),
                    Text(
                      'Reservation Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _DetailRow(
                      label: isSeat ? 'Booking date' : 'Pickup date',
                      value: item.date,
                    ),
                    _DetailRow(label: 'Time', value: value(item.time)),
                    if (!isSeat && item.pickupLocation?.isNotEmpty == true)
                      _DetailRow(
                        label: 'Pickup location',
                        value: item.pickupLocation!,
                      ),
                    if (!isSeat && item.loanPeriodDays != null)
                      _DetailRow(
                        label: 'Loan period',
                        value: '${item.loanPeriodDays} days',
                      ),
                    if (item.note?.isNotEmpty == true)
                      _DetailRow(label: 'Notes', value: item.note!),
                    _DetailRow(label: 'Status', value: item.statusLabel),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Back to Reservations',
              onPressed: () => context.go(AppRoutes.managerReservations),
            ),
          ],
        ),
      ),
    );
  }
}

// Student transactions prevent overlapping seat-hour ownership. This project
// has no Manager conflict engine or safe reassignment transaction.
class ManagerConflictScreen extends StatelessWidget {
  const ManagerConflictScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ConflictUnavailableScreen(title: 'Conflict Monitoring');
}

class ManagerReassignSeatScreen extends StatelessWidget {
  const ManagerReassignSeatScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ConflictUnavailableScreen(title: 'Seat Reassignment');
}

class ManagerResolvedScreen extends StatelessWidget {
  const ManagerResolvedScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ConflictUnavailableScreen(title: 'Conflict Monitoring');
}

class _ConflictUnavailableScreen extends StatelessWidget {
  const _ConflictUnavailableScreen({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    final hasConflict = repository.reservations.any(
      (r) => r.status == ManagerReservationStatus.conflict,
    );
    return ManagerScaffold(
      title: title,
      body: ManagerPagePadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (repository.reservationsError != null)
              Text(repository.reservationsError!)
            else if (repository.reservationsLoading)
              const CircularProgressIndicator()
            else
              Text(
                hasConflict
                    ? 'Conflict resolution is unavailable. Please contact the library.'
                    : 'No conflicts detected',
              ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Back to Reservations',
              onPressed: () => context.go(AppRoutes.managerReservations),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
}
