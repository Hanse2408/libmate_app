import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/reservation_record.dart';
import '../providers/librarian_scope.dart';
import '../providers/reservation_filter.dart';
import '../theme/librarian_theme.dart';
import '../widgets/filter_pill.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_search_field.dart';
import '../widgets/reservation_card.dart';

/// Lists all book and seat reservations with search and filters.
/// [initialStatus] / [initialDate] come from links such as the Dashboard's
/// "Review" (status=pending) or "Today" (date=today).
class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({
    super.key,
    this.initialStatus,
    this.initialDate = ReservationDateFilter.all,
  });

  final ReservationStatus? initialStatus;
  final ReservationDateFilter initialDate;

  @override
  State<ReservationManagementScreen> createState() =>
      _ReservationManagementScreenState();
}

class _ReservationManagementScreenState
    extends State<ReservationManagementScreen> {
  String _query = '';
  ReservationType? _type;
  late ReservationStatus? _status = widget.initialStatus;
  late ReservationDateFilter _date = widget.initialDate;

  // Menu options for the filter pills; index 0 is always "All".
  static const List<ReservationStatus?> _statusOptions = [null, ...ReservationStatus.values];
  static const List<ReservationType?> _typeOptions = [null, ...ReservationType.values];

  bool get _hasFilters =>
      _type != null || _status != null || _date != ReservationDateFilter.all;

  void _toggleType(ReservationType type) {
    setState(() => _type = _type == type ? null : type);
  }

  void _clearFilters() {
    setState(() {
      _type = null;
      _status = null;
      _date = ReservationDateFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final all = repository.reservations;
        final results = ReservationFilter(
          query: _query,
          type: _type,
          status: _status,
          date: _date,
        ).apply(all);

        return LibrarianPage(
          children: [
            const LibrarianPageHeader(
              title: 'Reservation Management',
              subtitle: 'Review, approve and manage book & seat reservations',
            ),
            _TypeButtons(selected: _type, onTap: _toggleType),
            const SizedBox(height: LibrarianSpacing.md + 4),
            LibrarianSearchField(
              hint: 'Search student, ID, book or seat',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            Wrap(
              spacing: LibrarianSpacing.sm,
              runSpacing: LibrarianSpacing.sm,
              children: [
                FilterPill(
                  label: 'Status',
                  options: [for (final s in _statusOptions) s?.label ?? 'All'],
                  selectedIndex: _statusOptions.indexOf(_status),
                  onSelected: (i) => setState(() => _status = _statusOptions[i]),
                ),
                FilterPill(
                  label: 'Date',
                  options: [for (final d in ReservationDateFilter.values) d.label],
                  selectedIndex: _date.index,
                  onSelected: (i) =>
                      setState(() => _date = ReservationDateFilter.values[i]),
                ),
                FilterPill(
                  label: 'Type',
                  options: [for (final t in _typeOptions) t?.label ?? 'All'],
                  selectedIndex: _typeOptions.indexOf(_type),
                  onSelected: (i) => setState(() => _type = _typeOptions[i]),
                ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            Text(
              '${results.length.toString().padLeft(2, '0')} '
              '${results.length == 1 ? 'reservation' : 'reservations'} found',
              style: const TextStyle(
                color: LibrarianColors.secondaryText,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: LibrarianSpacing.sm + 4),
            if (results.isEmpty)
              _emptyState(hasData: all.isNotEmpty)
            else
              for (final reservation in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
                  child: ReservationCard(
                    reservation: reservation,
                    showDate: _date != ReservationDateFilter.today,
                    onTap: () => context.go(
                      LibrarianRoutes.reservationDetails(reservation.id),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _emptyState({required bool hasData}) {
    if (!hasData) {
      return const LibrarianEmptyState(
        icon: Icons.event_note_outlined,
        title: 'No reservations yet',
        message: 'Book and seat requests from students will appear here.',
      );
    }
    if (_query.trim().isNotEmpty) {
      return LibrarianEmptyState(
        icon: Icons.search_off,
        title: 'No results for "${_query.trim()}"',
        message: 'Try a student name, student ID, reservation ID, book or seat.',
      );
    }
    return Column(
      children: [
        const LibrarianEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No reservations match these filters',
        ),
        if (_hasFilters)
          TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
      ],
    );
  }
}

/// The large "Books" / "Seats" buttons. Both solid = all types (Figma
/// default); tapping one shows only that type, tapping it again shows all.
class _TypeButtons extends StatelessWidget {
  const _TypeButtons({required this.selected, required this.onTap});

  final ReservationType? selected;
  final ValueChanged<ReservationType> onTap;

  @override
  Widget build(BuildContext context) {
    Widget button(ReservationType type, String label) {
      final active = selected == null || selected == type;
      return Expanded(
        child: FilledButton(
          onPressed: () => onTap(type),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 64),
            backgroundColor: active ? LibrarianColors.primary : LibrarianColors.lightBlue,
            foregroundColor: active ? Colors.white : LibrarianColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
            ),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          child: Text(label),
        ),
      );
    }

    return Row(
      children: [
        button(ReservationType.book, 'Books'),
        const SizedBox(width: LibrarianSpacing.md),
        button(ReservationType.seat, 'Seats'),
      ],
    );
  }
}
