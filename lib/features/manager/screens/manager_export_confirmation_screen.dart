import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerExportConfirmationScreen extends StatelessWidget {
  const ManagerExportConfirmationScreen({super.key, required this.selection});

  final ManagerReportSelection selection;

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Export Confirmation',
      body: ManagerPagePadding(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.lightBlue,
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 35,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Export Preview Ready',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'This is a UI demo. No ${selection.format} file has been created yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _ExportInfoRow(label: 'Report', value: selection.reportType),
                      const Divider(height: 20),
                      _ExportInfoRow(
                        label: 'Date Range',
                        value:
                            '${_dateLabel(selection.startDate)} - ${_dateLabel(selection.endDate)}',
                      ),
                      const Divider(height: 20),
                      _ExportInfoRow(label: 'Format', value: selection.format),
                      const Divider(height: 20),
                      _ExportInfoRow(
                        label: 'Records',
                        value: '${_recordCount(selection)} sample records',
                      ),
                      const Divider(height: 20),
                      _ExportInfoRow(
                        label: 'Generated',
                        value: _dateLabel(DateTime.now()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download (not available in demo)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share (not available in demo)'),
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'Back to Reports',
                onPressed: () => context.go(AppRoutes.managerReports),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _recordCount(ManagerReportSelection selection) =>
      switch (selection.reportType) {
        'Users' => ManagerUserStore.instance.users.length,
        'Reservations' || 'Conflicts' => managerReservations.length,
        'Popular Books' => popularBooks.length,
        'Overdue Books' => overdueBooks.length,
        _ => 4,
      };

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

class _ExportInfoRow extends StatelessWidget {
  const _ExportInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
