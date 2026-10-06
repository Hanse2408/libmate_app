import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 17, color: AppColors.navy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preview uses sample data. No report file is generated yet.',
                      style: TextStyle(fontSize: 11, color: AppColors.navy),
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
              'Sample data · $_recordsCount records',
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

  int get _recordsCount => switch (_selection.reportType) {
    'Users' => ManagerUserStore.instance.users.length,
    'Reservations' || 'Conflicts' => managerReservations.length,
    'Popular Books' => popularBooks.length,
    'Overdue Books' => overdueBooks.length,
    _ => 4,
  };

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
    final metrics = switch (selection.reportType) {
      'Users' => [
        ('Total Users', '${ManagerUserStore.instance.users.length}'),
        (
          'Active',
          '${ManagerUserStore.instance.users.where((user) => user.isActive).length}',
        ),
        (
          'Inactive',
          '${ManagerUserStore.instance.users.where((user) => !user.isActive).length}',
        ),
      ],
      'Popular Books' => [
        ('Books', '${popularBooks.length}'),
        ('Top Title', 'Clean Code'),
        ('Sample Count', '128'),
      ],
      'Overdue Books' => [
        ('Overdue Records', '${overdueBooks.length}'),
        ('Most Overdue', 'Clean Code'),
        ('Sample Count', '12'),
      ],
      'Occupancy' || 'Peak Usage' => [
        ('Total Seats', '120'),
        ('Occupied', '84'),
        ('Occupancy', '70%'),
      ],
      'Conflicts' => [
        (
          'Total Records',
          '${managerReservations.where((r) => r.status == ManagerReservationStatus.conflict).length}',
        ),
        ('Pending', '1'),
        ('Resolved', '1'),
      ],
      _ => [
        ('Total Reservations', '${managerReservations.length}'),
        (
          'Confirmed',
          '${managerReservations.where((r) => r.status == ManagerReservationStatus.confirmed).length}',
        ),
        (
          'Pending',
          '${managerReservations.where((r) => r.status == ManagerReservationStatus.pending).length}',
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
}

class _DailyBreakdown extends StatelessWidget {
  const _DailyBreakdown({required this.reportType});

  final String reportType;

  @override
  Widget build(BuildContext context) {
    final isReservations = reportType == 'Reservations';
    final isUsers = reportType == 'Users';
    final rows = isReservations
        ? const [('02 Oct', '2', '2', '0'), ('01 Oct', '2', '1', '1')]
        : isUsers
        ? const [('02 Oct', '3', '2', '1'), ('01 Oct', '2', '2', '0')]
        : const [('02 Oct', '2', '1', '1'), ('01 Oct', '2', '2', '0')];

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
}
