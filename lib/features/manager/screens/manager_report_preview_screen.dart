import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
import '../data/manager_repository.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerReportPreviewScreen extends StatefulWidget {
  const ManagerReportPreviewScreen({super.key, required this.selection});

  final ManagerReportSelection selection;

  @override
  State<ManagerReportPreviewScreen> createState() =>
      _ManagerReportPreviewScreenState();
}

class _ManagerReportPreviewScreenState
    extends State<ManagerReportPreviewScreen> {
  late ManagerReportSelection _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.selection;
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Report Preview',
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 17,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preview uses the live manager data source before export.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: _selection.reportType,
              decoration: const InputDecoration(labelText: 'Report'),
              items: [
                for (final type in managerReportTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(
                    () => _selection = _selection.copyWith(reportType: value),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _chooseDateRange,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                '${_dateLabel(_selection.startDate)} - ${_dateLabel(_selection.endDate)}',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${_selection.reportType} Report',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(
              'Live data · ${_recordsCount(context)} records',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            _PreviewSummary(selection: _selection),
            const SizedBox(height: 15),
            const SectionHeader(title: 'Daily Breakdown'),
            const SizedBox(height: 7),
            _DailyBreakdown(reportType: _selection.reportType),
            const SizedBox(height: 14),
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 7),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'CSV', label: Text('CSV')),
                ButtonSegment(value: 'PDF', label: Text('PDF')),
              ],
              selected: {_selection.format},
              onSelectionChanged: (value) {
                setState(
                  () => _selection = _selection.copyWith(format: value.first),
                );
              },
            ),
            const SizedBox(height: 13),
            PrimaryButton(
              label: 'Export Report',
              icon: Icons.file_download_outlined,
              onPressed: () => context.push(
                AppRoutes.managerExportConfirmation,
                extra: _selection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _recordsCount(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    return switch (_selection.reportType) {
      'Users' => repository.users.length,
      'Reservations' || 'Conflicts' => repository.reservations.length,
      'Popular Books' => _popularBookCount(repository),
      'Overdue Books' => _overdueBookCount(repository),
      _ => 4,
    };
  }

  int _popularBookCount(ManagerRepository repository) {
    final counts = <String, int>{};
    for (final reservation in repository.reservations) {
      final title = reservation.book.trim();
      if (title.isEmpty) continue;
      counts.update(title, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.values.fold<int>(0, (sum, value) => sum + value);
  }

  int _overdueBookCount(ManagerRepository repository) {
    return repository.reservations
        .where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.pending ||
              reservation.status == ManagerReservationStatus.conflict,
        )
        .length;
  }

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: _selection.startDate,
        end: _selection.endDate,
      ),
    );
    if (range != null && mounted) {
      setState(
        () => _selection = _selection.copyWith(
          startDate: range.start,
          endDate: range.end,
        ),
      );
    }
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.selection});

  final ManagerReportSelection selection;

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    final metrics = switch (selection.reportType) {
      'Users' => [
        ('Total Users', '${repository.users.length}'),
        ('Active', '${repository.users.where((user) => user.isActive).length}'),
        (
          'Inactive',
          '${repository.users.where((user) => !user.isActive).length}',
        ),
      ],
      'Popular Books' => _popularBookMetrics(repository),
      'Overdue Books' => _overdueMetrics(repository),
      'Occupancy' || 'Peak Usage' => [
        ('Total Seats', '${repository.reservations.length + 30}'),
        ('Booked', '${repository.reservations.length}'),
        (
          'Peak',
          '${repository.reservations.isEmpty ? 0 : repository.reservations.length}',
        ),
      ],
      'Conflicts' => [
        (
          'Total Records',
          '${repository.reservations.where((r) => r.status == ManagerReservationStatus.conflict).length}',
        ),
        (
          'Pending',
          '${repository.reservations.where((r) => r.status == ManagerReservationStatus.pending).length}',
        ),
        (
          'Confirmed',
          '${repository.reservations.where((r) => r.status == ManagerReservationStatus.confirmed).length}',
        ),
      ],
      _ => [
        ('Total Reservations', '${repository.reservations.length}'),
        (
          'Confirmed',
          '${repository.reservations.where((r) => r.status == ManagerReservationStatus.confirmed).length}',
        ),
        (
          'Pending',
          '${repository.reservations.where((r) => r.status == ManagerReservationStatus.pending).length}',
        ),
      ],
    };

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metrics[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metrics[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<(String, String)> _popularBookMetrics(ManagerRepository repository) {
    final counts = <String, int>{};
    for (final reservation in repository.reservations) {
      final title = reservation.book.trim();
      if (title.isEmpty) continue;
      counts.update(title, (value) => value + 1, ifAbsent: () => 1);
    }

    if (counts.isEmpty) {
      return [('Books', '0'), ('Top Title', 'No data'), ('Sample Count', '0')];
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTitle = sorted.first.key;
    final topCount = sorted.first.value;
    return [
      ('Books', '${counts.length}'),
      ('Top Title', topTitle),
      ('Sample Count', '$topCount'),
    ];
  }

  List<(String, String)> _overdueMetrics(ManagerRepository repository) {
    final attention = repository.reservations.where(
      (reservation) =>
          reservation.status == ManagerReservationStatus.pending ||
          reservation.status == ManagerReservationStatus.conflict,
    );
    final titles = attention.map((reservation) => reservation.book).toList();
    final topTitle = titles.isEmpty ? 'No data' : titles.first;
    final count = attention.length;
    return [
      ('Overdue Records', '$count'),
      ('Most Overdue', topTitle),
      ('Sample Count', '$count'),
    ];
  }
}

class _DailyBreakdown extends StatelessWidget {
  const _DailyBreakdown({required this.reportType});

  final String reportType;

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    final isReservations = reportType == 'Reservations';
    final isUsers = reportType == 'Users';
    final rows = isReservations
        ? _reservationBreakdown(repository)
        : isUsers
        ? _userBreakdown(repository)
        : _defaultBreakdown(repository);

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          columns: [
            const DataColumn(label: Text('Date')),
            DataColumn(label: Text(isUsers ? 'Users' : 'Total')),
            DataColumn(label: Text(isUsers ? 'Active' : 'Confirmed')),
            DataColumn(label: Text(isUsers ? 'Inactive' : 'Pending')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  DataCell(Text(row.$1)),
                  DataCell(Text(row.$2)),
                  DataCell(Text(row.$3)),
                  DataCell(Text(row.$4)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<(String, String, String, String)> _reservationBreakdown(
    ManagerRepository repository,
  ) {
    final confirmed = repository.reservations
        .where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.confirmed,
        )
        .length;
    final pending = repository.reservations
        .where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.pending,
        )
        .length;
    final conflict = repository.reservations
        .where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.conflict,
        )
        .length;
    final total = repository.reservations.length;
    return [('Live data', '$total', '$confirmed', '${pending + conflict}')];
  }

  List<(String, String, String, String)> _userBreakdown(
    ManagerRepository repository,
  ) {
    final active = repository.users.where((user) => user.isActive).length;
    final inactive = repository.users.where((user) => !user.isActive).length;
    return [
      ('Live users', '${repository.users.length}', '$active', '$inactive'),
    ];
  }

  List<(String, String, String, String)> _defaultBreakdown(
    ManagerRepository repository,
  ) {
    final pending = repository.reservations
        .where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.pending,
        )
        .length;
    final confirmed = repository.reservations
        .where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.confirmed,
        )
        .length;
    return [
      (
        'Live data',
        '${repository.reservations.length}',
        '$confirmed',
        '$pending',
      ),
    ];
  }
}
