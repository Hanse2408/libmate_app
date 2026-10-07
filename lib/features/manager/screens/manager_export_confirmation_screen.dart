import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/report_export_service.dart';
import '../data/manager_mock_data.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerExportConfirmationScreen extends StatefulWidget {
  const ManagerExportConfirmationScreen({super.key, required this.selection});

  final ManagerReportSelection selection;

  @override
  State<ManagerExportConfirmationScreen> createState() =>
      _ManagerExportConfirmationScreenState();
}

class _ManagerExportConfirmationScreenState
    extends State<ManagerExportConfirmationScreen> {
  bool _isSaving = false;
  String? _savedPath;

  @override
  Widget build(BuildContext context) {
    final canExportCsv = widget.selection.format.toUpperCase() == 'CSV';

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
                canExportCsv
                    ? 'This report is ready to be exported as CSV.'
                    : 'CSV export is currently available for this report type.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _ExportInfoRow(label: 'Report', value: widget.selection.reportType),
                      const Divider(height: 20),
                      _ExportInfoRow(
                        label: 'Date Range',
                        value:
                            '${_dateLabel(widget.selection.startDate)} - ${_dateLabel(widget.selection.endDate)}',
                      ),
                      const Divider(height: 20),
                      _ExportInfoRow(label: 'Format', value: widget.selection.format),
                      const Divider(height: 20),
                      _ExportInfoRow(
                        label: 'Records',
                        value: '${_recordCount(widget.selection)} sample records',
                      ),
                      const Divider(height: 20),
                      _ExportInfoRow(
                        label: 'Generated',
                        value: _dateLabel(DateTime.now()),
                      ),
                      if (_savedPath != null) ...[
                        const Divider(height: 20),
                        _ExportInfoRow(
                          label: 'Saved File',
                          value: _savedPath!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: canExportCsv && !_isSaving ? _downloadReport : null,
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  _isSaving ? 'Saving...' : 'Download CSV',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _savedPath == null ? null : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report saved to $_savedPath')),
                  );
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Open saved file'),
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

  Future<void> _downloadReport() async {
    setState(() => _isSaving = true);
    try {
      final repository = ManagerScope.of(context).repository;
      final path = await ReportExportService.saveCsv(
        widget.selection,
        repository: repository,
      );
      if (path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _savedPath = path;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to $path')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report export failed.')),
      );
    }
  }

  int _recordCount(ManagerReportSelection selection) {
    final repository = ManagerScope.of(context).repository;
    return switch (selection.reportType) {
      'Users' => repository.users.length,
      'Reservations' || 'Conflicts' => repository.reservations.length,
      'Popular Books' => popularBooks.length,
      'Overdue Books' => overdueBooks.length,
      _ => 4,
    };
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
